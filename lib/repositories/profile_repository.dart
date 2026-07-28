import '../data/profile_data_source.dart';
import '../models/models.dart';

class ProfileRepository {
  final ProfileDataSource dataSource;
  ProfileRepository({
    required this.dataSource,
  });
  Future<UserProfile> getProfile() {
    return dataSource.getProfile();
  }
  Future<void> updateProfile(
    UserProfile profile,
  ) {
    return dataSource.updateProfile(
      profile,
    );
  }
}

