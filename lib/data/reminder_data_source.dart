import '../models/models.dart';

/*
reminder data currently comes from MockReminderDataSource
future should come from FirestoreReminderDataSource
*/
abstract class ReminderDataSource {
  Future<List<Reminder>> getReminders();

  Future<void> addReminder(
    Reminder reminder,
  );

  Future<void> updateReminder(
    Reminder reminder,
  );

  Future<void> deleteReminder(
    String id,
  );
}

