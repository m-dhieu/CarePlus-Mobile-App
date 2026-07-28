/*
import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/models.dart';
import 'caregiver_data_source.dart';

class FirestoreCaregiverDataSource
    implements CaregiverDataSource {

  final FirebaseFirestore firestore;

  FirestoreCaregiverDataSource({
    required this.firestore,
  });

  @override
  Future<List<Caregiver>> getCaregivers() async {
    final snapshot =
        await firestore
        .collection('caregivers')
        .get();
    return snapshot.docs.map((doc){
      return Caregiver.fromMap(
        doc.id,
        doc.data(),
      );
    }).toList();
  }

  @override
  Future<void> addCaregiver(
      Caregiver caregiver) async {
    await firestore
        .collection('caregivers')
        .doc(caregiver.id)
        .set(
          caregiver.toMap(),
        );
  }

  @override
  Future<void> updateCaregiver(
      Caregiver caregiver) async {
    await firestore
        .collection('caregivers')
        .doc(caregiver.id)
        .update(
          caregiver.toMap(),
        );
  }

  @override
  Future<void> deleteCaregiver(
      String id) async {
    await firestore
        .collection('caregivers')
        .doc(id)
        .delete();
  }
}
*/

