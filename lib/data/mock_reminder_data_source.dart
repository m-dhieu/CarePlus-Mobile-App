import 'package:flutter/material.dart';

import '../models/models.dart';
import 'reminder_data_source.dart';

class MockReminderDataSource
    implements ReminderDataSource {

  final List<Reminder> _reminders = [
    Reminder(
      id: '1',
      medicationName: 'Metformin',
      time: const TimeOfDay(
        hour: 8,
        minute: 0,
      ),
      days: List.filled(7, true),
    ),

    Reminder(
      id: '2',
      medicationName: 'Lisinopril',
      time: const TimeOfDay(
        hour: 20,
        minute: 0,
      ),
      days: [
        true,
        true,
        true,
        true,
        true,
        false,
        false,
      ],
    ),
  ];

  @override
  Future<List<Reminder>> getReminders() async {
    return List.unmodifiable(_reminders);
  }

  @override
  Future<void> addReminder(
    Reminder reminder,
  ) async {
    _reminders.add(reminder);
  }

  @override
  Future<void> updateReminder(
    Reminder reminder,
  ) async {
    final index = _reminders.indexWhere(
      (r) => r.id == reminder.id,
    );

    if (index != -1) {
      _reminders[index] = reminder;
    }
  }

  @override
  Future<void> deleteReminder(
    String id,
  ) async {
    _reminders.removeWhere(
      (r) => r.id == id,
    );
  }
}

