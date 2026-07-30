abstract class OcrDataSource {
  Future<String?> getResult();

  Future<String?> processDocument(String path);

  Future<void> clearResult();
}
