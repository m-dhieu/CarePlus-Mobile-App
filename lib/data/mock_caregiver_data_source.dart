import '../models/models.dart';
import 'caregiver_data_source.dart';

class MockCaregiverDataSource
    implements CaregiverDataSource {
  final List<Caregiver> _caregivers = [
    const Caregiver(
      id: '1',
      name: 'Grace Mugisha',
      relation: 'Spouse',
      phone: '+250 788 000 000',
      role: CaregiverRole.fullAccess,
    ),
  ];

  @override
  Future<List<Caregiver>> getCaregivers() async {
    return _caregivers;
  }

  @override
  Future<void> addCaregiver(
    Caregiver caregiver,
  ) async {
    _caregivers.add(caregiver);
  }

  @override
  Future<void> updateCaregiver(
    Caregiver caregiver,
  ) async {
    final index = _caregivers.indexWhere(
      (c) => c.id == caregiver.id,
    );
    if(index != -1){
      _caregivers[index] = caregiver;
    }
  }

  @override
  Future<void> deleteCaregiver(
    String id,
  ) async {
    _caregivers.removeWhere(
      (c) => c.id == id,
    );
  }
}

