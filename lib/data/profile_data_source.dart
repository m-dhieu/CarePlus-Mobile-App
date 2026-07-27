import '../models/models.dart';

abstract class ProfileDataSource {
  Future<UserProfile> getProfile();

  Future<void> updateProfile(
    UserProfile profile,
  );
}

