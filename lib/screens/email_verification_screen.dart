import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../features/auth/auth_providers.dart';
import '../providers/providers.dart';
import '../widgets/shared_widgets.dart';

class EmailVerificationScreen extends ConsumerStatefulWidget {
  const EmailVerificationScreen({super.key});

  @override
  ConsumerState<EmailVerificationScreen> createState() => _EmailVerificationScreenState();
}

class _EmailVerificationScreenState extends ConsumerState<EmailVerificationScreen> {
  bool _busy = false;

  Future<void> _resend() async {
    setState(() => _busy = true);
    final repo = ref.read(authRepositoryProvider);
    try {
      await repo.resendVerificationEmail();
      ref.read(toastProvider.notifier).show('Verification email sent');
    } catch (e) {
      ref.read(toastProvider.notifier).show('Could not send email — try again');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _checkVerified() async {
    setState(() => _busy = true);
    final repo = ref.read(authRepositoryProvider);
    try {
      await repo.reloadUser();
      if (repo.currentUser?.emailVerified != true) {
        ref.read(toastProvider.notifier).show('Not verified yet — check your inbox');
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final email = ref.watch(authStateProvider).value?.email ?? 'your email';

    return Container(
      color: teal50,
      padding: const EdgeInsets.fromLTRB(24, 56, 24, 32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.mark_email_unread, size: 56, color: teal600),
          const SizedBox(height: 24),
          const Text(
            'Verify your email',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: teal700),
          ),
          const SizedBox(height: 12),
          Text(
            'We sent a verification link to $email. Click it, then come back here.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 13, color: slate500),
          ),
          const SizedBox(height: 32),
          ElevatedButton(
            onPressed: _busy ? null : _checkVerified,
            style: ElevatedButton.styleFrom(
              backgroundColor: teal600,
              foregroundColor: Colors.white,
              minimumSize: const Size.fromHeight(48),
              shape: const StadiumBorder(),
            ),
            child: Text(_busy ? 'Checking...' : "I've verified"),
          ),
          const SizedBox(height: 12),
          TextButton(
            onPressed: _busy ? null : _resend,
            child: const Text('Resend email', style: TextStyle(color: teal700)),
          ),
          TextButton(
            onPressed: _busy ? null : () => ref.read(authRepositoryProvider).signOut(),
            child: Text('Sign out', style: TextStyle(color: slate500)),
          ),
        ],
      ),
    );
  }
}
