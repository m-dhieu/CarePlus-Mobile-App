import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/mock_profile_data_source.dart';
import '../data/profile_data_source.dart';
import '../models/models.dart';
import '../repositories/profile_repository.dart';

final profileDataSourceProvider =
    Provider<ProfileDataSource>((ref) {
  return MockProfileDataSource();
});

final profileRepositoryProvider =
    Provider<ProfileRepository>((ref) {
  return ProfileRepository(
    dataSource:
        ref.read(profileDataSourceProvider),
  );
});

class ProfileNotifier
    extends AsyncNotifier<UserProfile> {
  @override
  Future<UserProfile> build() async {
    return ref
        .read(profileRepositoryProvider)
        .getProfile();
  }
  Future<void> updateProfile(
    UserProfile profile,
  ) async {
    await ref
        .read(profileRepositoryProvider)
        .updateProfile(profile);
    ref.invalidateSelf();
  }
}

final userProfileProvider =
    AsyncNotifierProvider<
        ProfileNotifier,
        UserProfile>(
      ProfileNotifier.new,
    );

