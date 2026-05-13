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
    try {
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
    } catch (e) {
      setState(() => _availableMethods = [_AuthMethod.password]);
    }
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

  // Login dengan password
  Future<void> _loginWithPassword() async {
    final password = _passwordController.text.trim();
    if (password.isEmpty) {
      setState(() => _errorMessage = 'Password tidak boleh kosong.');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    await Future.delayed(const Duration(seconds: 1));

    if (!mounted) return;

    if (password == 'password123') {
      Navigator.pushReplacementNamed(context, '/home');
    } else {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Password salah. Silakan coba lagi.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: _activeMethod == null
              ? _buildSelectionScreen()
              : _activeMethod == _AuthMethod.password
              ? _buildPasswordForm()
              : _buildBiometricScreen(),
        ),
      ),
    );
  }

  Widget _buildSelectionScreen() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Header
        const Icon(Icons.lock_outlined, size: 72, color: Colors.teal),
        const SizedBox(height: 16),
        const Text(
          'Selamat Datang',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Text(
          'Pilih metode login',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 14, color: Colors.grey[600]),
        ),
        const SizedBox(height: 40),

        ..._availableMethods.map((method) => _buildMethodCard(method)),
      ],
    );
  }

  Widget _buildMethodCard(_AuthMethod method) {
    final configs = {
      _AuthMethod.face: (
        icon: Icons.face_retouching_natural,
        label: 'Face ID',
        subtitle: 'Login menggunakan wajah',
        color: Colors.blue,
      ),
      _AuthMethod.fingerprint: (
        icon: Icons.fingerprint,
        label: 'Sidik Jari',
        subtitle: 'Login menggunakan sidik jari',
        color: Colors.teal,
      ),
      _AuthMethod.password: (
        icon: Icons.lock_outline,
        label: 'Password',
        subtitle: 'Login menggunakan password',
        color: Colors.orange,
      ),
    };

    final config = configs[method]!;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Card(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: ListTile(
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 20,
            vertical: 8,
          ),
          leading: CircleAvatar(
            backgroundColor: config.color.withOpacity(0.15),
            child: Icon(config.icon, color: config.color),
          ),
          title: Text(
            config.label,
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
          subtitle: Text(config.subtitle),
          trailing: const Icon(Icons.arrow_forward_ios, size: 16),
          onTap: () => _selectMethod(method),
        ),
      ),
    );
  }

  Widget _buildBiometricScreen() {
    final isFace = _activeMethod == _AuthMethod.face;

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ScaleTransition(
          scale: _isLoading ? _pulseAnim : const AlwaysStoppedAnimation(1.0),
          child: Icon(
            isFace ? Icons.face_retouching_natural : Icons.fingerprint,
            size: 100,
            color: Colors.teal,
          ),
        ),
        const SizedBox(height: 24),

        Text(
          _isLoading
              ? 'Menunggu verifikasi...'
              : isFace
              ? 'Arahkan wajah ke kamera'
              : 'Tempelkan jari ke sensor',
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
        ),
        const SizedBox(height: 32),

        // Error banner
        if (_errorMessage != null) ...[
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.red[50],
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.red[200]!),
            ),
            child: Text(
              _errorMessage!,
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.red[700]),
            ),
          ),
          const SizedBox(height: 16),
        ],

        // button action berdasarkan jenis error
        if (!_isLoading) ...[
          if (_errorCode != null && _errorMessage != null) ...[
            if (BiometricException(
              code: _errorCode!,
              message: '',
              userMessage: '',
            ).isRetryable)
              ElevatedButton.icon(
                onPressed: _startBiometric,
                icon: const Icon(Icons.refresh),
                label: const Text('Coba Lagi'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.teal,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            const SizedBox(height: 8),
          ],
          OutlinedButton(
            onPressed: () => setState(() {
              _activeMethod = null;
              _errorMessage = null;
              _errorCode = null;
            }),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text('Kembali'),
          ),
        ],
      ],
    );
  }

  Widget _buildPasswordForm() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Icon(Icons.lock_outlined, size: 72, color: Colors.orange),
        const SizedBox(height: 16),
        const Text(
          'Login dengan Password',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 32),

        // Field password
        TextField(
          controller: _passwordController,
          obscureText: _obscurePassword,
          decoration: InputDecoration(
            labelText: 'Password',
            prefixIcon: const Icon(Icons.lock_outlined),
            suffixIcon: IconButton(
              icon: Icon(
                _obscurePassword ? Icons.visibility : Icons.visibility_off,
              ),
              onPressed: () =>
                  setState(() => _obscurePassword = !_obscurePassword),
            ),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
          onSubmitted: (_) => _loginWithPassword(),
        ),
        const SizedBox(height: 12),

        // Error message
        if (_errorMessage != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Text(
              _errorMessage!,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.red),
            ),
          ),

        // Tombol Login
        ElevatedButton(
          onPressed: _isLoading ? null : _loginWithPassword,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.orange,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 14),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          child: _isLoading
              ? const SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : const Text(
                  'Login',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
        ),
        const SizedBox(height: 12),

        OutlinedButton(
          onPressed: () => setState(() {
            _activeMethod = null;
            _errorMessage = null;
            _passwordController.clear();
          }),
          style: OutlinedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 14),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          child: const Text('Kembali'),
        ),
      ],
    );
  }
}
