import '../data/caregiver_data_source.dart';
import '../models/models.dart';

class CaregiverRepository {
  final CaregiverDataSource dataSource;

  CaregiverRepository({
    required this.dataSource,
  });

  Future<List<Caregiver>> getCaregivers() {
    return dataSource.getCaregivers();
  }

  Future<void> addCaregiver(
    Caregiver caregiver,
  ) {
    return dataSource.addCaregiver(
      caregiver,
    );
  }

  Future<void> updateCaregiver(
    Caregiver caregiver,
  ) {
    return dataSource.updateCaregiver(
      caregiver,
    );
  }

  Future<void> deleteCaregiver(
    String id,
  ) {
    return dataSource.deleteCaregiver(
      id,
    );
  }
}

