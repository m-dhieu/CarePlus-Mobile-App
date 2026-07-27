import '../data/document_data_source.dart';
import '../models/models.dart';

class DocumentRepository {
  final DocumentDataSource dataSource;

  DocumentRepository({
    required this.dataSource,
  });

  Future<List<MedicalDocument>> getDocuments() {
    return dataSource.getDocuments();
  }

  Future<void> addDocument(
      MedicalDocument document) {
    return dataSource.addDocument(
      document,
    );
  }

  Future<void> updateDocument(
      MedicalDocument document) {
    return dataSource.updateDocument(
      document,
    );
  }

  Future<void> deleteDocument(
      String id) {
    return dataSource.deleteDocument(
      id,
    );
  }
}

