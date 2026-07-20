import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'auth_providers.dart';
import 'validators.dart';

enum _ResetStage { phone, code, newPassword }

class ForgotPasswordScreen extends ConsumerStatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  ConsumerState<ForgotPasswordScreen> createState() =>
      _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends ConsumerState<ForgotPasswordScreen> {
  final _phoneFormKey = GlobalKey<FormState>();
  final _phoneController = TextEditingController();
  final _otpController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();

  _ResetStage _stage = _ResetStage.phone;
  bool _submitting = false;
  String? _errorText;

  @override
  void dispose() {
    _phoneController.dispose();
    _otpController.dispose();
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  Future<void> _sendCode() async {
    if (!_phoneFormKey.currentState!.validate()) return;
    setState(() {
      _submitting = true;
      _errorText = null;
    });
    await ref
        .read(phoneVerificationControllerProvider.notifier)
        .sendCode(_phoneController.text.trim());
    if (mounted) {
      final status = ref.read(phoneVerificationControllerProvider).status;
      setState(() {
        _submitting = false;
        if (status == PhoneVerificationStatus.codeSent) {
          _stage = _ResetStage.code;
        }
      });
    }
  }

  Future<void> _verifyCode(String verificationId) async {
    if (validateOtpCode(_otpController.text) != null) {
      setState(() => _errorText = validateOtpCode(_otpController.text));
      return;
    }
    setState(() {
      _submitting = true;
      _errorText = null;
    });
    final repo = ref.read(authRepositoryProvider);
    try {
      final credential = repo.smsCredential(
        verificationId: verificationId,
        smsCode: _otpController.text.trim(),
      );
      final userCredential = await repo.signInWithPhoneCredential(credential);
      final uid = userCredential.user?.uid;
      final hasProfile = uid != null && await repo.hasUserProfile(uid);
      if (!hasProfile) {
        await repo.signOut();
        if (mounted) {
          setState(() {
            _errorText = 'No account found for this phone number.';
          });
        }
        return;
      }
      if (mounted) setState(() => _stage = _ResetStage.newPassword);
    } on FirebaseAuthException catch (e) {
      setState(() => _errorText = repo.mapAuthError(e));
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  Future<void> _submitNewPassword() async {
    final passwordError = validatePassword(_passwordController.text);
    if (passwordError != null) {
      setState(() => _errorText = passwordError);
      return;
    }
    if (_passwordController.text != _confirmController.text) {
      setState(() => _errorText = 'Passwords do not match.');
      return;
    }
    setState(() {
      _submitting = true;
      _errorText = null;
    });
    final repo = ref.read(authRepositoryProvider);
    try {
      await repo.updatePassword(_passwordController.text);
      if (mounted) Navigator.of(context).popUntil((route) => route.isFirst);
    } on FirebaseAuthException catch (e) {
      setState(() => _errorText = repo.mapAuthError(e));
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final verification = ref.watch(phoneVerificationControllerProvider);

    ref.listen(phoneVerificationControllerProvider, (previous, next) {
      if (next.status == PhoneVerificationStatus.error) {
        setState(() => _errorText = next.errorMessage);
      }
    });

    return Scaffold(
      appBar: AppBar(title: const Text('Reset password')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: switch (_stage) {
            _ResetStage.phone => _buildPhoneForm(),
            _ResetStage.code => _buildCodeForm(verification),
            _ResetStage.newPassword => _buildNewPasswordForm(),
          },
        ),
      ),
    );
  }

  Widget _buildPhoneForm() {
    return Form(
      key: _phoneFormKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text('Enter your phone number to recover your account.'),
          const SizedBox(height: 16),
          TextFormField(
            controller: _phoneController,
            keyboardType: TextInputType.phone,
            decoration: const InputDecoration(
              labelText: 'Phone number',
              hintText: '+250788123456',
            ),
            validator: validatePhone,
          ),
          if (_errorText != null) ...[
            const SizedBox(height: 8),
            Text(
              _errorText!,
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          ],
          const SizedBox(height: 24),
          FilledButton(
            onPressed: _submitting ? null : _sendCode,
            child: _submitting
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Send code'),
          ),
        ],
      ),
    );
  }

  Widget _buildCodeForm(PhoneVerificationState verification) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Enter the 6-digit code sent to ${_phoneController.text.trim()}.',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _otpController,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(labelText: 'Verification code'),
        ),
        if (_errorText != null) ...[
          const SizedBox(height: 8),
          Text(
            _errorText!,
            style: TextStyle(color: Theme.of(context).colorScheme.error),
          ),
        ],
        const SizedBox(height: 24),
        FilledButton(
          onPressed: _submitting || verification.verificationId == null
              ? null
              : () => _verifyCode(verification.verificationId!),
          child: _submitting
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Verify'),
        ),
      ],
    );
  }

  Widget _buildNewPasswordForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text('Choose a new password.'),
        const SizedBox(height: 16),
        TextFormField(
          controller: _passwordController,
          obscureText: true,
          decoration: const InputDecoration(labelText: 'New password'),
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _confirmController,
          obscureText: true,
          decoration: const InputDecoration(labelText: 'Confirm password'),
        ),
        if (_errorText != null) ...[
          const SizedBox(height: 8),
          Text(
            _errorText!,
            style: TextStyle(color: Theme.of(context).colorScheme.error),
          ),
        ],
        const SizedBox(height: 24),
        FilledButton(
          onPressed: _submitting ? null : _submitNewPassword,
          child: _submitting
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Reset password'),
        ),
      ],
    );
  }
}
