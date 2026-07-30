import '../data/emergency_access_data_source.dart';
import '../models/models.dart';

class EmergencyAccessRepository {

  final EmergencyAccessDataSource
      dataSource;

  EmergencyAccessRepository({
    required this.dataSource,
  });

  Future<EmergencyAccessCode?>
      getAccessCode() {
    return dataSource.getAccessCode();
  }

  Future<void> generateCode(
      EmergencyAccessCode code) {
    return dataSource.generateCode(
      code,
    );
  }

  Future<void> revokeCode() {
    return dataSource.revokeCode();
  }
}

