import '../models/models.dart';

abstract class ShareTokenDataSource {
  Future<List<RecordShareToken>> getTokens();

  Future<RecordShareToken> generateToken(
    String doctorName,
  );

  Future<void> revokeToken(
    String token,
  );
}

