// med model

class Medication {
  final String id;
  final String name;
  final String dose;
  final String condition;
  final int refills;
  const Medication({
    required this.id,
    required this.name,
    required this.dose,
    required this.condition,
    required this.refills,
  });

  Medication copyWith({
    String? id,
    String? name,
    String? dose,
    String? condition,
    int? refills,
  }) {
    return Medication(
      id: id ?? this.id,
      name: name ?? this.name,
      dose: dose ?? this.dose,
      condition: condition ?? this.condition,
      refills: refills ?? this.refills,
    );
  }

  factory Medication.fromMap(
    String id,
    Map<String, dynamic> map,
  ) {
    return Medication(
      id: id,
      name: map['name'] ?? '',
      dose: map['dose'] ?? '',
      condition: map['condition'] ?? '',
      refills: map['refills'] ?? 0,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'dose': dose,
      'condition': condition,
      'refills': refills,
    };
  }
}

