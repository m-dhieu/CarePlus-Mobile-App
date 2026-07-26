import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

import '../database/app_database.dart';

class OutboxService {
  OutboxService(this._db);
  final AppDatabase _db;
  static const _uuid = Uuid();

  Future<void> enqueue({
    required String userId,
    required String entityType,
    required String entityId,
    required String operation,
    required Map<String, dynamic> payload,
  }) async {
    // drop older pending ops for same entity to keep latest
    await (_db.delete(_db.syncOutbox)..where(
          (t) =>
              t.userId.equals(userId) &
              t.entityType.equals(entityType) &
              t.entityId.equals(entityId),
        ))
        .go();

    await _db
        .into(_db.syncOutbox)
        .insert(
          SyncOutboxCompanion.insert(
            id: _uuid.v4(),
            userId: userId,
            entityType: entityType,
            entityId: entityId,
            operation: operation,
            payloadJson: jsonEncode(payload),
            createdAt: DateTime.now().toUtc(),
          ),
        );
  }

  Future<List<SyncOutboxRow>> pending(String userId) {
    return (_db.select(_db.syncOutbox)
          ..where((t) => t.userId.equals(userId))
          ..orderBy([(t) => OrderingTerm.asc(t.createdAt)]))
        .get();
  }

  Future<void> remove(String id) async {
    await (_db.delete(_db.syncOutbox)..where((t) => t.id.equals(id))).go();
  }

  Future<void> removeForEntity({
    required String userId,
    required String entityType,
    required String entityId,
  }) async {
    await (_db.delete(_db.syncOutbox)..where(
          (t) =>
              t.userId.equals(userId) &
              t.entityType.equals(entityType) &
              t.entityId.equals(entityId),
        ))
        .go();
  }

  Future<void> markAttempt(String id, String error) async {
    final row = await (_db.select(
      _db.syncOutbox,
    )..where((t) => t.id.equals(id))).getSingleOrNull();
    if (row == null) return;
    await (_db.update(_db.syncOutbox)..where((t) => t.id.equals(id))).write(
      SyncOutboxCompanion(
        attempts: Value(row.attempts + 1),
        lastError: Value(error),
      ),
    );
  }
}
