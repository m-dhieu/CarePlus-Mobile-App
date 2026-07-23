import 'package:flutter/material.dart';

// ── Auth / Onboarding ────────────────────────────────────────────────────────

class OnboardingPage {
  final IconData icon;
  final String title;
  final String subtitle;
  const OnboardingPage({required this.icon, required this.title, required this.subtitle});
}

// ── User ─────────────────────────────────────────────────────────────────────

class UserProfile {
  final String name;
  final String initials;
  final int age;
  final String bloodType;
  final String height;
  final String patientId;
  final String hba1c;
  final String bpAvg;
  final String weight;
  final List<String> allergies;
  final EmergencyContact emergencyContact;

  const UserProfile({
    required this.name,
    required this.initials,
    required this.age,
    required this.bloodType,
    required this.height,
    required this.patientId,
    required this.hba1c,
    required this.bpAvg,
    required this.weight,
    required this.allergies,
    required this.emergencyContact,
  });
}

// ── Emergency ────────────────────────────────────────────────────────────────

class EmergencyContact {
  final String name;
  final String relation;
  final String phone;
  const EmergencyContact({required this.name, required this.relation, required this.phone});
}

class EmergencyAccessCode {
  final String code;
  final DateTime expiresAt;
  final String scope; // 'full' | 'summary'
  EmergencyAccessCode({required this.code, required this.expiresAt, required this.scope});

  bool get isExpired => DateTime.now().isAfter(expiresAt);
}

// ── Medications / Reminders ───────────────────────────────────────────────────

class Medication {
  final String id;
  final String name;
  final String dose;
  final String condition;
  final int refills;
  Medication({required this.id, required this.name, required this.dose, required this.condition, required this.refills});
}

class Reminder {
  final String id;
  final String medicationName;
  final TimeOfDay time;
  final List<bool> days; // Mon–Sun
  bool enabled;
  Reminder({required this.id, required this.medicationName, required this.time, required this.days, this.enabled = true});

  String get daysLabel {
    const labels = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];
    final active = <String>[];
    for (int i = 0; i < 7; i++) {
      if (days[i]) active.add(labels[i]);
    }
    if (active.length == 7) return 'Every day';
    return active.join(' · ');
  }
}

// ── Journal ───────────────────────────────────────────────────────────────────

class JournalEntry {
  final String id;
  final String type; // Visit | Lab | Prescription | Procedure
  final String date;
  final String facility;
  final String title;
  final String person;
  final String note;
  final List<String> tags;
  final IconData icon;
  JournalEntry({
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
}

// ── Records / Documents ───────────────────────────────────────────────────────

class MedicalDocument {
  final String id;
  final IconData icon;
  final String name;
  final String source;
  final String? ocrText; // populated after OCR import
  MedicalDocument({required this.id, required this.icon, required this.name, required this.source, this.ocrText});

  MedicalDocument copyWith({String? ocrText}) =>
      MedicalDocument(id: id, icon: icon, name: name, source: source, ocrText: ocrText ?? this.ocrText);
}

class RecordShareToken {
  final String token;
  final String doctorName;
  final DateTime expiresAt;
  RecordShareToken({required this.token, required this.doctorName, required this.expiresAt});
  bool get isExpired => DateTime.now().isAfter(expiresAt);
}

// ── Caregiver ─────────────────────────────────────────────────────────────────

enum CaregiverRole { fullAccess, viewOnly, medsOnly }

class Caregiver {
  final String id;
  final String name;
  final String relation;
  final String phone;
  final CaregiverRole role;
  final bool notificationsEnabled;
  Caregiver({
    required this.id,
    required this.name,
    required this.relation,
    required this.phone,
    required this.role,
    this.notificationsEnabled = true,
  });

  Caregiver copyWith({CaregiverRole? role, bool? notificationsEnabled}) => Caregiver(
        id: id, name: name, relation: relation, phone: phone,
        role: role ?? this.role,
        notificationsEnabled: notificationsEnabled ?? this.notificationsEnabled,
      );

  String get roleLabel {
    switch (role) {
      case CaregiverRole.fullAccess: return 'Full access';
      case CaregiverRole.viewOnly:   return 'View only';
      case CaregiverRole.medsOnly:   return 'Meds only';
    }
  }
}

// ── Metrics ───────────────────────────────────────────────────────────────────

class MetricPoint {
  final DateTime date;
  final double value;
  const MetricPoint({required this.date, required this.value});
}

class MetricSeries {
  final String label;
  final String unit;
  final List<MetricPoint> points;
  const MetricSeries({required this.label, required this.unit, required this.points});

  double get latest => points.isEmpty ? 0 : points.last.value;
  double get min => points.isEmpty ? 0 : points.map((p) => p.value).reduce((a, b) => a < b ? a : b);
  double get max => points.isEmpty ? 0 : points.map((p) => p.value).reduce((a, b) => a > b ? a : b);
}
