import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/caregiver_data_source.dart';
import '../data/mock_caregiver_data_source.dart';
import '../models/models.dart';
import '../repositories/caregiver_repository.dart';

final caregiverDataSourceProvider =
    Provider<CaregiverDataSource>((ref) {
  return MockCaregiverDataSource();
});

final caregiverRepositoryProvider =
    Provider<CaregiverRepository>((ref) {
  return CaregiverRepository(
    dataSource: ref.read(
      caregiverDataSourceProvider,
    ),
  );
});

class CaregiversNotifier
    extends AsyncNotifier<List<Caregiver>> {

  @override
  Future<List<Caregiver>> build() async {
    final repository = ref.read(
      caregiverRepositoryProvider,
    );
    return repository.getCaregivers();
  }

  Future<void> addCaregiver(
    Caregiver caregiver,
  ) async {
    await ref
        .read(caregiverRepositoryProvider)
        .addCaregiver(caregiver);
    ref.invalidateSelf();
  }

  Future<void> updateCaregiver(
    Caregiver caregiver,
  ) async {
    await ref
        .read(caregiverRepositoryProvider)
        .updateCaregiver(caregiver);
    ref.invalidateSelf();
  }

  Future<void> deleteCaregiver(
    String id,
  ) async {
    await ref
        .read(caregiverRepositoryProvider)
        .deleteCaregiver(id);
    ref.invalidateSelf();
  }

  Future<void> updateRole(
    String id,
    CaregiverRole role,
  ) async {
    final caregivers = await future;
    final caregiver = caregivers.firstWhere(
      (c) => c.id == id,
    );
    await updateCaregiver(
      caregiver.copyWith(
        role: role,
      ),
    );
  }

  Future<void> toggleNotifications(
    String id,
  ) async {
    final caregivers = await future;
    final caregiver = caregivers.firstWhere(
      (c) => c.id == id,
    );
    await updateCaregiver(
      caregiver.copyWith(
        notificationsEnabled:
            !caregiver.notificationsEnabled,
      ),
    );
  }
}

final caregiversProvider =
    AsyncNotifierProvider<
        CaregiversNotifier,
        List<Caregiver>>(
  CaregiversNotifier.new,
);

