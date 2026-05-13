import 'package:flutter/material.dart';
import '../services/biometric_service.dart';
import '../services/biometric_exception.dart';
import 'package:local_auth/local_auth.dart';

enum _AuthMethod { face, fingerprint, password }

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage>
    with SingleTickerProviderStateMixin {
  final BiometricService _service = BiometricService();

  _AuthMethod? _activeMethod;
  bool _isLoading = false;
  String? _errorMessage;
  BiometricErrorCode? _errorCode;
  List<_AuthMethod> _availableMethods = [];

  // Controller password
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;

  // Animasi pulse
  late final AnimationController _pulseController = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
  )..repeat(reverse: true);

  late final Animation<double> _pulseAnim = Tween(
    begin: 1.0,
    end: 1.12,
  ).animate(CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut));

  @override
  void initState() {
    super.initState();
    _init();
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  // Deteksi hardware saat pertama buka
  Future<void> _init() async {
    final available = await _service.isBiometricAvailable();
    if (!available) {
      setState(() => _availableMethods = [_AuthMethod.password]);
      return;
    }

    final types = await _service.getAvailableBiometrics();

    // Android face  → BiometricType.weak
    // iOS Face ID   → BiometricType.face
    // Fingerprint   → BiometricType.fingerprint atau BiometricType.strong
    final hasFace =
        types.contains(BiometricType.face) ||
        types.contains(BiometricType.weak);
    final hasFingerprint =
        types.contains(BiometricType.fingerprint) ||
        types.contains(BiometricType.strong);

    setState(() {
      _availableMethods = [
        if (hasFace) _AuthMethod.face,
        if (hasFingerprint) _AuthMethod.fingerprint,
        _AuthMethod.password,
      ];
    });
  }

  // Pilih metode & mulai autentikasi
  Future<void> _selectMethod(_AuthMethod method) async {
    setState(() {
      _activeMethod = method;
      _errorMessage = null;
      _errorCode = null;
    });

    if (method == _AuthMethod.password) return;

    await _startBiometric();
  }

  Future<void> _startBiometric() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _errorCode = null;
    });

    try {
      await _service.authenticate(
        reason: 'Verifikasi identitas Anda untuk masuk ke aplikasi',
      );
      if (!mounted) return;
      Navigator.pushReplacementNamed(context, '/home');
    } on BiometricException catch (e) {
      _handleError(e);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // Handle error dari BiometricException
  void _handleError(BiometricException e) {
    setState(() {
      _errorMessage = e.userMessage;
      _errorCode = e.code;
      if (e.requiresFallback) _activeMethod = _AuthMethod.password;
    });
  }
}
