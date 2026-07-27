import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/mock_share_token_data_source.dart';
import '../data/share_token_data_source.dart';
import '../models/models.dart';
import '../repositories/share_token_repository.dart';

final shareTokenDataSourceProvider =
    Provider<ShareTokenDataSource>((ref) {
  return MockShareTokenDataSource();
});

final shareTokenRepositoryProvider =
    Provider<ShareTokenRepository>((ref) {
  return ShareTokenRepository(
    dataSource:
        ref.read(shareTokenDataSourceProvider),
  );
});

class ShareTokensNotifier
    extends AsyncNotifier<List<RecordShareToken>> {
  @override
  Future<List<RecordShareToken>> build() async {
    final repository =
        ref.read(shareTokenRepositoryProvider);

    return repository.getTokens();
  }

  Future<RecordShareToken> generateToken(
      String doctorName) async {
    final token = await ref
        .read(shareTokenRepositoryProvider)
        .generateToken(doctorName);

    ref.invalidateSelf();

    return token;
  }

  Future<void> revokeToken(
      String token) async {
    await ref
        .read(shareTokenRepositoryProvider)
        .revokeToken(token);

    ref.invalidateSelf();
  }
}

final shareTokensProvider =
    AsyncNotifierProvider<
        ShareTokensNotifier,
        List<RecordShareToken>>(
  ShareTokensNotifier.new,
);

