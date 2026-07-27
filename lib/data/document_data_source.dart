import '../models/models.dart';

/*
current med doc data comes from MockDocumentDataSource
future should come from FirestoreDocumentDataSource
*/
abstract class DocumentDataSource {

  Future<List<MedicalDocument>> getDocuments();

  Future<void> addDocument(
    MedicalDocument document,
  );

  Future<void> updateDocument(
    MedicalDocument document,
  );

  Future<void> deleteDocument(
    String id,
  );

}

