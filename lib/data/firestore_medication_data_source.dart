/*
import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/models.dart';
import 'medication_data_source.dart';

class FirestoreMedicationDataSource 
    implements MedicationDataSource {

  final FirebaseFirestore firestore;

  FirestoreMedicationDataSource({
    required this.firestore,
  });

  @override
  Future<List<Medication>> getMedications() async {

    final snapshot = await firestore
        .collection('medications')
        .get();

    return snapshot.docs.map((doc) {

      final data = doc.data();

      return Medication(
        id: doc.id,
        name: data['name'],
        dose: data['dose'],
        condition: data['condition'],
        refills: data['refills'],
      );

    }).toList();
  }

  @override
  Future<void> addMedication(
    Medication medication,
  ) async {

    await firestore
        .collection('medications')
        .doc(medication.id)
        .set({

      'name': medication.name,
      'dose': medication.dose,
      'condition': medication.condition,
      'refills': medication.refills,

    });
  }

  @override
  Future<void> updateMedication(
    Medication medication,
  ) async {

    await firestore
        .collection('medications')
        .doc(medication.id)
        .update({

      'name': medication.name,
      'dose': medication.dose,
      'condition': medication.condition,
      'refills': medication.refills,

    });
  }

  @override
  Future<void> deleteMedication(
    String id,
  ) async {

    await firestore
        .collection('medications')
        .doc(id)
        .delete();
  }
}
*/

