import 'package:flutter/material.dart';
// journal model

class JournalEntry {
  final String id;
  final String type;
  final String date;
  final String facility;
  final String title;
  final String person;
  final String note;
  final List<String> tags;
  final IconData icon;

  const JournalEntry({
    required this.id,
    required this.type,
    required this.date,
    required this.facility,
    required this.title,
    required this.person,
    required this.note,
    required this.tags,
    required this.icon,
  });

  JournalEntry copyWith({
    String? id,
    String? type,
    String? date,
    String? facility,
    String? title,
    String? person,
    String? note,
    List<String>? tags,
    IconData? icon,
  }) {
    return JournalEntry(
      id: id ?? this.id,
      type: type ?? this.type,
      date: date ?? this.date,
      facility: facility ?? this.facility,
      title: title ?? this.title,
      person: person ?? this.person,
      note: note ?? this.note,
      tags: tags ?? this.tags,
      icon: icon ?? this.icon,
    );
  }

  factory JournalEntry.fromMap(
    String id,
    Map<String, dynamic> map,
  ) {
    return JournalEntry(
      id: id,
      type: map['type'] ?? '',
      date: map['date'] ?? '',
      facility: map['facility'] ?? '',
      title: map['title'] ?? '',
      person: map['person'] ?? '',
      note: map['note'] ?? '',
      tags: List<String>.from(map['tags'] ?? []),
      icon: Icons.description,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'type': type,
      'date': date,
      'facility': facility,
      'title': title,
      'person': person,
      'note': note,
      'tags': tags,
    };
  }
}

