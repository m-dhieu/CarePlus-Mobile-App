/*
import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/models.dart';
import 'document_data_source.dart';

class FirestoreDocumentDataSource
    implements DocumentDataSource {

  final FirebaseFirestore firestore;

  FirestoreDocumentDataSource({
    required this.firestore,
  });

  @override
  Future<List<MedicalDocument>> getDocuments() async {

    final snapshot = await firestore
        .collection('documents')
        .get();

    return snapshot.docs.map((doc) {

      final data = doc.data();

      return MedicalDocument(
        id: doc.id,
        icon: Icons.description,
        name: data['name'] ?? '',
        source: data['source'] ?? '',
        ocrText: data['ocrText'],
      );

    }).toList();

  }

  @override
  Future<void> addDocument(
      MedicalDocument document) async {

    await firestore
        .collection('documents')
        .doc(document.id)
        .set(
          document.toMap(),
        );

  }

  @override
  Future<void> updateDocument(
      MedicalDocument document) async {

    await firestore
        .collection('documents')
        .doc(document.id)
        .update(
          document.toMap(),
        );

  }

  @override
  Future<void> deleteDocument(
      String id) async {

    await firestore
        .collection('documents')
        .doc(id)
        .delete();

  }

}
*/

