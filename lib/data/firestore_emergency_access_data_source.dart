/*
import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/models.dart';
import 'emergency_access_data_source.dart';

class FirestoreEmergencyAccessDataSource
    implements EmergencyAccessDataSource {

  final FirebaseFirestore firestore;

  FirestoreEmergencyAccessDataSource({
    required this.firestore,
  });

  @override
  Future<EmergencyAccessCode?>
      getAccessCode() async {
    final snapshot = await firestore
        .collection('emergency_access')
        .limit(1)
        .get();
    if (snapshot.docs.isEmpty) {
      return null;
    }
    final doc = snapshot.docs.first;
    return EmergencyAccessCode.fromMap(
      doc.id,
      doc.data(),
    );
  }

  @override
  Future<void> generateCode(
      EmergencyAccessCode code) async {
    await firestore
        .collection('emergency_access')
        .doc('active')
        .set(
          code.toMap(),
        );
  }

  @override
  Future<void> revokeCode() async {
    await firestore
        .collection('emergency_access')
        .doc('active')
        .delete();
  }
}
*/

