import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/document_data_source.dart';
import '../data/mock_document_data_source.dart';
import '../models/models.dart';
import '../repositories/document_repository.dart';

final documentDataSourceProvider =
    Provider<DocumentDataSource>((ref) {
  return MockDocumentDataSource();
});

final documentRepositoryProvider =
    Provider<DocumentRepository>((ref) {
  return DocumentRepository(
    dataSource:
      ref.read(documentDataSourceProvider),
  );
});

class DocumentsNotifier
    extends AsyncNotifier<List<MedicalDocument>> {
  @override
  Future<List<MedicalDocument>> build() async {
    final repository =
        ref.read(documentRepositoryProvider);
    return repository.getDocuments();
  }

  Future<void> addDocument(
    MedicalDocument document) async {
    await ref
      .read(documentRepositoryProvider)
      .addDocument(document);

    ref.invalidateSelf();
}

  Future<void> deleteDocument(
      String id) async {
    await ref
        .read(documentRepositoryProvider)
        .deleteDocument(id);
    ref.invalidateSelf();
  }
}

final documentsProvider =
    AsyncNotifierProvider<
      DocumentsNotifier,
      List<MedicalDocument>>(
        DocumentsNotifier.new,
      );

