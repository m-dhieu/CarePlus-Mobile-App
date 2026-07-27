import '../models/models.dart';
import 'medication_data_source.dart';

class MockMedicationDataSource implements MedicationDataSource {

  final List<Medication> _medications = [

    Medication(
      id: '1',
      name: 'Metformin',
      dose: '500 mg',
      condition: 'Type 2 Diabetes',
      refills: 2,
    ),

    Medication(
      id: '2',
      name: 'Lisinopril',
      dose: '10 mg',
      condition: 'Hypertension',
      refills: 4,
    ),

    Medication(
      id: '3',
      name: 'Atorvastatin',
      dose: '20 mg',
      condition: 'Cholesterol',
      refills: 1,
    ),

    Medication(
      id: '4',
      name: 'Vitamin D3',
      dose: '1000 IU',
      condition: 'Supplement',
      refills: 6,
    ),
  ];

  @override
  Future<List<Medication>> getMedications() async {
    return List.unmodifiable(_medications);
  }

  @override
  Future<void> addMedication(
    Medication medication,
  ) async {
    _medications.add(medication);
  }

  @override
  Future<void> updateMedication(
    Medication medication,
  ) async {
    final index = _medications.indexWhere(
      (m) => m.id == medication.id,
    );
    if (index == -1) {
      throw Exception(
        'Medication not found',
      );
    }
    _medications[index] = medication;
  }

  @override
  Future<void> deleteMedication(
    String id,
  ) async {
    _medications.removeWhere(
      (m) => m.id == id,
    );
  }
}

