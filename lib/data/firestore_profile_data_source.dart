/*
import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/models.dart';
import 'profile_data_source.dart';

class FirestoreProfileDataSource
    implements ProfileDataSource {
  final FirebaseFirestore firestore;
  FirestoreProfileDataSource({
    required this.firestore,
  });

  @override
  Future<UserProfile> getProfile() async {
    final doc = await firestore
        .collection('profile')
        .doc('currentUser')
        .get();
    return UserProfile.fromMap(
      doc.data()!,
    );
  }

  @override
  Future<void> updateProfile(
      UserProfile profile) async {
    await firestore
        .collection('profile')
        .doc('currentUser')
        .set(
          profile.toMap(),
        );
  }
}
*/

