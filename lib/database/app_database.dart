import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'dart:io';

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

  static LazyDatabase _openConnection() {
    return LazyDatabase(() async {
      final dir = await getApplicationDocumentsDirectory();
      final file = File(p.join(dir.path, 'careplus.sqlite'));
      return NativeDatabase.createInBackground(file);
    });
  }
}
