/// Entity type keys used in sync outbox and Firestore collection names.
abstract final class EntityTypes {
  static const medications = 'medications';
  static const reminders = 'reminders';
  static const journalEntries = 'journal_entries';
  static const documents = 'documents';
  static const caregivers = 'caregivers';
  static const profile = 'profile';
  static const metricPoints = 'metric_points';
  static const shareTokens = 'share_tokens';
  static const emergencyAccess = 'emergency_access';

  static const all = [
    medications,
    reminders,
    journalEntries,
    documents,
    caregivers,
    profile,
    metricPoints,
    shareTokens,
    emergencyAccess,
  ];
}

abstract final class SyncStatuses {
  static const synced = 'synced';
  static const pending = 'pending';
  static const conflict = 'conflict';
}

abstract final class SyncOps {
  static const create = 'create';
  static const update = 'update';
  static const delete = 'delete';
}

abstract final class SyncMetaKeys {
  static const lastPulledAt = 'lastPulledAt';
  static const lastPushAt = 'lastPushAt';
  static const seeded = 'seeded';
}
