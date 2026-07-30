import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

import 'tables.dart';

part 'app_database.g.dart';

@DriftDatabase(
  tables: [
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
  ],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase([QueryExecutor? executor]) : super(executor ?? _openConnection());

  @override
  int get schemaVersion => 2;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (m) async => m.createAll(),
    onUpgrade: (m, from, to) async {
      if (from < 2) {
        await m.addColumn(userProfiles, userProfiles.phone as GeneratedColumn);
        await m.addColumn(documents, documents.storagePath as GeneratedColumn);
        await m.addColumn(documents, documents.downloadUrl as GeneratedColumn);
        await m.addColumn(documents, documents.mimeType as GeneratedColumn);
        await m.addColumn(documents, documents.sizeBytes as GeneratedColumn);
        await m.addColumn(documents, documents.createdAt as GeneratedColumn);
        await m.addColumn(caregivers, caregivers.status as GeneratedColumn);
        await m.addColumn(caregivers, caregivers.invitedAt as GeneratedColumn);
        await m.addColumn(shareTokens, shareTokens.redeemed as GeneratedColumn);
        await m.addColumn(shareTokens, shareTokens.redeemedAt as GeneratedColumn);
        await m.addColumn(
          emergencyAccessCodes,
          emergencyAccessCodes.redeemed as GeneratedColumn,
        );
        await m.addColumn(
          emergencyAccessCodes,
          emergencyAccessCodes.redeemedAt as GeneratedColumn,
        );
      }
    },
  );

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
