/*
import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/models.dart';
import 'reminder_data_source.dart';

class FirestoreReminderDataSource
    implements ReminderDataSource {

  final FirebaseFirestore firestore;

  FirestoreReminderDataSource({
    required this.firestore,
  });

  @override
  Future<List<Reminder>> getReminders() async {

    final snapshot = await firestore
        .collection('reminders')
        .get();

    return snapshot.docs.map((doc) {

      return Reminder.fromMap(
        doc.id,
        doc.data(),
      );

    }).toList();

  }

  @override
  Future<void> addReminder(
      Reminder reminder) async {

    await firestore
        .collection('reminders')
        .doc(reminder.id)
        .set(reminder.toMap());

  }

  @override
  Future<void> updateReminder(
      Reminder reminder) async {

    await firestore
        .collection('reminders')
        .doc(reminder.id)
        .update(reminder.toMap());

  }

  @override
  Future<void> deleteReminder(
      String id) async {

    await firestore
        .collection('reminders')
        .doc(id)
        .delete();

  }

}
*/

