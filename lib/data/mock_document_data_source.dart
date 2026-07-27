import 'package:flutter/material.dart';

import '../models/models.dart';
import 'document_data_source.dart';

class MockDocumentDataSource 
    implements DocumentDataSource {

  final List<MedicalDocument> _documents = [

    MedicalDocument(
      id: '1',
      icon: Icons.description,
      name: 'Blood Test Results',
      source: 'City Hospital · Jan 2026',
    ),

    MedicalDocument(
      id: '2',
      icon: Icons.receipt_long,
      name: 'Prescription History',
      source: 'Dr. Amara Diallo · Feb 2026',
    ),

    MedicalDocument(
      id: '3',
      icon: Icons.science,
      name: 'Diabetes Lab Report',
      source: 'Central Clinic · Mar 2026',
    ),

  ];

  @override
  Future<List<MedicalDocument>> getDocuments() async {

    return List.unmodifiable(_documents);

  }

  @override
  Future<void> addDocument(
      MedicalDocument document) async {

    _documents.add(document);

  }

  @override
  Future<void> updateDocument(
      MedicalDocument document) async {

    final index = _documents.indexWhere(
      (d) => d.id == document.id,
    );

    if (index != -1) {
      _documents[index] = document;
    }

  }

  @override
  Future<void> deleteDocument(
      String id) async {

    _documents.removeWhere(
      (d) => d.id == id,
    );

  }

}

