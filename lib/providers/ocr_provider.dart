import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/mock_ocr_data_source.dart';
import '../data/ocr_data_source.dart';
import '../repositories/ocr_repository.dart';

final ocrDataSourceProvider =
    Provider<OcrDataSource>((ref) {
  return MockOcrDataSource();
});

final ocrRepositoryProvider =
    Provider<OcrRepository>((ref) {
  return OcrRepository(
    dataSource:
        ref.read(ocrDataSourceProvider),
  );
});

class OcrNotifier
    extends AsyncNotifier<String?> {
  @override
  Future<String?> build() async {
    final repository =
        ref.read(ocrRepositoryProvider);

    return repository.getResult();
  }

  Future<void> processDocument(
      String path) async {
    await ref
        .read(ocrRepositoryProvider)
        .processDocument(path);

    ref.invalidateSelf();
  }

  Future<void> clearResult() async {
    await ref
        .read(ocrRepositoryProvider)
        .clearResult();

    ref.invalidateSelf();
  }
}

final ocrProvider =
    AsyncNotifierProvider<
        OcrNotifier,
        String?>(
  OcrNotifier.new,
);

