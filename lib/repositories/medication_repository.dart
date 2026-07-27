import '../data/medication_data_source.dart';
import '../models/models.dart';

class MedicationRepository {
  final MedicationDataSource dataSource;

  MedicationRepository({
    required this.dataSource,
  });

  // fetch all meds
  Future<List<Medication>> getMedications() {
    return dataSource.getMedications();
  }

  // add new med
  Future<void> addMedication(
    Medication medication,
  ) {
    return dataSource.addMedication(
      medication,
    );
  }

  // update existing med
  Future<void> updateMedication(
    Medication medication,
  ) {
    return dataSource.updateMedication(
      medication,
    );
  }

  // delete med by id
  Future<void> deleteMedication(
    String id,
  ) {
    return dataSource.deleteMedication(
      id,
    );
  }
}

