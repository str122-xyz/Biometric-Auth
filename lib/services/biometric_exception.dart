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
}
