import 'package:flutter/material.dart';

import '../models/models.dart';
import 'journal_data_source.dart';

class MockJournalDataSource
    implements JournalDataSource {

  final List<JournalEntry> _entries = [

    JournalEntry(
      id: '1',
      type: 'Visit',
      date: '08 JUN',
      facility: 'Kigali University Hospital',
      title: 'Routine endocrinology check-up',
      person: 'Dr. Amara Diallo',
      note: 'HbA1c improved to 6.8%. Continue current regimen.',
      tags: ['Diabetes', 'Follow-up'],
      icon: Icons.medical_services,
    ),

    JournalEntry(
      id: '2',
      type: 'Lab',
      date: '29 MAY',
      facility: 'Central Pathology',
      title: 'Lipid panel & HbA1c',
      person: 'Central Pathology',
      note: 'Triglycerides within normal range.',
      tags: ['Lab'],
      icon: Icons.science,
    ),
  ];

  @override
  Future<List<JournalEntry>> getEntries() async {
    return List.unmodifiable(_entries);
  }

  @override
  Future<void> addEntry(
      JournalEntry entry) async {
    _entries.add(entry);
  }

  @override
  Future<void> updateEntry(
      JournalEntry entry) async {

    final index = _entries.indexWhere(
      (e) => e.id == entry.id,
    );

    if (index != -1) {
      _entries[index] = entry;
    }
  }

  @override
  Future<void> deleteEntry(
      String id) async {
    _entries.removeWhere(
      (e) => e.id == id,
    );
  }
}

