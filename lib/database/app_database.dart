import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

import 'tables.dart';

part 'app_database.g.dart';

@DriftDatabase(tables: [
  Medications,
  Reminders,
  JournalEntries,
  Documents,
  Caregivers,
  UserProfiles,
  MetricPoints,
  ShareTokens,
  EmergencyAccessCodes,
  SyncOutbox,
  SyncMeta,
])
class AppDatabase extends _$AppDatabase {
  AppDatabase([QueryExecutor? executor]) : super(executor ?? _openConnection());

  @override
  int get schemaVersion => 1;

  static QueryExecutor _openConnection() {
    return driftDatabase(
      name: 'careplus',
      web: kIsWeb
          ? DriftWebOptions(
              sqlite3Wasm: Uri.parse('sqlite3.wasm'),
              driftWorker: Uri.parse('drift_worker.js'),
            )
          : null,
    );
  }
}
