import '../data/reminder_data_source.dart';
import '../models/models.dart';

class ReminderRepository {
  final ReminderDataSource dataSource;

  const ReminderRepository({
    required this.dataSource,
  });

  Future<List<Reminder>> getReminders() {
    return dataSource.getReminders();
  }

  Future<void> addReminder(
    Reminder reminder,
  ) {
    return dataSource.addReminder(reminder);
  }

  Future<void> updateReminder(
    Reminder reminder,
  ) {
    return dataSource.updateReminder(reminder);
  }

  Future<void> deleteReminder(
    String id,
  ) {
    return dataSource.deleteReminder(id);
  }
}

