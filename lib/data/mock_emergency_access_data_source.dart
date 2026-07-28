import '../models/models.dart';

import 'emergency_access_data_source.dart';

class MockEmergencyAccessDataSource
    implements EmergencyAccessDataSource {

  EmergencyAccessCode? _code;

  @override
  Future<EmergencyAccessCode?>
      getAccessCode() async {
    return _code;
  }

  @override
  Future<void> generateCode(
    EmergencyAccessCode code,
  ) async {
    _code = code;
  }

  @override
  Future<void> revokeCode() async {
    _code = null;
  }
}

