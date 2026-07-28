import '../models/models.dart';
import 'profile_data_source.dart';

class MockProfileDataSource
    implements ProfileDataSource {
  UserProfile _profile = UserProfile(
    name: 'Arnold Mugabo',
    initials: 'AM',
    age: 42,
    bloodType: 'O+',
    height: '174 cm',
    patientId: 'PT-102938',
    hba1c: '6.8%',
    bpAvg: '124/82',
    weight: '78 kg',
    allergies: const [
      'Penicillin',
      'Sulfa drugs',
      'Peanuts',
    ],
    emergencyContact: const EmergencyContact(
      name: 'Sarah Mugabo',
      relation: 'Wife',
      phone: '+250 788 123 456',
    ),
  );

  @override
  Future<UserProfile> getProfile() async {
    return _profile;
  }

  @override
  Future<void> updateProfile(
    UserProfile profile,
  ) async {
    _profile = profile;
  }
}

