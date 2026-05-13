import 'package:local_auth/local_auth.dart';
import 'package:local_auth_android/local_auth_android.dart';
import 'biometric_exception.dart';

class BiometricService {
  final LocalAuthentication _auth = LocalAuthentication();

  //Cek apakah biometrik tersedia di perangkat
  Future<bool> isBiometricAvailable() async {
    final bool canCheck = await _auth.canCheckBiometrics; // Ada sensor?
    final bool isSupported = await _auth
        .isDeviceSupported(); // Device mendukung?
    return canCheck && isSupported;
  }

  Future<List<BiometricType>> getAvailableBiometrics() async {
    return await _auth.getAvailableBiometrics();
    // Mengembalikan list: [BiometricType.fingerprint, BiometricType.face, ...]
    // BiometricType.weak  = face Android (2D)
    // BiometricType.strong = fingerprint / iris
  }
}
