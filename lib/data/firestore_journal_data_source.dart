/*
import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/models.dart';
import 'journal_data_source.dart';

class FirestoreJournalDataSource
    implements JournalDataSource {

  final FirebaseFirestore firestore;

  FirestoreJournalDataSource({
    required this.firestore,
  });

  @override
  Future<List<JournalEntry>> getEntries() async {

    final snapshot = await firestore
        .collection('journal')
        .get();

    return snapshot.docs.map((doc) {
      return JournalEntry.fromMap(
        doc.id,
        doc.data(),
      );
    }).toList();
  }

  @override
  Future<void> addEntry(
      JournalEntry entry) async {

    await firestore
        .collection('journal')
        .doc(entry.id)
        .set(entry.toMap());
  }

  @override
  Future<void> updateEntry(
      JournalEntry entry) async {

    await firestore
        .collection('journal')
        .doc(entry.id)
        .update(entry.toMap());
  }

  @override
  Future<void> deleteEntry(
      String id) async {

    await firestore
        .collection('journal')
        .doc(id)
        .delete();
  }
}
*/

