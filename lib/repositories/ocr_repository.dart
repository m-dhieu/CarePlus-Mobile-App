import '../data/ocr_data_source.dart';

class OcrRepository {
  final OcrDataSource dataSource;

  OcrRepository({
    required this.dataSource,
  });

  Future<String?> processDocument(
    String path,
  ) {
    return dataSource.processDocument(
      path,
    );
  }

  Future<void> clearResult() {
    return dataSource.clearResult();
  }

  Future<String?> getResult() {
    return dataSource.getResult();
  }
}

