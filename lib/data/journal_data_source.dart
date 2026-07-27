import '../models/models.dart';

abstract class JournalDataSource {

  Future<List<JournalEntry>> getEntries();

  Future<void> addEntry(
    JournalEntry entry,
  );

  Future<void> updateEntry(
    JournalEntry entry,
  );

  Future<void> deleteEntry(
    String id,
  );
}

