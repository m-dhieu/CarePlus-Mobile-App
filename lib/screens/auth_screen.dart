import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/providers.dart';
import '../services/auth_errors.dart';
import '../widgets/shared_widgets.dart';

class AuthScreen extends ConsumerStatefulWidget {
  const AuthScreen({super.key});

  @override
  ConsumerState<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends ConsumerState<AuthScreen> {
  bool _isLogin = true;
  bool _showPw = false;
  bool _showConfirmPw = false;
  bool _busy = false;
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    _confirmCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final email = _emailCtrl.text.trim();
    final password = _passwordCtrl.text;
    if (email.isEmpty || password.isEmpty) {
      ref.read(toastProvider.notifier).show('Email and password are required');
      return;
    }
    if (!_isLogin && password != _confirmCtrl.text) {
      ref.read(toastProvider.notifier).show('Passwords do not match');
      return;
    }

    setState(() => _busy = true);
    try {
      if (_isLogin) {
        await ref.read(authProvider.notifier).login(email, password);
      } else {
        await ref.read(authProvider.notifier).signUp(email, password);
        ref
            .read(toastProvider.notifier)
            .show('Account created — you are signed in');
      }
    } catch (e) {
      ref.read(toastProvider.notifier).show(AuthErrorMapper.message(e));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _social(Future<void> Function() action) async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      await action();
    } catch (e) {
      if (e is AuthCancelledException) return;
      ref.read(toastProvider.notifier).show(AuthErrorMapper.message(e));
    } finally {
      if (mounted) setState(() => _busy = false);
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
              const Text(
                'Care',
                style: TextStyle(
                  fontSize: 30,
                  fontWeight: FontWeight.w900,
                  color: teal700,
                ),
              ),
              const SizedBox(width: 2),
              const Icon(Icons.add, size: 26, color: teal500),
            ],
          ),
          const SizedBox(height: 32),
          Container(
            decoration: BoxDecoration(
              color: Colors.white60,
              borderRadius: BorderRadius.circular(50),
            ),
            padding: const EdgeInsets.all(4),
            child: Row(
              children: [
                _tabBtn(
                  'Login',
                  _isLogin,
                  () => setState(() => _isLogin = true),
                ),
                _tabBtn(
                  'Sign up',
                  !_isLogin,
                  () => setState(() => _isLogin = false),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
              ),
              padding: const EdgeInsets.all(24),
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      _isLogin ? "You're welcome again" : 'Create your account',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: teal700,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 24),

                    if (!_isLogin) ...[
                      const _Field(
                        label: 'Full name',
                        placeholder: 'Enter your full name',
                        icon: Icons.person,
                      ),
                      const SizedBox(height: 16),
                      const _Field(
                        label: 'Phone number',
                        placeholder: '+250 788 000 000',
                        icon: Icons.phone,
                        keyboardType: TextInputType.phone,
                      ),
                      const SizedBox(height: 16),
                    ],

                    _Field(
                      label: 'Email',
                      placeholder: 'Enter your email',
                      icon: Icons.mail,
                      keyboardType: TextInputType.emailAddress,
                      controller: _emailCtrl,
                    ),
                    const SizedBox(height: 16),
                    _Field(
                      label: 'Password',
                      placeholder: 'Enter your password',
                      icon: Icons.lock,
                      obscure: !_showPw,
                      suffixIcon: _showPw
                          ? Icons.visibility_off
                          : Icons.visibility,
                      onSuffixTap: () => setState(() => _showPw = !_showPw),
                      controller: _passwordCtrl,
                    ),

                    if (!_isLogin) ...[
                      const SizedBox(height: 16),
                      _Field(
                        label: 'Confirm password',
                        placeholder: 'Re-enter your password',
                        icon: Icons.lock,
                        obscure: !_showConfirmPw,
                        suffixIcon: _showConfirmPw
                            ? Icons.visibility_off
                            : Icons.visibility,
                        onSuffixTap: () =>
                            setState(() => _showConfirmPw = !_showConfirmPw),
                        controller: _confirmCtrl,
                      ),
                    ],

                    const SizedBox(height: 28),

                    ElevatedButton(
                      onPressed: _busy ? null : _submit,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: teal600,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: const StadiumBorder(),
                        elevation: 2,
                      ),
                      child: Text(
                        _busy
                            ? 'Please wait…'
                            : (_isLogin ? 'Login' : 'Sign up'),
                        style: const TextStyle(fontWeight: FontWeight.w800),
                      ),
                    ),

                    const SizedBox(height: 20),
                    Row(
                      children: [
                        const Expanded(child: Divider(color: slate200)),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          child: Text(
                            _isLogin ? 'or continue with' : 'or sign up with',
                            style: const TextStyle(
                              fontSize: 11,
                              color: slate400,
                            ),
                          ),
                        ),
                        const Expanded(child: Divider(color: slate200)),
                      ],
                    ),
                    const SizedBox(height: 16),

                    _SocialButton(
                      enabled: !_busy,
                      background: Colors.white,
                      borderColor: slate200,
                      onTap: () => _social(
                        () =>
                            ref.read(authProvider.notifier).signInWithGoogle(),
                      ),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          _GoogleLogo(),
                          SizedBox(width: 10),
                          Text(
                            'Continue with Google',
                            style: TextStyle(
                              color: slate900,
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    _SocialButton(
                      enabled: !_busy,
                      background: const Color(0xFF000000),
                      onTap: () => _social(
                        () => ref.read(authProvider.notifier).signInWithApple(),
                      ),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          _AppleLogo(),
                          SizedBox(width: 10),
                          Text(
                            'Sign up with Apple',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 16),
                    const Text(
                      'Signed-in data syncs to Firestore and stays available offline.',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 11, color: slate400),
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
            boxShadow: active
                ? [const BoxShadow(color: Colors.black12, blurRadius: 4)]
                : [],
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

class _SocialButton extends StatelessWidget {
  final bool enabled;
  final Color background;
  final Color? borderColor;
  final VoidCallback onTap;
  final Widget child;

  const _SocialButton({
    required this.enabled,
    required this.background,
    this.borderColor,
    required this.onTap,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: enabled ? 1 : 0.6,
      child: GestureDetector(
        onTap: enabled ? onTap : null,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            color: background,
            borderRadius: BorderRadius.circular(50),
            border: borderColor == null
                ? null
                : Border.all(color: borderColor!),
          ),
          child: child,
        ),
      ),
    );
  }
}

class _GoogleLogo extends StatelessWidget {
  const _GoogleLogo();

  @override
  Widget build(BuildContext context) {
    return const SizedBox(
      width: 18,
      height: 18,
      child: CustomPaint(painter: _GoogleLogoPainter()),
    );
  }
}

class _GoogleLogoPainter extends CustomPainter {
  const _GoogleLogoPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final stroke = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = size.width * 0.18
      ..strokeCap = StrokeCap.butt;

    final rect = Rect.fromLTWH(
      size.width * 0.12,
      size.height * 0.12,
      size.width * 0.76,
      size.height * 0.76,
    );

    stroke.color = const Color(0xFF4285F4);
    canvas.drawArc(rect, -0.4, 1.6, false, stroke);
    stroke.color = const Color(0xFF34A853);
    canvas.drawArc(rect, 1.2, 1.1, false, stroke);
    stroke.color = const Color(0xFFFBBC05);
    canvas.drawArc(rect, 2.3, 0.8, false, stroke);
    stroke.color = const Color(0xFFEA4335);
    canvas.drawArc(rect, 3.1, 1.0, false, stroke);

    final bar = Paint()..color = const Color(0xFF4285F4);
    canvas.drawRect(
      Rect.fromLTWH(
        size.width * 0.48,
        size.height * 0.42,
        size.width * 0.40,
        size.height * 0.16,
      ),
      bar,
    );
  }

  @override
  bool shouldRepaint(_) => false;
}

class _AppleLogo extends StatelessWidget {
  const _AppleLogo();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 18,
      height: 18,
      child: CustomPaint(painter: _AppleLogoPainter()),
    );
  }
}

class _AppleLogoPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;
    final w = size.width;
    final h = size.height;

    final path = Path();
    path.moveTo(w * 0.72, h * 0.0);
    path.cubicTo(w * 0.72, h * 0.0, w * 0.44, h * 0.02, w * 0.44, h * 0.28);
    path.cubicTo(w * 0.44, h * 0.38, w * 0.50, h * 0.44, w * 0.56, h * 0.44);
    path.cubicTo(w * 0.62, h * 0.44, w * 0.68, h * 0.40, w * 0.72, h * 0.36);
    path.cubicTo(w * 0.76, h * 0.40, w * 0.82, h * 0.44, w * 0.88, h * 0.44);
    path.cubicTo(w * 0.94, h * 0.44, w * 1.0, h * 0.38, w * 1.0, h * 0.28);
    path.cubicTo(w * 1.0, h * 0.02, w * 0.72, h * 0.0, w * 0.72, h * 0.0);
    path.close();

    final body = Path();
    body.moveTo(w * 0.18, h * 0.46);
    body.cubicTo(w * 0.06, h * 0.46, w * 0.0, h * 0.56, w * 0.0, h * 0.68);
    body.cubicTo(w * 0.0, h * 0.86, w * 0.12, h * 1.0, w * 0.28, h * 1.0);
    body.cubicTo(w * 0.36, h * 1.0, w * 0.42, h * 0.96, w * 0.50, h * 0.96);
    body.cubicTo(w * 0.58, h * 0.96, w * 0.64, h * 1.0, w * 0.72, h * 1.0);
    body.cubicTo(w * 0.88, h * 1.0, w * 1.0, h * 0.86, w * 1.0, h * 0.68);
    body.cubicTo(w * 1.0, h * 0.56, w * 0.94, h * 0.46, w * 0.82, h * 0.46);
    body.cubicTo(w * 0.74, h * 0.46, w * 0.66, h * 0.52, w * 0.50, h * 0.52);
    body.cubicTo(w * 0.34, h * 0.52, w * 0.26, h * 0.46, w * 0.18, h * 0.46);
    body.close();

    canvas.drawPath(path, paint);
    canvas.drawPath(body, paint);
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
        Text(
          label,
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: teal700,
          ),
        ),
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
