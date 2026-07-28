// caregiver model

enum CaregiverRole {
  fullAccess,
  viewOnly,
  medsOnly,
}

class Caregiver {
  final String id;
  final String name;
  final String relation;
  final String phone;
  final CaregiverRole role;
  final bool notificationsEnabled;
  const Caregiver({
    required this.id,
    required this.name,
    required this.relation,
    required this.phone,
    required this.role,
    this.notificationsEnabled = true,
  });

  Caregiver copyWith({
    CaregiverRole? role,
    bool? notificationsEnabled,
  }) {
    return Caregiver(
      id: id,
      name: name,
      relation: relation,
      phone: phone,
      role: role ?? this.role,
      notificationsEnabled:
          notificationsEnabled ?? this.notificationsEnabled,
    );
  }

  String get roleLabel {
    switch (role) {
      case CaregiverRole.fullAccess:
        return 'Full access';
      case CaregiverRole.viewOnly:
        return 'View only';
      case CaregiverRole.medsOnly:
        return 'Meds only';
    }
  }

  factory Caregiver.fromMap(
    String id,
    Map<String, dynamic> map,
  ) {
    return Caregiver(
      id: id,
      name: map['name'] ?? '',
      relation: map['relation'] ?? '',
      phone: map['phone'] ?? '',
      role: CaregiverRole.values.firstWhere(
        (e) => e.name == map['role'],
        orElse: () => CaregiverRole.viewOnly,
      ),
      notificationsEnabled:
          map['notificationsEnabled'] ?? true,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'relation': relation,
      'phone': phone,
      'role': role.name,
      'notificationsEnabled': notificationsEnabled,
    };
  }
}

