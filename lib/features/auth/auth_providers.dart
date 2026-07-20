import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app_user.dart';
import 'auth_repository.dart';

final authRepositoryProvider = Provider<CareAuthRepository>((ref) {
  return CareAuthRepository();
});

final authStateProvider = StreamProvider<User?>((ref) {
  return ref.watch(authRepositoryProvider).authStateChanges();
});

final currentAppUserProvider = StreamProvider<AppUser?>((ref) {
  final user = ref.watch(authStateProvider).value;
  if (user == null) return Stream.value(null);
  return ref.watch(authRepositoryProvider).watchUser(user.uid);
});

enum PhoneVerificationStatus { idle, sending, codeSent, autoVerified, error }

class PhoneVerificationState {
  const PhoneVerificationState({
    this.status = PhoneVerificationStatus.idle,
    this.verificationId,
    this.resendToken,
    this.errorMessage,
    this.credential,
  });

  final PhoneVerificationStatus status;
  final String? verificationId;
  final int? resendToken;
  final String? errorMessage;
  final PhoneAuthCredential? credential;

  PhoneVerificationState copyWith({
    PhoneVerificationStatus? status,
    String? verificationId,
    int? resendToken,
    String? errorMessage,
    PhoneAuthCredential? credential,
  }) {
    return PhoneVerificationState(
      status: status ?? this.status,
      verificationId: verificationId ?? this.verificationId,
      resendToken: resendToken ?? this.resendToken,
      errorMessage: errorMessage,
      credential: credential ?? this.credential,
    );
  }
}

class PhoneVerificationController extends Notifier<PhoneVerificationState> {
  @override
  PhoneVerificationState build() => const PhoneVerificationState();

  Future<void> sendCode(String phone) async {
    state = state.copyWith(status: PhoneVerificationStatus.sending);
    final repo = ref.read(authRepositoryProvider);
    await repo.startPhoneVerification(
      phone: phone,
      onAutoVerified: (credential) {
        state = state.copyWith(
          status: PhoneVerificationStatus.autoVerified,
          credential: credential,
        );
      },
      onFailed: (error) {
        state = state.copyWith(
          status: PhoneVerificationStatus.error,
          errorMessage: repo.mapAuthError(error),
        );
      },
      onCodeSent: (verificationId, resendToken) {
        state = state.copyWith(
          status: PhoneVerificationStatus.codeSent,
          verificationId: verificationId,
          resendToken: resendToken,
        );
      },
      forceResendingToken: state.resendToken,
    );
  }

  void reset() {
    state = const PhoneVerificationState();
  }
}

final phoneVerificationControllerProvider =
    NotifierProvider<PhoneVerificationController, PhoneVerificationState>(
  PhoneVerificationController.new,
);
