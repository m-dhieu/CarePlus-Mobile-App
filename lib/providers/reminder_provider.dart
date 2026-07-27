import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/mock_reminder_data_source.dart';
import '../data/reminder_data_source.dart';
import '../models/models.dart';
import '../repositories/reminder_repository.dart';

final reminderDataSourceProvider =
    Provider<ReminderDataSource>((ref) {
  return MockReminderDataSource();

  /*
  Later:

  return FirestoreReminderDataSource(
    firestore: FirebaseFirestore.instance,
  );
  */
});

final reminderRepositoryProvider =
    Provider<ReminderRepository>((ref) {
  return ReminderRepository(
    dataSource: ref.read(
      reminderDataSourceProvider,
    ),
  );
});

class ReminderNotifier
    extends AsyncNotifier<List<Reminder>> {

  @override
  Future<List<Reminder>> build() async {
    final repository = ref.read(
      reminderRepositoryProvider,
    );

    return repository.getReminders();
  }

  Future<void> addReminder(
    Reminder reminder,
  ) async {
    await ref
        .read(reminderRepositoryProvider)
        .addReminder(reminder);

    ref.invalidateSelf();
  }

  Future<void> updateReminder(
    Reminder reminder,
  ) async {
    await ref
        .read(reminderRepositoryProvider)
        .updateReminder(reminder);

    ref.invalidateSelf();
  }

  Future<void> deleteReminder(
    String id,
  ) async {
    await ref
        .read(reminderRepositoryProvider)
        .deleteReminder(id);

    ref.invalidateSelf();
  }

  Future<void> toggleReminder(
    String id,
  ) async {
    final current = state.value ?? [];

    final reminder = current.firstWhere(
      (r) => r.id == id,
      orElse: () => throw Exception(
        'Reminder not found',
      ),
    );

    final updated = reminder.copyWith(
      enabled: !reminder.enabled,
    );

    await ref
        .read(reminderRepositoryProvider)
        .updateReminder(updated);

    ref.invalidateSelf();
  }
}

final remindersProvider = AsyncNotifierProvider<
    ReminderNotifier,
    List<Reminder>>(
  ReminderNotifier.new,
);

