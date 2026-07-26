import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/journal_data_source.dart';
import '../data/mock_journal_data_source.dart';
import '../models/models.dart';
import '../repositories/journal_repository.dart';

final journalDataSourceProvider =
    Provider<JournalDataSource>((ref) {

  return MockJournalDataSource();

  /*
  later:
  return FirestoreJournalDataSource(
    firestore: FirebaseFirestore.instance,
  );
  */
});

final journalRepositoryProvider =
    Provider<JournalRepository>((ref) {

  return JournalRepository(
    dataSource:
        ref.read(journalDataSourceProvider),
  );
});

class JournalNotifier
    extends AsyncNotifier<List<JournalEntry>> {

  @override
  Future<List<JournalEntry>> build() async {

    return ref
        .read(journalRepositoryProvider)
        .getEntries();
  }

  Future<void> addEntry(
      JournalEntry entry) async {

    await ref
        .read(journalRepositoryProvider)
        .addEntry(entry);

    ref.invalidateSelf();
  }

  Future<void> updateEntry(
      JournalEntry entry) async {

    await ref
        .read(journalRepositoryProvider)
        .updateEntry(entry);

    ref.invalidateSelf();
  }

  Future<void> deleteEntry(
      String id) async {

    await ref
        .read(journalRepositoryProvider)
        .deleteEntry(id);

    ref.invalidateSelf();
  }
}

final journalProvider =
    AsyncNotifierProvider<
        JournalNotifier,
        List<JournalEntry>>(
  JournalNotifier.new,
);

