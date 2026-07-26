import 'package:flutter/material.dart';

// reminder model

class Reminder {
  final String id;
  final String medicationName;
  final TimeOfDay time;
  final List<bool> days;
  final bool enabled;

  const Reminder({
    required this.id,
    required this.medicationName,
    required this.time,
    required this.days,
    this.enabled = true,
  });

  Reminder copyWith({
    String? id,
    String? medicationName,
    TimeOfDay? time,
    List<bool>? days,
    bool? enabled,
  }) {
    return Reminder(
      id: id ?? this.id,
      medicationName: medicationName ?? this.medicationName,
      time: time ?? this.time,
      days: days ?? this.days,
      enabled: enabled ?? this.enabled,
    );
  }

  String get daysLabel {
    const labels = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];

    final active = <String>[];

    for (int i = 0; i < 7; i++) {
      if (days[i]) active.add(labels[i]);
    }

    if (active.length == 7) {
      return 'Every day';
    }

    return active.join(' · ');
  }

  factory Reminder.fromMap(
    String id,
    Map<String, dynamic> map,
  ) {
    final time = (map['time'] ?? '08:00') as String;

    final parts = time.split(':');

    return Reminder(
      id: id,
      medicationName: map['medicationName'] ?? '',
      time: TimeOfDay(
        hour: int.parse(parts[0]),
        minute: int.parse(parts[1]),
      ),
      days: List<bool>.from(
        map['days'] ?? List.filled(7, true),
      ),
      enabled: map['enabled'] ?? true,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'medicationName': medicationName,
      'time':
          '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}',
      'days': days,
      'enabled': enabled,
    };
  }
}

