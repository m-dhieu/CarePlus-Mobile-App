import '../data/journal_data_source.dart';
import '../models/models.dart';

class JournalRepository {

  final JournalDataSource dataSource;

  JournalRepository({
    required this.dataSource,
  });

  Future<List<JournalEntry>> getEntries() {
    return dataSource.getEntries();
  }

  Future<void> addEntry(
    JournalEntry entry,
  ) {
    return dataSource.addEntry(entry);
  }

  Future<void> updateEntry(
    JournalEntry entry,
  ) {
    return dataSource.updateEntry(entry);
  }

  Future<void> deleteEntry(
    String id,
  ) {
    return dataSource.deleteEntry(id);
  }
}

