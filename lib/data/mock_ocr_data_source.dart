import 'ocr_data_source.dart';

class MockOcrDataSource
    implements OcrDataSource {
  String? _result;

  @override
  Future<String?> getResult() async {
    return _result;
  }

  @override
  Future<String?> processDocument(
    String path,
  ) async {
    await Future.delayed(
      const Duration(seconds: 2),
    );

    _result = '''
HbA1c: 6.8%
Blood Pressure: 124/82
Glucose: 108 mg/dL
''';

    return _result;
  }

  @override
  Future<void> clearResult() async {
    _result = null;
  }
}

