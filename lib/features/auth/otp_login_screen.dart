import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'auth_providers.dart';
import 'validators.dart';

enum _OtpStage { phone, code }

class OtpLoginScreen extends ConsumerStatefulWidget {
  const OtpLoginScreen({super.key});

  @override
  ConsumerState<OtpLoginScreen> createState() => _OtpLoginScreenState();
}

class _OtpLoginScreenState extends ConsumerState<OtpLoginScreen> {
  final _phoneFormKey = GlobalKey<FormState>();
  final _phoneController = TextEditingController();
  final _otpController = TextEditingController();

  _OtpStage _stage = _OtpStage.phone;
  bool _submitting = false;
  String? _errorText;

  @override
  void dispose() {
    _phoneController.dispose();
    _otpController.dispose();
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
          _stage = _OtpStage.code;
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
            _errorText = 'No account found for this phone number. '
                'Please register first.';
          });
        }
        return;
      }
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
      appBar: AppBar(title: const Text('Log in with a one-time code')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: _stage == _OtpStage.phone
              ? _buildPhoneForm()
              : _buildCodeForm(verification),
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
              : const Text('Verify & log in'),
        ),
      ],
    );
  }
}
