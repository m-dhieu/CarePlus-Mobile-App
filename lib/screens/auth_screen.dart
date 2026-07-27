import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../features/auth/auth_providers.dart';
import '../features/auth/validators.dart';
import '../providers/providers.dart';
import '../widgets/shared_widgets.dart';

const _errorRed = Color(0xFFEF4444);

class AuthScreen extends ConsumerStatefulWidget {
  const AuthScreen({super.key});

  @override
  ConsumerState<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends ConsumerState<AuthScreen> {
  bool _isLogin = true;
  bool _showPw = false;
  bool _showConfirmPw = false;
  bool _submitting = false;
  String? _errorText;

  final _fullNameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();

  @override
  void dispose() {
    _fullNameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text;

    final emailError = validateEmail(email);
    final passwordError = validatePassword(password);
    if (emailError != null) {
      setState(() => _errorText = emailError);
      return;
    }
    if (passwordError != null) {
      setState(() => _errorText = passwordError);
      return;
    }

    if (!_isLogin) {
      final nameError = validateFullName(_fullNameController.text);
      if (nameError != null) {
        setState(() => _errorText = nameError);
        return;
      }
      if (password != _confirmController.text) {
        setState(() => _errorText = 'Passwords do not match.');
        return;
      }
    }

    setState(() {
      _submitting = true;
      _errorText = null;
    });
    final repo = ref.read(authRepositoryProvider);
    try {
      if (_isLogin) {
        await repo.loginWithEmailPassword(email: email, password: password);
      } else {
        await repo.registerWithEmailPassword(
          email: email,
          password: password,
          fullName: _fullNameController.text.trim(),
          phone: _phoneController.text.trim(),
        );
      }
    } on FirebaseAuthException catch (e) {
      setState(() => _errorText = repo.mapAuthError(e));
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  Future<void> _forgotPassword() async {
    final email = _emailController.text.trim();
    final emailError = validateEmail(email);
    if (emailError != null) {
      setState(() => _errorText = 'Enter your email above first.');
      return;
    }
    setState(() {
      _submitting = true;
      _errorText = null;
    });
    final repo = ref.read(authRepositoryProvider);
    try {
      await repo.resetPasswordEmail(email);
      ref.read(toastProvider.notifier).show('Password reset email sent');
    } on FirebaseAuthException catch (e) {
      setState(() => _errorText = repo.mapAuthError(e));
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  Future<void> _googleSignIn() async {
    setState(() {
      _submitting = true;
      _errorText = null;
    });
    final repo = ref.read(authRepositoryProvider);
    try {
      await repo.signInWithGoogle();
    } on FirebaseAuthException catch (e) {
      setState(() => _errorText = repo.mapAuthError(e));
    } catch (e) {
      setState(() => _errorText = 'Google sign-in is not available here.');
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: teal50,
      padding: const EdgeInsets.fromLTRB(24, 56, 24, 32),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text('Care', style: TextStyle(fontSize: 30, fontWeight: FontWeight.w900, color: teal700)),
              const SizedBox(width: 2),
              const Icon(Icons.add, size: 26, color: teal500),
            ],
          ),
          const SizedBox(height: 32),
          Container(
            decoration: BoxDecoration(color: Colors.white60, borderRadius: BorderRadius.circular(50)),
            padding: const EdgeInsets.all(4),
            child: Row(
              children: [
                _tabBtn('Login', _isLogin, () => setState(() { _isLogin = true; _errorText = null; })),
                _tabBtn('Sign up', !_isLogin, () => setState(() { _isLogin = false; _errorText = null; })),
              ],
            ),
          ),
          const SizedBox(height: 24),
          Expanded(
            child: Container(
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24)),
              padding: const EdgeInsets.all(24),
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      _isLogin ? "You're welcome again" : 'Create your account',
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: teal700, fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 24),

                    // ── Sign-up fields ──────────────────────────────────────
                    if (!_isLogin) ...[
                      _Field(label: 'Full name', placeholder: 'Enter your full name', icon: Icons.person, controller: _fullNameController),
                      const SizedBox(height: 16),
                      _Field(label: 'Phone number', placeholder: '+250 788 000 000', icon: Icons.phone, keyboardType: TextInputType.phone, controller: _phoneController),
                      const SizedBox(height: 16),
                    ],

                    // ── Shared fields ───────────────────────────────────────
                    _Field(label: 'Email', placeholder: 'Enter your email', icon: Icons.mail, keyboardType: TextInputType.emailAddress, controller: _emailController),
                    const SizedBox(height: 16),
                    _Field(
                      label: 'Password',
                      placeholder: 'Enter your password',
                      icon: Icons.lock,
                      obscure: !_showPw,
                      suffixIcon: _showPw ? Icons.visibility_off : Icons.visibility,
                      onSuffixTap: () => setState(() => _showPw = !_showPw),
                      controller: _passwordController,
                    ),

                    if (!_isLogin) ...[
                      const SizedBox(height: 16),
                      _Field(
                        label: 'Confirm password',
                        placeholder: 'Re-enter your password',
                        icon: Icons.lock,
                        obscure: !_showConfirmPw,
                        suffixIcon: _showConfirmPw ? Icons.visibility_off : Icons.visibility,
                        onSuffixTap: () => setState(() => _showConfirmPw = !_showConfirmPw),
                        controller: _confirmController,
                      ),
                    ],

                    if (_isLogin) ...[
                      const SizedBox(height: 8),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: GestureDetector(
                          onTap: _submitting ? null : _forgotPassword,
                          child: Text('Forgot password?', style: TextStyle(fontSize: 12, color: slate500)),
                        ),
                      ),
                    ],

                    if (_errorText != null) ...[
                      const SizedBox(height: 12),
                      Text(_errorText!, style: const TextStyle(color: _errorRed, fontSize: 12)),
                    ],

                    const SizedBox(height: 28),

                    // ── Primary action button ───────────────────────────────
                    ElevatedButton(
                      onPressed: _submitting ? null : _submit,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: teal600,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: const StadiumBorder(),
                        elevation: 2,
                      ),
                      child: _submitting
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                            )
                          : Text(
                              _isLogin ? 'Login' : 'Sign up',
                              style: const TextStyle(fontWeight: FontWeight.w800),
                            ),
                    ),

                    // ── Divider + Google ────────────────────────────────────
                    const SizedBox(height: 20),
                    Row(
                      children: [
                        const Expanded(child: Divider(color: slate200)),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          child: Text(_isLogin ? 'or continue with' : 'or sign up with', style: TextStyle(fontSize: 11, color: slate400)),
                        ),
                        const Expanded(child: Divider(color: slate200)),
                      ],
                    ),
                    const SizedBox(height: 16),
                    GestureDetector(
                      onTap: _submitting ? null : _googleSignIn,
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          border: Border.all(color: slate200),
                          borderRadius: BorderRadius.circular(50),
                        ),
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            _GoogleLogo(),
                            SizedBox(width: 10),
                            Text(
                              'Continue with Google',
                              style: TextStyle(
                                color: slate700,
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _tabBtn(String label, bool active, VoidCallback onTap) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: active ? teal600 : Colors.transparent,
            borderRadius: BorderRadius.circular(50),
            boxShadow: active ? [const BoxShadow(color: Colors.black12, blurRadius: 4)] : [],
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: active ? Colors.white : teal700,
            ),
          ),
        ),
      ),
    );
  }
}

// Google "G" mark drawn with simple colored quadrants — no asset needed
class _GoogleLogo extends StatelessWidget {
  const _GoogleLogo();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 18,
      height: 18,
      child: CustomPaint(painter: _GoogleLogoPainter()),
    );
  }
}

class _GoogleLogoPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;
    final rect = Rect.fromCircle(center: center, radius: radius);
    const start = -0.4;

    void arc(double startTurn, double sweepTurn, Color color) {
      final paint = Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = size.width * 0.28;
      canvas.drawArc(rect.deflate(paint.strokeWidth / 2), startTurn * 6.28319, sweepTurn * 6.28319, false, paint);
    }

    arc(start, 0.24, const Color(0xFF4285F4));
    arc(start + 0.24, 0.26, const Color(0xFF34A853));
    arc(start + 0.5, 0.24, const Color(0xFFFBBC05));
    arc(start + 0.74, 0.26, const Color(0xFFEA4335));
  }

  @override
  bool shouldRepaint(_) => false;
}

class _Field extends StatelessWidget {
  final String label;
  final String placeholder;
  final IconData icon;
  final bool obscure;
  final IconData? suffixIcon;
  final VoidCallback? onSuffixTap;
  final TextInputType keyboardType;
  final TextEditingController? controller;

  const _Field({
    required this.label,
    required this.placeholder,
    required this.icon,
    this.obscure = false,
    this.suffixIcon,
    this.onSuffixTap,
    this.keyboardType = TextInputType.text,
    this.controller,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: teal700)),
        const SizedBox(height: 4),
        Container(
          decoration: BoxDecoration(
            border: Border.all(color: slate200),
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          child: Row(
            children: [
              Icon(icon, size: 16, color: slate400),
              const SizedBox(width: 8),
              Expanded(
                child: TextField(
                  controller: controller,
                  obscureText: obscure,
                  keyboardType: keyboardType,
                  decoration: InputDecoration(
                    hintText: placeholder,
                    hintStyle: const TextStyle(color: slate300, fontSize: 13),
                    border: InputBorder.none,
                    isDense: true,
                  ),
                  style: const TextStyle(fontSize: 13),
                ),
              ),
              if (suffixIcon != null)
                GestureDetector(
                  onTap: onSuffixTap,
                  child: Icon(suffixIcon, size: 16, color: slate400),
                ),
            ],
          ),
        ),
      ],
    );
  }
}
