import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../database/app_database.dart';
import '../models/models.dart';
import '../repositories/care_repository.dart';
import '../repositories/seed_service.dart';
import '../services/auth_service.dart';
import '../sync/outbox_service.dart';
import '../sync/sync_engine.dart';

// infrastructure

final sharedPrefsProvider = FutureProvider<SharedPreferences>(
  (_) => SharedPreferences.getInstance(),
);

final databaseProvider = Provider<AppDatabase>((ref) {
  final db = AppDatabase();
  ref.onDispose(db.close);
  return db;
});

final authServiceProvider = Provider<AuthService>((_) => AuthService());

final outboxServiceProvider = Provider<OutboxService>((ref) {
  return OutboxService(ref.watch(databaseProvider));
});

final syncEngineProvider = Provider<SyncEngine>((ref) {
  final engine = SyncEngine(
    db: ref.watch(databaseProvider),
    outbox: ref.watch(outboxServiceProvider),
  );
  ref.onDispose(engine.dispose);
  return engine;
});

final seedServiceProvider = Provider<SeedService>((ref) {
  return SeedService(
    ref.watch(databaseProvider),
    ref.watch(outboxServiceProvider),
  );
});

final careRepositoryProvider = Provider<CareRepository>((ref) {
  final engine = ref.watch(syncEngineProvider);
  return CareRepository(
    ref.watch(databaseProvider),
    ref.watch(outboxServiceProvider),
    onDirty: engine.requestSync,
  );
});

// ── Auth ──────────────────────────────────────────────────────────────────────

final authStateProvider = StreamProvider<User?>((ref) {
  return ref.watch(authServiceProvider).authStateChanges;
});

final currentUserIdProvider = Provider<String?>((ref) {
  return ref.watch(authStateProvider).asData?.value?.uid;
});

class AuthNotifier extends Notifier<bool> {
  @override
  bool build() {
    final asyncUser = ref.watch(authStateProvider);
    return asyncUser.asData?.value != null;
  }

  Future<void> login(String email, String password) async {
    await ref
        .read(authServiceProvider)
        .signIn(email: email.trim(), password: password);
  }

  Future<void> signUp(String email, String password) async {
    await ref
        .read(authServiceProvider)
        .signUp(email: email.trim(), password: password);
  }

  Future<void> register({
    required String email,
    required String password,
    required String fullName,
    required String phone,
  }) async {
    final trimmedName = fullName.trim();
    final cred = await ref.read(authServiceProvider).signUp(
          email: email.trim(),
          password: password,
          displayName: trimmedName,
        );
    await ref.read(careRepositoryProvider).upsertProfile(
          cred.user!.uid,
          name: trimmedName.isEmpty ? email.split('@').first : trimmedName,
          phone: phone.trim(),
          email: email.trim(),
        );
  }

  Future<void> sendPasswordReset(String email) async {
    await ref.read(authServiceProvider).sendPasswordResetEmail(email);
  }

  Future<void> signInWithGoogle() async {
    await ref.read(authServiceProvider).signInWithGoogle();
  }

  Future<void> signInWithApple() async {
    await ref.read(authServiceProvider).signInWithApple();
  }

  Future<void> logout() async {
    ref.read(syncEngineProvider).stop();
    await ref.read(authServiceProvider).signOut();
  }
}

final authProvider = NotifierProvider<AuthNotifier, bool>(AuthNotifier.new);

// Starts background Firestore sync when a Firebase user is present.
// UI reads Drift only; SyncEngine push/pull updates Drift off the main path.
final sessionBootstrapProvider = FutureProvider<void>((ref) async {
  final uid = ref.watch(currentUserIdProvider);
  if (uid == null) {
    ref.read(syncEngineProvider).stop();
    return;
  }
  final user = ref.read(authServiceProvider).currentUser;
  await ref.read(careRepositoryProvider).ensureProfile(
        uid,
        displayName: user?.displayName,
        email: user?.email,
      );
  await ref.read(seedServiceProvider).seedIfNeeded(uid);
  ref.read(syncEngineProvider).start(uid);
});

final syncPhaseProvider = StreamProvider<SyncPhase>((ref) {
  return ref.watch(syncEngineProvider).phase;
});

// ── Onboarding ────────────────────────────────────────────────────────────────

class OnboardingNotifier extends Notifier<bool> {
  @override
  bool build() {
    Future.microtask(load);
    return false;
  }

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

final onboardingProvider = NotifierProvider<OnboardingNotifier, bool>(
  OnboardingNotifier.new,
);

final onboardingPages = [
  const OnboardingPage(
    icon: Icons.health_and_safety,
    title: 'Your health, unified',
    subtitle: 'All your records, medications, and visits in one secure place.',
  ),
  const OnboardingPage(
    icon: Icons.share,
    title: 'Share with your care team',
    subtitle:
        'Instantly share your full history with any doctor — encrypted end-to-end.',
  ),
  const OnboardingPage(
    icon: Icons.notifications_active,
    title: 'Never miss a dose',
    subtitle:
        'Smart reminders keep you on track with your medication schedule.',
  ),
  const OnboardingPage(
    icon: Icons.people,
    title: 'Involve your caregivers',
    subtitle: 'Give family members controlled access to support your care.',
  ),
];

// helpers for Drift-backed notifiers

void _listenList<T>(
  Ref ref,
  Stream<List<T>> Function(String uid) streamFn,
  void Function(List<T>) setState,
) {
  final uid = ref.watch(currentUserIdProvider);
  if (uid == null) return;
  ref.watch(sessionBootstrapProvider);
  final sub = streamFn(uid).listen(setState);
  ref.onDispose(sub.cancel);
}

// ── User Profile ──────────────────────────────────────────────────────────────

UserProfile _emptyProfile([String name = 'User']) {
  final parts =
      name.trim().split(RegExp(r'\s+')).where((p) => p.isNotEmpty).toList();
  final initials = parts.isEmpty
      ? 'U'
      : parts.length == 1
          ? parts.first.substring(0, parts.first.length >= 2 ? 2 : 1).toUpperCase()
          : '${parts.first[0]}${parts.last[0]}'.toUpperCase();
  return UserProfile(
    name: name,
    initials: initials,
    phone: '—',
    age: 0,
    bloodType: '—',
    height: '—',
    patientId: '—',
    hba1c: '—',
    bpAvg: '—',
    weight: '—',
    allergies: const [],
    emergencyContact: const EmergencyContact(
      name: '—',
      relation: '—',
      phone: '—',
    ),
  );
}

class UserProfileNotifier extends Notifier<UserProfile> {
  @override
  UserProfile build() {
    final uid = ref.watch(currentUserIdProvider);
    if (uid == null) return _emptyProfile();
    ref.watch(sessionBootstrapProvider);
    final sub = ref.read(careRepositoryProvider).watchProfile(uid).listen((p) {
      if (p != null) state = p;
    });
    ref.onDispose(sub.cancel);
    final user = ref.read(authServiceProvider).currentUser;
    final hint = user?.displayName?.trim().isNotEmpty == true
        ? user!.displayName!.trim()
        : (user?.email?.split('@').first ?? 'User');
    return _emptyProfile(hint);
  }
}

final userProfileProvider = NotifierProvider<UserProfileNotifier, UserProfile>(
  UserProfileNotifier.new,
);

class UserProfileEditorNotifier extends Notifier<void> {
  @override
  void build() {}

  Future<void> save(
    UserProfile profile, {
    required String name,
    required String phone,
    required int age,
    required String bloodType,
    required String height,
    required String hba1c,
    required String bpAvg,
    required String weight,
    required List<String> allergies,
    required String emergencyName,
    required String emergencyRelation,
    required String emergencyPhone,
  }) async {
    final uid = ref.read(currentUserIdProvider);
    if (uid == null) return;
    await ref.read(careRepositoryProvider).upsertProfile(
          uid,
          name: name,
          phone: phone,
          age: age,
          bloodType: bloodType,
          height: height,
          hba1c: hba1c,
          bpAvg: bpAvg,
          weight: weight,
          allergies: allergies,
          emergencyContact: EmergencyContact(
            name: emergencyName,
            relation: emergencyRelation,
            phone: emergencyPhone,
          ),
        );
    final authUser = ref.read(authServiceProvider).currentUser;
    if (authUser != null &&
        name.trim().isNotEmpty &&
        authUser.displayName != name.trim()) {
      await ref.read(authServiceProvider).updateDisplayName(name.trim());
    }
  }
}

final userProfileEditorProvider =
    NotifierProvider<UserProfileEditorNotifier, void>(
      UserProfileEditorNotifier.new,
    );

// ── Medications ───────────────────────────────────────────────────────────────

class MedicationsNotifier extends Notifier<List<Medication>> {
  @override
  List<Medication> build() {
    _listenList(
      ref,
      (uid) => ref.read(careRepositoryProvider).watchMedications(uid),
      (v) => state = v,
    );
    return const [];
  }

  Future<void> add(Medication med) async {
    final uid = ref.read(currentUserIdProvider);
    if (uid == null) return;
    await ref.read(careRepositoryProvider).addMedication(uid, med);
  }

  Future<void> requestRefill(String id) async {
    final uid = ref.read(currentUserIdProvider);
    if (uid == null) return;
    await ref.read(careRepositoryProvider).requestRefill(uid, id);
  }
}

final medicationsProvider =
    NotifierProvider<MedicationsNotifier, List<Medication>>(
      MedicationsNotifier.new,
    );

// ── Reminders ─────────────────────────────────────────────────────────────────

class RemindersNotifier extends Notifier<List<Reminder>> {
  @override
  List<Reminder> build() {
    _listenList(
      ref,
      (uid) => ref.read(careRepositoryProvider).watchReminders(uid),
      (v) => state = v,
    );
    return const [];
  }

  Future<void> toggle(String id) async {
    final uid = ref.read(currentUserIdProvider);
    if (uid == null) return;
    await ref.read(careRepositoryProvider).toggleReminder(uid, id);
  }

  Future<void> add(Reminder reminder) async {
    final uid = ref.read(currentUserIdProvider);
    if (uid == null) return;
    await ref.read(careRepositoryProvider).addReminder(uid, reminder);
  }

  Future<void> remove(String id) async {
    final uid = ref.read(currentUserIdProvider);
    if (uid == null) return;
    await ref.read(careRepositoryProvider).removeReminder(uid, id);
  }

  Future<void> updateTime(String id, TimeOfDay time) async {
    final uid = ref.read(currentUserIdProvider);
    if (uid == null) return;
    await ref.read(careRepositoryProvider).updateReminderTime(uid, id, time);
  }
}

final remindersProvider = NotifierProvider<RemindersNotifier, List<Reminder>>(
  RemindersNotifier.new,
);

// ── Journal ───────────────────────────────────────────────────────────────────

class JournalNotifier extends Notifier<List<JournalEntry>> {
  @override
  List<JournalEntry> build() {
    _listenList(
      ref,
      (uid) => ref.read(careRepositoryProvider).watchJournal(uid),
      (v) => state = v,
    );
    return const [];
  }

  Future<void> add(JournalEntry entry) async {
    final uid = ref.read(currentUserIdProvider);
    if (uid == null) return;
    await ref.read(careRepositoryProvider).addJournal(uid, entry);
  }
}

final journalProvider = NotifierProvider<JournalNotifier, List<JournalEntry>>(
  JournalNotifier.new,
);

class JournalTabNotifier extends Notifier<String> {
  @override
  String build() => 'All';
  void set(String tab) => state = tab;
}

final journalTabProvider = NotifierProvider<JournalTabNotifier, String>(
  JournalTabNotifier.new,
);

// ── Records / Documents ───────────────────────────────────────────────────────

class DocumentsNotifier extends Notifier<List<MedicalDocument>> {
  @override
  List<MedicalDocument> build() {
    _listenList(
      ref,
      (uid) => ref.read(careRepositoryProvider).watchDocuments(uid),
      (v) => state = v,
    );
    return const [];
  }

  Future<void> addOcrDocument(MedicalDocument doc) async {
    final uid = ref.read(currentUserIdProvider);
    if (uid == null) return;
    await ref.read(careRepositoryProvider).addDocument(uid, doc);
  }

  Future<void> updateOcr(String id, String ocrText) async {
    final uid = ref.read(currentUserIdProvider);
    if (uid == null) return;
    await ref.read(careRepositoryProvider).updateDocumentOcr(uid, id, ocrText);
  }
}

final documentsProvider =
    NotifierProvider<DocumentsNotifier, List<MedicalDocument>>(
      DocumentsNotifier.new,
    );

// ── Record Share Tokens ───────────────────────────────────────────────────────

class ShareTokensNotifier extends Notifier<List<RecordShareToken>> {
  @override
  List<RecordShareToken> build() {
    _listenList(
      ref,
      (uid) => ref.read(careRepositoryProvider).watchShareTokens(uid),
      (v) => state = v,
    );
    return const [];
  }

  Future<RecordShareToken?> generate(String doctorName) async {
    final uid = ref.read(currentUserIdProvider);
    if (uid == null) return null;
    return ref.read(careRepositoryProvider).generateShareToken(uid, doctorName);
  }

  Future<void> revoke(String token) async {
    final uid = ref.read(currentUserIdProvider);
    if (uid == null) return;
    await ref.read(careRepositoryProvider).revokeShareToken(uid, token);
  }
}

final shareTokensProvider =
    NotifierProvider<ShareTokensNotifier, List<RecordShareToken>>(
      ShareTokensNotifier.new,
    );

// ── Emergency Access ──────────────────────────────────────────────────────────

class EmergencyAccessNotifier extends Notifier<EmergencyAccessCode?> {
  @override
  EmergencyAccessCode? build() {
    final uid = ref.watch(currentUserIdProvider);
    if (uid == null) return null;
    ref.watch(sessionBootstrapProvider);
    final sub = ref
        .read(careRepositoryProvider)
        .watchEmergency(uid)
        .listen((v) => state = v);
    ref.onDispose(sub.cancel);
    return null;
  }

  Future<EmergencyAccessCode?> generate(String scope) async {
    final uid = ref.read(currentUserIdProvider);
    if (uid == null) return null;
    return ref.read(careRepositoryProvider).generateEmergency(uid, scope);
  }

  Future<void> revoke() async {
    final uid = ref.read(currentUserIdProvider);
    if (uid == null) return;
    await ref.read(careRepositoryProvider).revokeEmergency(uid);
  }
}

final emergencyAccessProvider =
    NotifierProvider<EmergencyAccessNotifier, EmergencyAccessCode?>(
      EmergencyAccessNotifier.new,
    );

// ── OCR Import ────────────────────────────────────────────────────────────────

class OcrNotifier extends Notifier<String?> {
  @override
  String? build() => null;

  void setResult(String text) => state = text;
  void clear() => state = null;

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
  List<Caregiver> build() {
    _listenList(
      ref,
      (uid) => ref.read(careRepositoryProvider).watchCaregivers(uid),
      (v) => state = v,
    );
    return const [];
  }

  Future<void> add(Caregiver c) async {
    final uid = ref.read(currentUserIdProvider);
    if (uid == null) return;
    await ref.read(careRepositoryProvider).addCaregiver(uid, c);
  }

  Future<void> remove(String id) async {
    final uid = ref.read(currentUserIdProvider);
    if (uid == null) return;
    await ref.read(careRepositoryProvider).removeCaregiver(uid, id);
  }

  Future<void> updateRole(String id, CaregiverRole role) async {
    final uid = ref.read(currentUserIdProvider);
    if (uid == null) return;
    await ref.read(careRepositoryProvider).updateCaregiverRole(uid, id, role);
  }

  Future<void> toggleNotifications(String id) async {
    final uid = ref.read(currentUserIdProvider);
    if (uid == null) return;
    await ref
        .read(careRepositoryProvider)
        .toggleCaregiverNotifications(uid, id);
  }

  Future<void> updateStatus(String id, String status) async {
    final uid = ref.read(currentUserIdProvider);
    if (uid == null) return;
    await ref.read(careRepositoryProvider).updateCaregiverStatus(uid, id, status);
  }
}

final caregiversProvider =
    NotifierProvider<CaregiversNotifier, List<Caregiver>>(
      CaregiversNotifier.new,
    );

// ── Metrics ───────────────────────────────────────────────────────────────────

class MetricsNotifier extends Notifier<Map<String, MetricSeries>> {
  @override
  Map<String, MetricSeries> build() {
    final uid = ref.watch(currentUserIdProvider);
    if (uid == null) return {};
    ref.watch(sessionBootstrapProvider);
    final sub = ref
        .read(careRepositoryProvider)
        .watchMetrics(uid)
        .listen((v) => state = v);
    ref.onDispose(sub.cancel);
    return {};
  }

  Future<void> addPoint({
    required String seriesKey,
    required String label,
    required String unit,
    required double value,
    DateTime? date,
  }) async {
    final uid = ref.read(currentUserIdProvider);
    if (uid == null) return;
    await ref.read(careRepositoryProvider).addMetricPoint(
          uid,
          seriesKey: seriesKey,
          label: label,
          unit: unit,
          value: value,
          date: date ?? DateTime.now(),
        );
  }
}

final metricsProvider =
    NotifierProvider<MetricsNotifier, Map<String, MetricSeries>>(
      MetricsNotifier.new,
    );

// ── Toast ─────────────────────────────────────────────────────────────────────

class ToastNotifier extends Notifier<String?> {
  @override
  String? build() => null;

  void show(String msg) {
    state = msg;
    Future.delayed(const Duration(milliseconds: 2400), () {
      if (state == msg) state = null;
    });
  }

  /// Toast + greppable `[Care+][TODO]` log for stubs not shipped yet.
  void showUnfinished(
    String feature, {
    String? detail,
    String? userMessage,
  }) {
    final note = detail == null ? feature : '$feature — $detail';
    debugPrint('[Care+][TODO] $note');
    show(userMessage ?? '$feature is not available yet');
  }
}

final toastProvider = NotifierProvider<ToastNotifier, String?>(
  ToastNotifier.new,
);

// ── Navigation ────────────────────────────────────────────────────────────────

class ScreenNotifier extends Notifier<String> {
  @override
  String build() => 'home';
  void go(String screen) => state = screen;
}

final screenProvider = NotifierProvider<ScreenNotifier, String>(
  ScreenNotifier.new,
);
