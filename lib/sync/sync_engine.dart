import 'dart:async';
import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:drift/drift.dart' hide Query;

import '../database/app_database.dart';
import 'outbox_service.dart';
import 'sync_constants.dart';

enum SyncPhase { idle, syncing, offline, error }

class SyncEngine {
  SyncEngine({
    required AppDatabase db,
    required OutboxService outbox,
    FirebaseFirestore? firestore,
    Connectivity? connectivity,
  }) : _db = db,
       _outbox = outbox,
       _providedFs = firestore,
       _connectivity = connectivity ?? Connectivity();

  final AppDatabase _db;
  final OutboxService _outbox;
  final FirebaseFirestore? _providedFs;
  final Connectivity _connectivity;
  FirebaseFirestore? _cachedFs;

  FirebaseFirestore get _fs =>
      _providedFs ?? (_cachedFs ??= FirebaseFirestore.instance);

  String? _userId;
  Timer? _debounce;
  bool _running = false;
  StreamSubscription<List<ConnectivityResult>>? _connSub;

  final _phaseController = StreamController<SyncPhase>.broadcast();
  Stream<SyncPhase> get phase => _phaseController.stream;
  SyncPhase _phase = SyncPhase.idle;
  SyncPhase get currentPhase => _phase;

  void start(String userId) {
    _userId = userId;
    _connSub?.cancel();
    _connSub = _connectivity.onConnectivityChanged.listen((results) {
      if (results.any((r) => r != ConnectivityResult.none)) {
        requestSync();
      } else {
        _setPhase(SyncPhase.offline);
      }
    });
    requestSync();
  }

  void stop() {
    _debounce?.cancel();
    _connSub?.cancel();
    _userId = null;
    _setPhase(SyncPhase.idle);
  }

  void requestSync() {
    if (_userId == null) return;
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 700), () {
      unawaited(syncNow());
    });
  }

  Future<void> syncNow() async {
    final uid = _userId;
    if (uid == null || _running) return;

    final results = await _connectivity.checkConnectivity();
    if (results.every((r) => r == ConnectivityResult.none)) {
      _setPhase(SyncPhase.offline);
      return;
    }

    _running = true;
    _setPhase(SyncPhase.syncing);
    try {
      await _push(uid);
      await _pull(uid);
      _setPhase(SyncPhase.idle);
    } catch (e) {
      _setPhase(SyncPhase.error);
      rethrow;
    } finally {
      _running = false;
    }
  }

  Future<void> _push(String uid) async {
    final pending = await _outbox.pending(uid);
    if (pending.isEmpty) return;

    const chunk = 400;
    for (var i = 0; i < pending.length; i += chunk) {
      final slice = pending.skip(i).take(chunk).toList();
      final batch = _fs.batch();
      final succeeded = <SyncOutboxRow>[];

      for (final item in slice) {
        try {
          final ref = _docRef(uid, item.entityType, item.entityId);
          final payload = Map<String, dynamic>.from(
            jsonDecode(item.payloadJson) as Map,
          );
          if (item.operation == SyncOps.delete) {
            batch.set(ref, payload, SetOptions(merge: true));
          } else {
            batch.set(ref, payload, SetOptions(merge: true));
          }
          succeeded.add(item);
        } catch (e) {
          await _outbox.markAttempt(item.id, e.toString());
        }
      }

      if (succeeded.isEmpty) continue;
      await batch.commit();
      for (final item in succeeded) {
        await _outbox.remove(item.id);
        await _markLocalSynced(uid, item.entityType, item.entityId);
      }
    }

    await _setMeta(uid, SyncMetaKeys.lastPushAt, DateTime.now().toUtc());
  }

  Future<void> _pull(String uid) async {
    final lastPulled = await _getMeta(uid, SyncMetaKeys.lastPulledAt);
    final since = lastPulled != null ? DateTime.tryParse(lastPulled) : null;
    var newest = since;

    for (final type in EntityTypes.all) {
      Query<Map<String, dynamic>> q = _collection(uid, type);
      if (since != null) {
        q = q.where('updatedAt', isGreaterThan: since.toIso8601String());
      }
      final snap = await q.limit(500).get();
      for (final doc in snap.docs) {
        final data = doc.data();
        final updatedAt = DateTime.tryParse(data['updatedAt'] as String? ?? '');
        if (updatedAt != null &&
            (newest == null || updatedAt.isAfter(newest))) {
          newest = updatedAt;
        }
        // remote wins: upsert local and drop outbox for this entity.
        await _applyRemote(uid, type, data);
        await _outbox.removeForEntity(
          userId: uid,
          entityType: type,
          entityId: data['id'] as String? ?? doc.id,
        );
      }
    }

    await _setMeta(
      uid,
      SyncMetaKeys.lastPulledAt,
      newest ?? DateTime.now().toUtc(),
    );
  }

  Future<void> _applyRemote(
    String uid,
    String type,
    Map<String, dynamic> data,
  ) async {
    final id = data['id'] as String?;
    if (id == null) return;
    final updatedAt =
        DateTime.tryParse(data['updatedAt'] as String? ?? '') ??
        DateTime.now().toUtc();
    final deletedAt = data['deletedAt'] != null
        ? DateTime.tryParse(data['deletedAt'] as String)
        : null;

    switch (type) {
      case EntityTypes.medications:
        await _db
            .into(_db.medications)
            .insertOnConflictUpdate(
              MedicationsCompanion.insert(
                id: id,
                userId: uid,
                name: data['name'] as String? ?? '',
                dose: data['dose'] as String? ?? '',
                condition: data['condition'] as String? ?? '',
                refills: (data['refills'] as num?)?.toInt() ?? 0,
                updatedAt: updatedAt,
                syncStatus: const Value(SyncStatuses.synced),
                deletedAt: Value(deletedAt),
              ),
            );
      case EntityTypes.reminders:
        await _db
            .into(_db.reminders)
            .insertOnConflictUpdate(
              RemindersCompanion.insert(
                id: id,
                userId: uid,
                medicationName: data['medicationName'] as String? ?? '',
                hour: (data['hour'] as num?)?.toInt() ?? 0,
                minute: (data['minute'] as num?)?.toInt() ?? 0,
                days: data['days'] as String? ?? '[]',
                enabled: Value(data['enabled'] as bool? ?? true),
                updatedAt: updatedAt,
                syncStatus: const Value(SyncStatuses.synced),
                deletedAt: Value(deletedAt),
              ),
            );
      case EntityTypes.journalEntries:
        await _db
            .into(_db.journalEntries)
            .insertOnConflictUpdate(
              JournalEntriesCompanion.insert(
                id: id,
                userId: uid,
                type: data['type'] as String? ?? '',
                date: data['date'] as String? ?? '',
                facility: data['facility'] as String? ?? '',
                title: data['title'] as String? ?? '',
                person: data['person'] as String? ?? '',
                note: data['note'] as String? ?? '',
                tags: data['tags'] as String? ?? '[]',
                iconCodePoint: (data['iconCodePoint'] as num?)?.toInt() ?? 0,
                updatedAt: updatedAt,
                syncStatus: const Value(SyncStatuses.synced),
                deletedAt: Value(deletedAt),
              ),
            );
      case EntityTypes.documents:
        await _db
            .into(_db.documents)
            .insertOnConflictUpdate(
              DocumentsCompanion.insert(
                id: id,
                userId: uid,
                iconCodePoint: (data['iconCodePoint'] as num?)?.toInt() ?? 0,
                name: data['name'] as String? ?? '',
                source: data['source'] as String? ?? '',
                ocrText: Value(data['ocrText'] as String?),
                storagePath: Value(data['storagePath'] as String?),
                downloadUrl: Value(data['downloadUrl'] as String?),
                mimeType: Value(data['mimeType'] as String?),
                sizeBytes: Value((data['sizeBytes'] as num?)?.toInt()),
                createdAt: Value(
                  DateTime.tryParse(data['createdAt'] as String? ?? ''),
                ),
                updatedAt: updatedAt,
                syncStatus: const Value(SyncStatuses.synced),
                deletedAt: Value(deletedAt),
              ),
            );
      case EntityTypes.caregivers:
        await _db
            .into(_db.caregivers)
            .insertOnConflictUpdate(
              CaregiversCompanion.insert(
                id: id,
                userId: uid,
                name: data['name'] as String? ?? '',
                relation: data['relation'] as String? ?? '',
                phone: data['phone'] as String? ?? '',
                role: data['role'] as String? ?? 'viewOnly',
                notificationsEnabled: Value(
                  data['notificationsEnabled'] as bool? ?? true,
                ),
                status: Value(data['status'] as String? ?? 'pending'),
                invitedAt: Value(
                  DateTime.tryParse(data['invitedAt'] as String? ?? ''),
                ),
                updatedAt: updatedAt,
                syncStatus: const Value(SyncStatuses.synced),
                deletedAt: Value(deletedAt),
              ),
            );
      case EntityTypes.profile:
        await _db
            .into(_db.userProfiles)
            .insertOnConflictUpdate(
              UserProfilesCompanion.insert(
                id: id,
                userId: uid,
                name: data['name'] as String? ?? '',
                initials: data['initials'] as String? ?? '',
                phone: Value(data['phone'] as String? ?? '—'),
                age: (data['age'] as num?)?.toInt() ?? 0,
                bloodType: data['bloodType'] as String? ?? '',
                height: data['height'] as String? ?? '',
                patientId: data['patientId'] as String? ?? '',
                hba1c: data['hba1c'] as String? ?? '',
                bpAvg: data['bpAvg'] as String? ?? '',
                weight: data['weight'] as String? ?? '',
                allergies: data['allergies'] as String? ?? '[]',
                emergencyName: data['emergencyName'] as String? ?? '',
                emergencyRelation: data['emergencyRelation'] as String? ?? '',
                emergencyPhone: data['emergencyPhone'] as String? ?? '',
                updatedAt: updatedAt,
                syncStatus: const Value(SyncStatuses.synced),
                deletedAt: Value(deletedAt),
              ),
            );
      case EntityTypes.metricPoints:
        await _db
            .into(_db.metricPoints)
            .insertOnConflictUpdate(
              MetricPointsCompanion.insert(
                id: id,
                userId: uid,
                seriesKey: data['seriesKey'] as String? ?? '',
                label: data['label'] as String? ?? '',
                unit: data['unit'] as String? ?? '',
                date:
                    DateTime.tryParse(data['date'] as String? ?? '') ??
                    updatedAt,
                value: (data['value'] as num?)?.toDouble() ?? 0,
                updatedAt: updatedAt,
                syncStatus: const Value(SyncStatuses.synced),
                deletedAt: Value(deletedAt),
              ),
            );
      case EntityTypes.shareTokens:
        await _db
            .into(_db.shareTokens)
            .insertOnConflictUpdate(
              ShareTokensCompanion.insert(
                id: id,
                userId: uid,
                token: data['token'] as String? ?? '',
                doctorName: data['doctorName'] as String? ?? '',
                expiresAt:
                    DateTime.tryParse(data['expiresAt'] as String? ?? '') ??
                    updatedAt,
                redeemed: Value(data['redeemed'] as bool? ?? false),
                redeemedAt: Value(
                  DateTime.tryParse(data['redeemedAt'] as String? ?? ''),
                ),
                updatedAt: updatedAt,
                syncStatus: const Value(SyncStatuses.synced),
                deletedAt: Value(deletedAt),
              ),
            );
      case EntityTypes.emergencyAccess:
        await _db
            .into(_db.emergencyAccessCodes)
            .insertOnConflictUpdate(
              EmergencyAccessCodesCompanion.insert(
                id: id,
                userId: uid,
                code: data['code'] as String? ?? '',
                expiresAt:
                    DateTime.tryParse(data['expiresAt'] as String? ?? '') ??
                    updatedAt,
                scope: data['scope'] as String? ?? 'summary',
                redeemed: Value(data['redeemed'] as bool? ?? false),
                redeemedAt: Value(
                  DateTime.tryParse(data['redeemedAt'] as String? ?? ''),
                ),
                updatedAt: updatedAt,
                syncStatus: const Value(SyncStatuses.synced),
                deletedAt: Value(deletedAt),
              ),
            );
    }
  }

  Future<void> _markLocalSynced(
    String uid,
    String type,
    String entityId,
  ) async {
    switch (type) {
      case EntityTypes.medications:
        await (_db.update(
          _db.medications,
        )..where((t) => t.id.equals(entityId) & t.userId.equals(uid))).write(
          const MedicationsCompanion(syncStatus: Value(SyncStatuses.synced)),
        );
      case EntityTypes.reminders:
        await (_db.update(
          _db.reminders,
        )..where((t) => t.id.equals(entityId) & t.userId.equals(uid))).write(
          const RemindersCompanion(syncStatus: Value(SyncStatuses.synced)),
        );
      case EntityTypes.journalEntries:
        await (_db.update(
          _db.journalEntries,
        )..where((t) => t.id.equals(entityId) & t.userId.equals(uid))).write(
          const JournalEntriesCompanion(syncStatus: Value(SyncStatuses.synced)),
        );
      case EntityTypes.documents:
        await (_db.update(
          _db.documents,
        )..where((t) => t.id.equals(entityId) & t.userId.equals(uid))).write(
          const DocumentsCompanion(syncStatus: Value(SyncStatuses.synced)),
        );
      case EntityTypes.caregivers:
        await (_db.update(
          _db.caregivers,
        )..where((t) => t.id.equals(entityId) & t.userId.equals(uid))).write(
          const CaregiversCompanion(syncStatus: Value(SyncStatuses.synced)),
        );
      case EntityTypes.profile:
        await (_db.update(
          _db.userProfiles,
        )..where((t) => t.id.equals(entityId) & t.userId.equals(uid))).write(
          const UserProfilesCompanion(syncStatus: Value(SyncStatuses.synced)),
        );
      case EntityTypes.metricPoints:
        await (_db.update(
          _db.metricPoints,
        )..where((t) => t.id.equals(entityId) & t.userId.equals(uid))).write(
          const MetricPointsCompanion(syncStatus: Value(SyncStatuses.synced)),
        );
      case EntityTypes.shareTokens:
        await (_db.update(
          _db.shareTokens,
        )..where((t) => t.id.equals(entityId) & t.userId.equals(uid))).write(
          const ShareTokensCompanion(syncStatus: Value(SyncStatuses.synced)),
        );
      case EntityTypes.emergencyAccess:
        await (_db.update(
          _db.emergencyAccessCodes,
        )..where((t) => t.id.equals(entityId) & t.userId.equals(uid))).write(
          const EmergencyAccessCodesCompanion(
            syncStatus: Value(SyncStatuses.synced),
          ),
        );
    }
  }

  CollectionReference<Map<String, dynamic>> _collection(
    String uid,
    String type,
  ) {
    // profile stored as collection too (doc id = profile-{uid})
    return _fs.collection('users').doc(uid).collection(type);
  }

  DocumentReference<Map<String, dynamic>> _docRef(
    String uid,
    String type,
    String id,
  ) {
    return _collection(uid, type).doc(id);
  }

  Future<String?> _getMeta(String uid, String key) async {
    final row =
        await (_db.select(_db.syncMeta)
              ..where((t) => t.userId.equals(uid) & t.key.equals(key)))
            .getSingleOrNull();
    return row?.value;
  }

  Future<void> _setMeta(String uid, String key, DateTime value) async {
    await _db
        .into(_db.syncMeta)
        .insertOnConflictUpdate(
          SyncMetaCompanion.insert(
            key: key,
            userId: uid,
            value: value.toIso8601String(),
          ),
        );
  }

  void _setPhase(SyncPhase p) {
    _phase = p;
    _phaseController.add(p);
  }

  Future<void> dispose() async {
    stop();
    await _phaseController.close();
  }
}
