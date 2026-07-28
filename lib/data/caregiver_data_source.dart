import '../models/models.dart';

abstract class CaregiverDataSource {
  Future<List<Caregiver>> getCaregivers();
  Future<void> addCaregiver(
    Caregiver caregiver,
  );
  Future<void> updateCaregiver(
    Caregiver caregiver,
  );
  Future<void> deleteCaregiver(
    String id,
  );
}

