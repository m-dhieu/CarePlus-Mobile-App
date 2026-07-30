import '../models/models.dart';
import 'share_token_data_source.dart';

class MockShareTokenDataSource implements ShareTokenDataSource {
  final List<RecordShareToken> _tokens = [];

  @override
  Future<List<RecordShareToken>> getTokens() async {
    return _tokens;
  }

  @override
  Future<RecordShareToken> generateToken(String doctorName) async {
    final token = RecordShareToken(
      token:
          'MED-${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}',
      doctorName: doctorName,
      expiresAt: DateTime.now().add(const Duration(hours: 24)),
    );

    _tokens.add(token);

    return token;
  }

  @override
  Future<void> revokeToken(String token) async {
    _tokens.removeWhere((t) => t.token == token);
  }
}
