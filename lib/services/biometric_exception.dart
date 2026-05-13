import 'package:local_auth/error_codes.dart' as auth_error;
import 'package:local_auth_android/local_auth_android.dart';
import 'package:local_auth/local_auth.dart';

enum BiometricErrorCode {
  noBiometricHardware, // Tidak ada sensor biometrik di perangkat
  notEnrolled, // Sensor ada, tapi belum ada sidik jari/wajah terdaftar
  temporaryLockout, // Terkunci sementara (terlalu banyak percobaan gagal)
  biometricLockout, // Terkunci permanen (butuh buka kunci dengan PIN dulu)
  userCanceled, // User menekan tombol Batal
  systemCanceled, // Sistem membatalkan
  unknown,
}

class BiometricException implements Exception {
  final BiometricErrorCode code;
  final String message;
  final String userMessage;

  const BiometricException({
    required this.code,
    required this.message,
    required this.userMessage,
  });

  // Konversi dari LocalAuthException ke BiometricException
  factory BiometricException.fromLocalAuthException(Object e) {
    // local_auth v3 melempar string error code
    final errorCode = e.toString();

    if (errorCode.contains(auth_error.notAvailable) ||
        errorCode.contains(auth_error.notEnrolled)) {
      if (errorCode.contains(auth_error.notEnrolled)) {
        return const BiometricException(
          code: BiometricErrorCode.notEnrolled,
          message: 'No biometrics enrolled',
          userMessage:
              'Belum ada sidik jari tersimpan. Daftarkan di Pengaturan.',
        );
      }
      return const BiometricException(
        code: BiometricErrorCode.noBiometricHardware,
        message: 'Biometric not available',
        userMessage: 'Perangkat tidak memiliki sensor biometrik.',
      );
    } else if (errorCode.contains(auth_error.lockedOut)) {
      return const BiometricException(
        code: BiometricErrorCode.temporaryLockout,
        message: 'Biometric temporarily locked out',
        userMessage: 'Terlalu banyak percobaan gagal. Coba lagi sebentar.',
      );
    } else if (errorCode.contains(auth_error.permanentlyLockedOut)) {
      return const BiometricException(
        code: BiometricErrorCode.biometricLockout,
        message: 'Biometric permanently locked out',
        userMessage:
            'Biometrik terkunci. Buka kunci perangkat dengan PIN terlebih dahulu.',
      );
    }

    return BiometricException(
      code: BiometricErrorCode.unknown,
      message: e.toString(),
      userMessage: 'Terjadi kesalahan. Silakan coba lagi.',
    );
  }

  // ─── keputusan UI ───

  // Tampilkan tombol "Coba Lagi"?
  bool get isRetryable =>
      code == BiometricErrorCode.userCanceled ||
      code == BiometricErrorCode.systemCanceled ||
      code == BiometricErrorCode.unknown;

  // Tampilkan tombol "Buka Pengaturan"?
  bool get requiresSettings => code == BiometricErrorCode.notEnrolled;

  // Otomatis pindah ke form password?
  bool get requiresFallback =>
      code == BiometricErrorCode.noBiometricHardware ||
      code == BiometricErrorCode.biometricLockout;

  @override
  String toString() => 'BiometricException($code): $message';
}
