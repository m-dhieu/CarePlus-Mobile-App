import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/models.dart';

// ── Shared Preferences ────────────────────────────────────────────────────────

final sharedPrefsProvider = FutureProvider<SharedPreferences>(
  (_) => SharedPreferences.getInstance(),
);

// ── Auth ──────────────────────────────────────────────────────────────────────

class AuthNotifier extends Notifier<bool> {
  @override
  bool build() => false;

  void login() => state = true;
  void logout() => state = false;
}

final authProvider = NotifierProvider<AuthNotifier, bool>(AuthNotifier.new);

// ── Onboarding ────────────────────────────────────────────────────────────────

class OnboardingNotifier extends Notifier<bool> {
  @override
  bool build() => false; // false = not completed

  Future<void> complete() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('onboarding_done', true);
    state = true;
  }

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    state = prefs.getBool('onboarding_done') ?? false;
  }
}

final onboardingProvider = NotifierProvider<OnboardingNotifier, bool>(OnboardingNotifier.new);

final onboardingPages = [
  const OnboardingPage(
    icon: Icons.health_and_safety,
    title: 'Your health, unified',
    subtitle: 'All your records, medications, and visits in one secure place.',
  ),
  const OnboardingPage(
    icon: Icons.share,
    title: 'Share with your care team',
    subtitle: 'Instantly share your full history with any doctor — encrypted end-to-end.',
  ),
  const OnboardingPage(
    icon: Icons.notifications_active,
    title: 'Never miss a dose',
    subtitle: 'Smart reminders keep you on track with your medication schedule.',
  ),
  const OnboardingPage(
    icon: Icons.people,
    title: 'Involve your caregivers',
    subtitle: 'Give family members controlled access to support your care.',
  ),
];

// ── User Profile ──────────────────────────────────────────────────────────────

final userProfileProvider = Provider<UserProfile>((_) => UserProfile(
  name: 'Arnold Mugabo',
  initials: 'AM',
  age: 42,
  bloodType: 'O+',
  height: '174 cm',
  patientId: 'VTL-2026-08124',
  hba1c: '6.8%',
  bpAvg: '124/82',
  weight: '78 kg',
  allergies: const ['Penicillin', 'Sulfa drugs', 'Peanuts'],
  emergencyContact: const EmergencyContact(
    name: 'Grace Mugisha',
    relation: 'Spouse',
    phone: '+250 788 832 123',
  ),
));

// ── Medications ───────────────────────────────────────────────────────────────

class MedicationsNotifier extends Notifier<List<Medication>> {
  @override
  List<Medication> build() => [
    Medication(id: '1', name: 'Metformin',    dose: '500 mg',  condition: 'Type 2 Diabetes', refills: 2),
    Medication(id: '2', name: 'Lisinopril',   dose: '10 mg',   condition: 'Hypertension',    refills: 4),
    Medication(id: '3', name: 'Atorvastatin', dose: '20 mg',   condition: 'Cholesterol',     refills: 1),
    Medication(id: '4', name: 'Vitamin D3',   dose: '1000 IU', condition: 'Supplement',      refills: 6),
  ];

  void requestRefill(String id) {
    state = [
      for (final m in state)
        if (m.id == id) Medication(id: m.id, name: m.name, dose: m.dose, condition: m.condition, refills: m.refills + 1)
        else m,
    ];
  }
}

final medicationsProvider = NotifierProvider<MedicationsNotifier, List<Medication>>(MedicationsNotifier.new);

// ── Reminders ─────────────────────────────────────────────────────────────────

class RemindersNotifier extends Notifier<List<Reminder>> {
  @override
  List<Reminder> build() => [
    Reminder(id: '1', medicationName: 'Metformin',    time: const TimeOfDay(hour: 8,  minute: 0),  days: [true,true,true,true,true,true,true]),
    Reminder(id: '2', medicationName: 'Lisinopril',   time: const TimeOfDay(hour: 13, minute: 30), days: [true,true,true,true,true,false,false]),
    Reminder(id: '3', medicationName: 'Atorvastatin', time: const TimeOfDay(hour: 21, minute: 30), days: [true,true,true,true,true,true,true]),
  ];

  void toggle(String id) {
    state = [
      for (final r in state)
        if (r.id == id) Reminder(id: r.id, medicationName: r.medicationName, time: r.time, days: r.days, enabled: !r.enabled)
        else r,
    ];
  }

  void add(Reminder reminder) => state = [...state, reminder];

  void remove(String id) => state = state.where((r) => r.id != id).toList();

  void updateTime(String id, TimeOfDay time) {
    state = [
      for (final r in state)
        if (r.id == id) Reminder(id: r.id, medicationName: r.medicationName, time: time, days: r.days, enabled: r.enabled)
        else r,
    ];
  }
}

final remindersProvider = NotifierProvider<RemindersNotifier, List<Reminder>>(RemindersNotifier.new);

// ── Journal ───────────────────────────────────────────────────────────────────

class JournalNotifier extends Notifier<List<JournalEntry>> {
  @override
  List<JournalEntry> build() => [
    JournalEntry(id: '1', type: 'Visit',        date: '08 JUN', facility: 'Kigali University Hospital', title: 'Routine endocrinology check-up',   person: 'Dr. Amara Diallo', note: 'HbA1c improved to 6.8%. Continue current regimen.',          tags: ['Diabetes', 'Follow-up'], icon: Icons.medical_services),
    JournalEntry(id: '2', type: 'Lab',          date: '29 MAY', facility: 'Central Pathology',          title: 'Lipid panel & HbA1c',              person: 'Lab · Central Pathology', note: 'LDL 102 mg/dl, HDL 48, HbA1c 6.8%.',                   tags: ['Lab result'],            icon: Icons.science),
    JournalEntry(id: '3', type: 'Prescription', date: '14 MAY', facility: "St. Mary's Medical Center",  title: 'Atorvastatin 20mg added',          person: 'Dr. Henrik Vos',   note: 'Begin once-daily evening dose.',                             tags: ['New med'],               icon: Icons.medication),
    JournalEntry(id: '4', type: 'Procedure',    date: '02 APR', facility: 'Riverside Clinic',           title: 'Ophthalmology screening – retina', person: 'Dr. Lin Wei',      note: 'No diabetic retinopathy detected.',                          tags: ['Screening', 'Annual'],   icon: Icons.monitor_heart),
    JournalEntry(id: '5', type: 'Visit',        date: '18 MAR', facility: "St. Mary's Medical Center",  title: 'Cardiology consultation',          person: 'Dr. Henrik Vos',   note: 'Blood pressure trending high. Adjusted Lisinopril to 10mg.', tags: ['New med'],               icon: Icons.medical_services),
  ];

  void add(JournalEntry entry) => state = [entry, ...state];
}

final journalProvider = NotifierProvider<JournalNotifier, List<JournalEntry>>(JournalNotifier.new);

class JournalTabNotifier extends Notifier<String> {
  @override
  String build() => 'All';
  void set(String tab) => state = tab;
}

final journalTabProvider = NotifierProvider<JournalTabNotifier, String>(JournalTabNotifier.new);

// ── Records / Documents ───────────────────────────────────────────────────────

class DocumentsNotifier extends Notifier<List<MedicalDocument>> {
  @override
  List<MedicalDocument> build() => [
    MedicalDocument(id: '1', icon: Icons.science,     name: 'Hb1c lab results',            source: 'Central Pathology · 29 May 2026'),
    MedicalDocument(id: '2', icon: Icons.description, name: 'Cardiology consultation note', source: 'Dr. Henrik Vos · 18 Mar 2026'),
    MedicalDocument(id: '3', icon: Icons.image,       name: 'Retina scan – left eye',       source: 'Riverside Clinic · 2 Apr 2026'),
    MedicalDocument(id: '4', icon: Icons.description, name: 'Discharge summary',            source: 'Kigali University Hospital · 11 Jan 2026'),
  ];

  void addOcrDocument(MedicalDocument doc) => state = [doc, ...state];

  void updateOcr(String id, String ocrText) {
    state = [for (final d in state) if (d.id == id) d.copyWith(ocrText: ocrText) else d];
  }
}

final documentsProvider = NotifierProvider<DocumentsNotifier, List<MedicalDocument>>(DocumentsNotifier.new);

// ── Record Share Tokens ───────────────────────────────────────────────────────

class ShareTokensNotifier extends Notifier<List<RecordShareToken>> {
  @override
  List<RecordShareToken> build() => [];

  RecordShareToken generate(String doctorName) {
    final token = RecordShareToken(
      token: 'CPX-${DateTime.now().millisecondsSinceEpoch.toRadixString(36).toUpperCase()}',
      doctorName: doctorName,
      expiresAt: DateTime.now().add(const Duration(hours: 24)),
    );
    state = [token, ...state];
    return token;
  }

  void revoke(String token) => state = state.where((t) => t.token != token).toList();
}

final shareTokensProvider = NotifierProvider<ShareTokensNotifier, List<RecordShareToken>>(ShareTokensNotifier.new);

// ── Emergency Access ──────────────────────────────────────────────────────────

class EmergencyAccessNotifier extends Notifier<EmergencyAccessCode?> {
  @override
  EmergencyAccessCode? build() => null;

  EmergencyAccessCode generate(String scope) {
    final code = EmergencyAccessCode(
      code: (100000 + DateTime.now().millisecondsSinceEpoch % 900000).toString(),
      expiresAt: DateTime.now().add(const Duration(minutes: 30)),
      scope: scope,
    );
    state = code;
    return code;
  }

  void revoke() => state = null;
}

final emergencyAccessProvider = NotifierProvider<EmergencyAccessNotifier, EmergencyAccessCode?>(EmergencyAccessNotifier.new);

// ── OCR Import ────────────────────────────────────────────────────────────────

class OcrNotifier extends Notifier<String?> {
  @override
  String? build() => null; // holds last extracted text

  void setResult(String text) => state = text;
  void clear() => state = null;

  // Simulates OCR processing (replace with real ML Kit / Tesseract call)
  Future<String> processImage(String imagePath) async {
    await Future.delayed(const Duration(seconds: 2));
    const fakeResult =
        'HbA1c: 6.8%\nFasting Glucose: 119 mg/dL\nLDL Cholesterol: 102 mg/dL\n'
        'HDL Cholesterol: 48 mg/dL\nTriglycerides: 145 mg/dL\nDate: 29 May 2026';
    state = fakeResult;
    return fakeResult;
  }
}

final ocrProvider = NotifierProvider<OcrNotifier, String?>(OcrNotifier.new);

// ── Caregivers ────────────────────────────────────────────────────────────────

class CaregiversNotifier extends Notifier<List<Caregiver>> {
  @override
  List<Caregiver> build() => [
    Caregiver(id: '1', name: 'Grace Mugisha', relation: 'Spouse',  phone: '+250 788 832 123', role: CaregiverRole.fullAccess),
    Caregiver(id: '2', name: 'Eric Mugabo',   relation: 'Brother', phone: '+250 788 111 222', role: CaregiverRole.viewOnly),
  ];

  void add(Caregiver c) => state = [...state, c];
  void remove(String id) => state = state.where((c) => c.id != id).toList();

  void updateRole(String id, CaregiverRole role) {
    state = [for (final c in state) if (c.id == id) c.copyWith(role: role) else c];
  }

  void toggleNotifications(String id) {
    state = [
      for (final c in state)
        if (c.id == id) c.copyWith(notificationsEnabled: !c.notificationsEnabled) else c,
    ];
  }
}

final caregiversProvider = NotifierProvider<CaregiversNotifier, List<Caregiver>>(CaregiversNotifier.new);

// ── Metrics ───────────────────────────────────────────────────────────────────

final metricsProvider = Provider<Map<String, MetricSeries>>((_) {
  final now = DateTime.now();
  List<MetricPoint> pts(List<double> vals) => List.generate(
        vals.length,
        (i) => MetricPoint(date: now.subtract(Duration(days: (vals.length - 1 - i) * 7)), value: vals[i]),
      );

  return {
    'glucose': MetricSeries(label: 'Blood Glucose', unit: 'mg/dL', points: pts([132, 128, 125, 121, 119, 117, 119])),
    'bp_sys':  MetricSeries(label: 'Systolic BP',   unit: 'mmHg',  points: pts([138, 135, 130, 128, 126, 124, 125])),
    'bp_dia':  MetricSeries(label: 'Diastolic BP',  unit: 'mmHg',  points: pts([90, 88, 86, 84, 83, 82, 82])),
    'hr':      MetricSeries(label: 'Heart Rate',    unit: 'bpm',   points: pts([78, 76, 75, 74, 73, 72, 72])),
    'weight':  MetricSeries(label: 'Weight',        unit: 'kg',    points: pts([81, 80.5, 80, 79.5, 79, 78.5, 78])),
    'hba1c':   MetricSeries(label: 'HbA1c',         unit: '%',     points: pts([7.4, 7.2, 7.1, 7.0, 6.9, 6.8, 6.8])),
  };
});

// ── Toast ─────────────────────────────────────────────────────────────────────

class ToastNotifier extends Notifier<String?> {
  @override
  String? build() => null;

  void show(String msg) {
    state = msg;
    Future.delayed(const Duration(milliseconds: 2400), () => state = null);
  }
}

final toastProvider = NotifierProvider<ToastNotifier, String?>(ToastNotifier.new);

// ── Navigation ────────────────────────────────────────────────────────────────

class ScreenNotifier extends Notifier<String> {
  @override
  String build() => 'home';
  void go(String screen) => state = screen;
}

final screenProvider = NotifierProvider<ScreenNotifier, String>(ScreenNotifier.new);
