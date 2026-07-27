import 'package:flutter/material.dart';

// document model

class MedicalDocument {
  final String id;
  final IconData icon;
  final String name;
  final String source;
  final String? ocrText;

  const MedicalDocument({
    required this.id,
    required this.icon,
    required this.name,
    required this.source,
    this.ocrText,
  });

  MedicalDocument copyWith({
    String? id,
    IconData? icon,
    String? name,
    String? source,
    String? ocrText,
  }) {
    return MedicalDocument(
      id: id ?? this.id,
      icon: icon ?? this.icon,
      name: name ?? this.name,
      source: source ?? this.source,
      ocrText: ocrText ?? this.ocrText,
    );
  }

  factory MedicalDocument.fromMap(
    String id,
    Map<String, dynamic> map,
  ) {
    return MedicalDocument(
      id: id,
      icon: Icons.description,
      name: map['name'] ?? '',
      source: map['source'] ?? '',
      ocrText: map['ocrText'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'source': source,
      'ocrText': ocrText,
    };
  }
}

