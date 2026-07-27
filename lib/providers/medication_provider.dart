import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/medication_data_source.dart';
import '../data/mock_medication_data_source.dart';
import '../models/models.dart';
import '../repositories/medication_repository.dart';

final medicationDataSourceProvider =
    Provider<MedicationDataSource>((ref) {
  /*
  current: data comes from mock source
  later: replace with firestore source
  */
  return MockMedicationDataSource();
  /*
  later:
  return FirestoreMedicationDataSource(
    firestore: FirebaseFirestore.instance,
  );
  */
});

final medicationRepositoryProvider =
    Provider<MedicationRepository>((ref) {
  return MedicationRepository(
    dataSource: ref.read(
      medicationDataSourceProvider,
    ),
  );
});

class MedicationsNotifier
    extends AsyncNotifier<List<Medication>> {

  @override
  Future<List<Medication>> build() async {
    final repository =
        ref.read(
          medicationRepositoryProvider,
        );
    return repository.getMedications();
  }

  Future<void> requestRefill(String id) async {
    final current =
        state.value ?? [];

    final medication =
        current.firstWhere(
          (m) => m.id == id,
          orElse: () =>
              throw Exception(
                'Medication not found',
              ),
        );

    final updatedMedication =
        Medication(
          id: medication.id,
          name: medication.name,
          dose: medication.dose,
          condition: medication.condition,
          refills: medication.refills + 1,
        );

    await ref
        .read(
          medicationRepositoryProvider,
        )
        .updateMedication(
          updatedMedication,
        );

    /*
    reload data from repository
    later this will also update local db update & sync Firestore
    */
    ref.invalidateSelf();
  }
}

final medicationsProvider =
    AsyncNotifierProvider<
        MedicationsNotifier,
        List<Medication>>(
  MedicationsNotifier.new,
);

