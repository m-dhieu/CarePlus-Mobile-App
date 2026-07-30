import 'package:drift/drift.dart';

/// Shared sync metadata columns mixed into every entity table
mixin SyncColumns on Table {
  TextColumn get userId => text()();
  DateTimeColumn get updatedAt => dateTime()();
  TextColumn get syncStatus => text().withDefault(const Constant('pending'))();
  DateTimeColumn get deletedAt => dateTime().nullable()();
}

@DataClassName('MedicationRow')
class Medications extends Table with SyncColumns {
  TextColumn get id => text()();
  TextColumn get name => text()();
  TextColumn get dose => text()();
  TextColumn get condition => text()();
  IntColumn get refills => integer()();

  @override
  Set<Column> get primaryKey => {id};
}

@DataClassName('ReminderRow')
class Reminders extends Table with SyncColumns {
  TextColumn get id => text()();
  TextColumn get medicationName => text()();
  IntColumn get hour => integer()();
  IntColumn get minute => integer()();
  TextColumn get days => text()(); // JSON list of bools
  BoolColumn get enabled => boolean().withDefault(const Constant(true))();

  @override
  Set<Column> get primaryKey => {id};
}

@DataClassName('JournalEntryRow')
class JournalEntries extends Table with SyncColumns {
  TextColumn get id => text()();
  TextColumn get type => text()();
  TextColumn get date => text()();
  TextColumn get facility => text()();
  TextColumn get title => text()();
  TextColumn get person => text()();
  TextColumn get note => text()();
  TextColumn get tags => text()(); // JSON list
  IntColumn get iconCodePoint => integer()();

  @override
  Set<Column> get primaryKey => {id};
}

@DataClassName('DocumentRow')
class Documents extends Table with SyncColumns {
  TextColumn get id => text()();
  IntColumn get iconCodePoint => integer()();
  TextColumn get name => text()();
  TextColumn get source => text()();
  TextColumn get ocrText => text().nullable()();
  TextColumn get storagePath => text().nullable()();
  TextColumn get downloadUrl => text().nullable()();
  TextColumn get mimeType => text().nullable()();
  IntColumn get sizeBytes => integer().nullable()();
  DateTimeColumn get createdAt => dateTime().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

@DataClassName('CaregiverRow')
class Caregivers extends Table with SyncColumns {
  TextColumn get id => text()();
  TextColumn get name => text()();
  TextColumn get relation => text()();
  TextColumn get phone => text()();
  TextColumn get role => text()();
  BoolColumn get notificationsEnabled =>
      boolean().withDefault(const Constant(true))();
  TextColumn get status => text().withDefault(const Constant('pending'))();
  DateTimeColumn get invitedAt => dateTime().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

@DataClassName('UserProfileRow')
class UserProfiles extends Table with SyncColumns {
  TextColumn get id => text()();
  TextColumn get name => text()();
  TextColumn get initials => text()();
  TextColumn get phone => text().withDefault(const Constant('—'))();
  IntColumn get age => integer()();
  TextColumn get bloodType => text()();
  TextColumn get height => text()();
  TextColumn get patientId => text()();
  TextColumn get hba1c => text()();
  TextColumn get bpAvg => text()();
  TextColumn get weight => text()();
  TextColumn get allergies => text()(); // JSON list
  TextColumn get emergencyName => text()();
  TextColumn get emergencyRelation => text()();
  TextColumn get emergencyPhone => text()();

  @override
  Set<Column> get primaryKey => {id};
}

@DataClassName('MetricPointRow')
class MetricPoints extends Table with SyncColumns {
  TextColumn get id => text()();
  TextColumn get seriesKey => text()();
  TextColumn get label => text()();
  TextColumn get unit => text()();
  DateTimeColumn get date => dateTime()();
  RealColumn get value => real()();

  @override
  Set<Column> get primaryKey => {id};
}

@DataClassName('ShareTokenRow')
class ShareTokens extends Table with SyncColumns {
  TextColumn get id => text()();
  TextColumn get token => text()();
  TextColumn get doctorName => text()();
  DateTimeColumn get expiresAt => dateTime()();
  BoolColumn get redeemed => boolean().withDefault(const Constant(false))();
  DateTimeColumn get redeemedAt => dateTime().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

@DataClassName('EmergencyAccessRow')
class EmergencyAccessCodes extends Table with SyncColumns {
  TextColumn get id => text()();
  TextColumn get code => text()();
  DateTimeColumn get expiresAt => dateTime()();
  TextColumn get scope => text()();
  BoolColumn get redeemed => boolean().withDefault(const Constant(false))();
  DateTimeColumn get redeemedAt => dateTime().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

@DataClassName('SyncOutboxRow')
class SyncOutbox extends Table {
  TextColumn get id => text()();
  TextColumn get userId => text()();
  TextColumn get entityType => text()();
  TextColumn get entityId => text()();
  TextColumn get operation => text()(); // create | update | delete
  TextColumn get payloadJson => text()();
  DateTimeColumn get createdAt => dateTime()();
  IntColumn get attempts => integer().withDefault(const Constant(0))();
  TextColumn get lastError => text().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

@DataClassName('SyncMetaRow')
class SyncMeta extends Table {
  TextColumn get key => text()();
  TextColumn get userId => text()();
  TextColumn get value => text()();

  @override
  Set<Column> get primaryKey => {key, userId};
}
