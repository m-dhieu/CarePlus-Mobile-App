import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/providers.dart';
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
                _tabBtn('Login', _isLogin, () => setState(() => _isLogin = true)),
                _tabBtn('Sign up', !_isLogin, () => setState(() => _isLogin = false)),
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
                      _Field(label: 'Full name', placeholder: 'Enter your full name', icon: Icons.person),
                      const SizedBox(height: 16),
                      _Field(label: 'Phone number', placeholder: '+250 788 000 000', icon: Icons.phone, keyboardType: TextInputType.phone),
                      const SizedBox(height: 16),
                    ],

                    // ── Shared fields ───────────────────────────────────────
                    _Field(label: 'Email', placeholder: 'Enter your email', icon: Icons.mail, keyboardType: TextInputType.emailAddress),
                    const SizedBox(height: 16),
                    _Field(
                      label: 'Password',
                      placeholder: 'Enter your password',
                      icon: Icons.lock,
                      obscure: !_showPw,
                      suffixIcon: _showPw ? Icons.visibility_off : Icons.visibility,
                      onSuffixTap: () => setState(() => _showPw = !_showPw),
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
                      ),
                    ],

                    if (_isLogin) ...[
                      const SizedBox(height: 8),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Text('Forgot password?', style: TextStyle(fontSize: 12, color: slate500)),
                      ),
                    ],

                    const SizedBox(height: 28),

                    // ── Primary action button ───────────────────────────────
                    ElevatedButton(
                      onPressed: () {
                        if (_isLogin) {
                          ref.read(authProvider.notifier).login();
                        } else {
                          // After sign-up, redirect to sign-in
                          setState(() => _isLogin = true);
                          ref.read(toastProvider.notifier).show('Account created — please sign in');
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: teal600,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: const StadiumBorder(),
                        elevation: 2,
                      ),
                      child: Text(
                        _isLogin ? 'Login' : 'Sign up',
                        style: const TextStyle(fontWeight: FontWeight.w800),
                      ),
                    ),

                    // ── Divider ─────────────────────────────────────────────
                    if (_isLogin) ...[
                      const SizedBox(height: 20),
                      Row(
                        children: [
                          const Expanded(child: Divider(color: slate200)),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            child: Text('or continue with', style: TextStyle(fontSize: 11, color: slate400)),
                          ),
                          const Expanded(child: Divider(color: slate200)),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // ── Apple Sign-In button ────────────────────────────
                      GestureDetector(
                        onTap: () => ref.read(toastProvider.notifier).show('Apple Sign-In needs a backend connection'),
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          decoration: BoxDecoration(
                            color: const Color(0xFF000000),
                            borderRadius: BorderRadius.circular(50),
                          ),
                          child: const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              _AppleLogo(),
                              SizedBox(width: 10),
                              Text(
                                'Sign in with Apple',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],

                    // ── Apple Sign-Up (sign-up tab only) ───────────────────
                    if (!_isLogin) ...[
                      const SizedBox(height: 20),
                      Row(
                        children: [
                          const Expanded(child: Divider(color: slate200)),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            child: Text('or sign up with', style: TextStyle(fontSize: 11, color: slate400)),
                          ),
                          const Expanded(child: Divider(color: slate200)),
                        ],
                      ),
                      const SizedBox(height: 16),
                      GestureDetector(
                        onTap: () => ref.read(toastProvider.notifier).show('Apple Sign-Up needs a backend connection'),
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          decoration: BoxDecoration(
                            color: const Color(0xFF000000),
                            borderRadius: BorderRadius.circular(50),
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
                      ),
                    ],

                    const SizedBox(height: 16),
                    const Text(
                      'Frontend preview — connect a backend to enable real accounts.',
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

// Apple logo drawn with CustomPainter — no asset needed
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
    final paint = Paint()..color = Colors.white..style = PaintingStyle.fill;
    final w = size.width;
    final h = size.height;

    // Apple body path (simplified Apple logo shape)
    final path = Path();
    // Right lobe
    path.moveTo(w * 0.72, h * 0.0);
    path.cubicTo(w * 0.72, h * 0.0, w * 0.44, h * 0.02, w * 0.44, h * 0.28);
    path.cubicTo(w * 0.44, h * 0.38, w * 0.50, h * 0.44, w * 0.56, h * 0.44);
    path.cubicTo(w * 0.62, h * 0.44, w * 0.68, h * 0.40, w * 0.72, h * 0.36);
    path.cubicTo(w * 0.76, h * 0.40, w * 0.82, h * 0.44, w * 0.88, h * 0.44);
    path.cubicTo(w * 0.94, h * 0.44, w * 1.0, h * 0.38, w * 1.0, h * 0.28);
    path.cubicTo(w * 1.0, h * 0.02, w * 0.72, h * 0.0, w * 0.72, h * 0.0);
    path.close();

    // Body
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

  const _Field({
    required this.label,
    required this.placeholder,
    required this.icon,
    this.obscure = false,
    this.suffixIcon,
    this.onSuffixTap,
    this.keyboardType = TextInputType.text,
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
