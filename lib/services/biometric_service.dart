import 'package:local_auth/local_auth.dart';
import 'package:local_auth_android/local_auth_android.dart';
import 'biometric_exception.dart';

class BiometricService {
  final LocalAuthentication _auth = LocalAuthentication();

  //Cek apakah biometrik tersedia di perangkat
  Future<bool> isBiometricAvailable() async {
    final bool canCheck = await _auth.canCheckBiometrics;
    final bool isSupported = await _auth.isDeviceSupported();
    return canCheck && isSupported;
  }

  Future<List<BiometricType>> getAvailableBiometrics() async {
    return await _auth.getAvailableBiometrics();
    // Mengembalikan list: [BiometricType.fingerprint, BiometricType.face, ...]
    // BiometricType.weak  = face Android (2D)
    // BiometricType.strong = fingerprint / iris
  }

  // fungsi autentikasi biometrik
  Future<bool> authenticate({
    String reason = 'Verifikasi identitas Anda untuk melanjutkan',
  }) async {
    // apakah hardware tersedia?
    final bool available = await isBiometricAvailable();
    if (!available) {
      throw const BiometricException(
        code: BiometricErrorCode.noBiometricHardware,
        message: 'Biometric hardware not available',
        userMessage: 'Perangkat tidak memiliki sensor biometrik.',
      );
    }

    // apakah sudah ada biometrik terdaftar?
    final List<BiometricType> types = await getAvailableBiometrics();
    if (types.isEmpty) {
      throw const BiometricException(
        code: BiometricErrorCode.notEnrolled,
        message: 'No biometrics enrolled',
        userMessage: 'Belum ada sidik jari tersimpan. Daftarkan di Pengaturan.',
      );
    }

    try {
      // tampilkan dialog biometrik OS
      final bool result = await _auth.authenticate(
        localizedReason: reason,
        authMessages: [
          AndroidAuthMessages(
            signInTitle: 'Verifikasi Diperlukan',
            cancelButton: 'Batal',
            signInHint: 'Tempelkan jari atau arahkan wajah',
          ),
        ],
        biometricOnly: false, // false = izinkan fallback PIN/pattern OS
        sensitiveTransaction: false, // true = tidak izinkan face 2D (Class 2)
        persistAcrossBackgrounding:
            true, // dialog tetap muncul setelah app di-background
      );

      // result=false tanpa exception = user tekan Batal
      if (!result) {
        throw const BiometricException(
          code: BiometricErrorCode.userCanceled,
          message: 'User canceled authentication',
          userMessage: 'Autentikasi dibatalkan oleh pengguna.',
        );
      }

      return true;
    } on BiometricException {
      rethrow; //lempar ulang BiometricException yang udah dibuat
    } on LocalAuthException catch (e) {
      //konversi LocalAuthException → BiometricException
      throw BiometricException.fromLocalAuthException(e);
    }
  }
}
