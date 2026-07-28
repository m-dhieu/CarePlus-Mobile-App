// emergency model

class EmergencyAccessCode {
  final String code;
  final DateTime expiresAt;
  final String scope;
  const EmergencyAccessCode({
    required this.code,
    required this.expiresAt,
    required this.scope,
  });

  bool get isExpired =>
      DateTime.now().isAfter(expiresAt);
  factory EmergencyAccessCode.fromMap(
    String id,
    Map<String, dynamic> map,
  ) {
    return EmergencyAccessCode(
      code: map['code'] ?? '',
      expiresAt: DateTime.parse(
        map['expiresAt'],
      ),
      scope: map['scope'] ?? 'summary',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'code': code,
      'expiresAt':
          expiresAt.toIso8601String(),
      'scope': scope,
    };
  }
}

