import '../data/share_token_data_source.dart';
import '../models/models.dart';

class ShareTokenRepository {
  final ShareTokenDataSource dataSource;

  ShareTokenRepository({
    required this.dataSource,
  });

  Future<List<RecordShareToken>> getTokens() {
    return dataSource.getTokens();
  }

  Future<RecordShareToken> generateToken(
    String doctorName,
  ) {
    return dataSource.generateToken(
      doctorName,
    );
  }

  Future<void> revokeToken(
    String token,
  ) {
    return dataSource.revokeToken(
      token,
    );
  }
}

