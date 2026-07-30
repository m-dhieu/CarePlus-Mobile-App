import '../database/app_database.dart';
import '../sync/outbox_service.dart';

/// Bootstrap hook kept for session wiring.
///
/// Demo seeding is off: providers read Drift, and [SyncEngine] fills / uploads
/// real user data in the background. Re-enable local demo inserts from git
/// history if needed for UI demos
class SeedService {
  SeedService(this.db, this.outbox);

  final AppDatabase db;
  final OutboxService outbox;

  Future<void> seedIfNeeded(String userId) async {
    // no-op in real-data mode
  }
}
