import '../models/models.dart';

abstract class EmergencyAccessDataSource {

  Future<EmergencyAccessCode?>
      getAccessCode();

  Future<void> generateCode(
    EmergencyAccessCode code,
  );

  Future<void> revokeCode();
}

