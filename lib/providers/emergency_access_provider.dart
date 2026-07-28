import 'dart:math';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/models.dart';
import '../providers/providers.dart';

class EmergencyAccessNotifier
    extends AsyncNotifier<
        EmergencyAccessCode?> {

  @override
  Future<EmergencyAccessCode?>
      build() async {
    final repository = ref.watch(
      emergencyAccessRepositoryProvider,
    );
    return repository.getAccessCode();
  }

  Future<void> generateCode(
      String scope) async {

    final repository = ref.read(
      emergencyAccessRepositoryProvider,
    );

    final random = Random();

    final code =
        (100000 + random.nextInt(900000))
            .toString();
    final accessCode =
        EmergencyAccessCode(
      code: code,
      expiresAt: DateTime.now().add(
        const Duration(minutes: 30),
      ),
      scope: scope,
    );
    await repository.generateCode(
      accessCode,
    );
    state = AsyncData(accessCode);
  }

  Future<void> revokeCode() async {
    final repository = ref.read(
      emergencyAccessRepositoryProvider,
    );
    await repository.revokeCode();
    state = const AsyncData(null);
  }
}

