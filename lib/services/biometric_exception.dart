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

  // Konversi LocalAuthException (error OS) → BiometricException (error app)
  factory BiometricException.fromLocalAuthException(LocalAuthException e) {
    switch (e.code) {
      case LocalAuthExceptionCode.noBiometricHardware:
        return const BiometricException(
          code: BiometricErrorCode.noBiometricHardware,
          message: 'No biometric hardware found',
          userMessage: 'Perangkat tidak memiliki sensor biometrik.',
        );
      case LocalAuthExceptionCode.noBiometricsEnrolled:
        return const BiometricException(
          code: BiometricErrorCode.notEnrolled,
          message: 'No biometrics enrolled',
          userMessage:
              'Belum ada sidik jari tersimpan. Daftarkan di Pengaturan.',
        );
      case LocalAuthExceptionCode.temporaryLockout:
        return const BiometricException(
          code: BiometricErrorCode.temporaryLockout,
          message: 'Biometric temporarily locked out',
          userMessage: 'Terlalu banyak percobaan gagal. Coba lagi sebentar.',
        );
      case LocalAuthExceptionCode.biometricLockout:
        return const BiometricException(
          code: BiometricErrorCode.biometricLockout,
          message: 'Biometric permanently locked out',
          userMessage:
              'Biometrik terkunci. Buka kunci perangkat dengan PIN terlebih dahulu.',
        );
      case LocalAuthExceptionCode.userCanceled:
        return const BiometricException(
          code: BiometricErrorCode.userCanceled,
          message: 'User canceled authentication',
          userMessage: 'Autentikasi dibatalkan oleh pengguna.',
        );
      case LocalAuthExceptionCode.systemCanceled:
        return const BiometricException(
          code: BiometricErrorCode.systemCanceled,
          message: 'System canceled authentication',
          userMessage: 'Autentikasi dibatalkan oleh sistem.',
        );
      default:
        return BiometricException(
          code: BiometricErrorCode.unknown,
          message: e.toString(),
          userMessage: 'Terjadi kesalahan. Silakan coba lagi.',
        );
    }
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
