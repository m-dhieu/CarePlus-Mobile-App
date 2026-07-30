import 'dart:convert';

import 'package:flutter/material.dart';

import '../models/models.dart';
import 'app_database.dart';

Medication medicationFromRow(MedicationRow row) => Medication(
      id: row.id,
      name: row.name,
      dose: row.dose,
      condition: row.condition,
      refills: row.refills,
    );

Reminder reminderFromRow(ReminderRow row) => Reminder(
      id: row.id,
      medicationName: row.medicationName,
      time: TimeOfDay(hour: row.hour, minute: row.minute),
      days: (jsonDecode(row.days) as List).map((e) => e == true).toList(),
      enabled: row.enabled,
    );

JournalEntry journalFromRow(JournalEntryRow row) => JournalEntry(
      id: row.id,
      type: row.type,
      date: row.date,
      facility: row.facility,
      title: row.title,
      person: row.person,
      note: row.note,
      tags: (jsonDecode(row.tags) as List).cast<String>(),
      // ignore: non_const_argument_for_const_parameter
      icon: IconData(row.iconCodePoint, fontFamily: 'MaterialIcons'),
    );

MedicalDocument documentFromRow(DocumentRow row) => MedicalDocument(
      id: row.id,
      // ignore: non_const_argument_for_const_parameter
      icon: IconData(row.iconCodePoint, fontFamily: 'MaterialIcons'),
      name: row.name,
      source: row.source,
      ocrText: row.ocrText,
      storagePath: row.storagePath,
      downloadUrl: row.downloadUrl,
      mimeType: row.mimeType,
      sizeBytes: row.sizeBytes,
      createdAt: row.createdAt,
    );

Caregiver caregiverFromRow(CaregiverRow row) => Caregiver(
      id: row.id,
      name: row.name,
      relation: row.relation,
      phone: row.phone,
      role: CaregiverRole.values.firstWhere(
        (r) => r.name == row.role,
        orElse: () => CaregiverRole.viewOnly,
      ),
      notificationsEnabled: row.notificationsEnabled,
      status: row.status,
      invitedAt: row.invitedAt,
    );

UserProfile profileFromRow(UserProfileRow row) => UserProfile(
      name: row.name,
      initials: row.initials,
      phone: row.phone,
      age: row.age,
      bloodType: row.bloodType,
      height: row.height,
      patientId: row.patientId,
      hba1c: row.hba1c,
      bpAvg: row.bpAvg,
      weight: row.weight,
      allergies: (jsonDecode(row.allergies) as List).cast<String>(),
      emergencyContact: EmergencyContact(
        name: row.emergencyName,
        relation: row.emergencyRelation,
        phone: row.emergencyPhone,
      ),
    );

RecordShareToken shareTokenFromRow(ShareTokenRow row) => RecordShareToken(
      id: row.id,
      token: row.token,
      doctorName: row.doctorName,
      expiresAt: row.expiresAt,
      redeemed: row.redeemed,
      redeemedAt: row.redeemedAt,
    );

EmergencyAccessCode emergencyFromRow(EmergencyAccessRow row) =>
    EmergencyAccessCode(
      code: row.code,
      expiresAt: row.expiresAt,
      scope: row.scope,
    );

Map<String, MetricSeries> metricsFromRows(List<MetricPointRow> rows) {
  final byKey = <String, List<MetricPointRow>>{};
  for (final row in rows) {
    byKey.putIfAbsent(row.seriesKey, () => []).add(row);
  }
  return {
    for (final entry in byKey.entries)
      entry.key: MetricSeries(
        label: entry.value.first.label,
        unit: entry.value.first.unit,
        points: [
          for (final r in entry.value
            ..sort((a, b) => a.date.compareTo(b.date)))
            MetricPoint(date: r.date, value: r.value),
        ],
      ),
  };
}
