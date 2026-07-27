import '../models/models.dart';

/*
current med data comes from MockMedicationDataSource
future should come from FirestoreMedicationDataSource
*/
abstract class MedicationDataSource {

  Future<List<Medication>> getMedications();

  Future<void> addMedication(
    Medication medication,
  );

  Future<void> updateMedication(
    Medication medication,
  );

  Future<void> deleteMedication(
    String id,
  );
}

