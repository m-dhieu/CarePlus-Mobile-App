// user profile model

class EmergencyContact {
  final String name;
  final String relation;
  final String phone;
  const EmergencyContact({
    required this.name,
    required this.relation,
    required this.phone,
  });
  EmergencyContact copyWith({
    String? name,
    String? relation,
    String? phone,
  }) {
    return EmergencyContact(
      name: name ?? this.name,
      relation: relation ?? this.relation,
      phone: phone ?? this.phone,
    );
  }
  factory EmergencyContact.fromMap(
    Map<String, dynamic> map,
  ) {
    return EmergencyContact(
      name: map['name'] ?? '',
      relation: map['relation'] ?? '',
      phone: map['phone'] ?? '',
    );
  }
  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'relation': relation,
      'phone': phone,
    };
  }
}

class UserProfile {
  final String name;
  final String initials;
  final int age;
  final String bloodType;
  final String height;
  final String patientId;
  final String hba1c;
  final String bpAvg;
  final String weight;
  final List<String> allergies;
  final EmergencyContact emergencyContact;
  const UserProfile({
    required this.name,
    required this.initials,
    required this.age,
    required this.bloodType,
    required this.height,
    required this.patientId,
    required this.hba1c,
    required this.bpAvg,
    required this.weight,
    required this.allergies,
    required this.emergencyContact,
  });
  UserProfile copyWith({
    String? name,
    String? initials,
    int? age,
    String? bloodType,
    String? height,
    String? patientId,
    String? hba1c,
    String? bpAvg,
    String? weight,
    List<String>? allergies,
    EmergencyContact? emergencyContact,
  }) {
    return UserProfile(
      name: name ?? this.name,
      initials: initials ?? this.initials,
      age: age ?? this.age,
      bloodType: bloodType ?? this.bloodType,
      height: height ?? this.height,
      patientId: patientId ?? this.patientId,
      hba1c: hba1c ?? this.hba1c,
      bpAvg: bpAvg ?? this.bpAvg,
      weight: weight ?? this.weight,
      allergies: allergies ?? this.allergies,
      emergencyContact:
          emergencyContact ?? this.emergencyContact,
    );
  }
  factory UserProfile.fromMap(
    Map<String, dynamic> map,
  ) {
    return UserProfile(
      name: map['name'] ?? '',
      initials: map['initials'] ?? '',
      age: map['age'] ?? 0,
      bloodType: map['bloodType'] ?? '',
      height: map['height'] ?? '',
      patientId: map['patientId'] ?? '',
      hba1c: map['hba1c'] ?? '',
      bpAvg: map['bpAvg'] ?? '',
      weight: map['weight'] ?? '',
      allergies:
          List<String>.from(map['allergies'] ?? []),
      emergencyContact: EmergencyContact.fromMap(
        map['emergencyContact'] ?? {},
      ),
    );
  }
  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'initials': initials,
      'age': age,
      'bloodType': bloodType,
      'height': height,
      'patientId': patientId,
      'hba1c': hba1c,
      'bpAvg': bpAvg,
      'weight': weight,
      'allergies': allergies,
      'emergencyContact':
          emergencyContact.toMap(),
    };
  }
}

