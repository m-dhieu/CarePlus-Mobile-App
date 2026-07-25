import 'package:flutter/material.dart';

const mockUser = {
  'name': 'Arnold Mugabo',
  'initials': 'AM',
  'age': '42',
  'bloodType': 'O+',
  'height': '174 cm',
  'patientId': 'VTL-2026-08124',
  'hba1c': '6.8%',
  'bpAvg': '124/82',
  'weight': '78 kg',
};

final mockConditions = [
  {'icon': Icons.water_drop, 'name': 'Type 2 Diabetes', 'diagnosed': '2019', 'status': 'Stable'},
  {'icon': Icons.favorite, 'name': 'Hypertension', 'diagnosed': '2021', 'status': 'Stable'},
];

const mockAllergies = ['Penicillin', 'Sulfa drugs', 'Peanuts'];

const mockEmergencyContact = {
  'name': 'Grace Mugisha',
  'relation': 'Spouse',
  'phone': '+250 788 832 123',
};

final mockSettings = [
  {'icon': Icons.notifications, 'label': 'Reminders & notifications', 'value': 'On'},
  {'icon': Icons.shield, 'label': 'Privacy & data sharing', 'value': 'Managed'},
  {'icon': Icons.language, 'label': 'Language', 'value': 'English'},
];

final mockTodaysMeds = [
  {'name': 'Metformin', 'detail': '500 mg · with breakfast', 'time': '08:00', 'status': 'Taken'},
  {'name': 'Lisinopril', 'detail': '10 mg · oral', 'time': '13:30', 'status': 'Due'},
  {'name': 'Atorvastatin', 'detail': '20 mg · evening', 'time': '21:30', 'status': 'Upcoming'},
];

const mockUpcomingVisit = {
  'date': 'JUN 20',
  'title': 'Quarterly endocrinology review',
  'doctor': 'Dr. Amara Diallo',
  'time': '10:30 AM',
};

final mockCareTeam = [
  {'name': 'Dr. Amara Diallo', 'role': 'Endocrinologist', 'hospital': 'Kigali University Hospital'},
  {'name': 'Dr. Henrik Vos', 'role': 'Cardiologist', 'hospital': "St. Mary's Medical Center"},
];

final mockMedsSchedule = <Map<String, dynamic>>[
  {
    'label': 'Morning',
    'time': '8:00',
    'items': <Map<String, dynamic>>[
      {'name': 'Metformin', 'detail': '500 mg · with food', 'status': 'Taken'},
      {'name': 'Lisinopril', 'detail': '10 mg · oral', 'status': 'Taken'},
    ],
  },
  {
    'label': 'Afternoon',
    'time': '13:00',
    'items': <Map<String, dynamic>>[
      {'name': 'Metformin', 'detail': 'Reminder in 12 min', 'status': 'Taken now'},
    ],
  },
];

final mockPrescriptions = [
  {'name': 'Metformin', 'condition': 'Type 2 Diabetes', 'refills': 2},
  {'name': 'Lisinopril', 'condition': 'Hypertension', 'refills': 4},
  {'name': 'Atorvastatin', 'condition': 'Cholesterol', 'refills': 1},
  {'name': 'Vitamin D3', 'condition': 'Supplement', 'refills': 6},
];

final mockHospitals = [
  {'name': 'Kigali University Hospital', 'visits': 18, 'since': 2019},
  {'name': "St. Mary's Medical Center", 'visits': 12, 'since': 2021},
];

final mockDocuments = [
  {'icon': Icons.science, 'name': 'Hb1c lab results', 'source': 'Central Pathology · 29 May 2026'},
  {'icon': Icons.description, 'name': 'Cardiology consultation note', 'source': 'Dr. Henrik Vos · 18 Mar 2026'},
  {'icon': Icons.image, 'name': 'Retina scan – left eye', 'source': 'Riverside Clinic · 2 Apr 2026'},
  {'icon': Icons.description, 'name': 'Discharge summary', 'source': 'Kigali University Hospital · 11 Jan 2026'},
];

final mockDoctorFeedback = [
  {
    'initials': 'DI',
    'name': 'Dr. Amara Diallo',
    'role': 'Endocrinologist · Kigali University Hospital',
    'note': 'Patient is responding well to the current regimen. HbA1c is trending positively. Maintain the plan and monitor blood pressure closely over the next quarter.',
  },
  {
    'initials': 'VO',
    'name': 'Dr. Henrik Vos',
    'role': "Cardiologist · St. Mary's Hospital",
    'note': 'Recommend home BP monitoring twice daily. Lifestyle adjustments are showing measurable improvement — continue with the current dosage.',
  },
];

final mockJournal = <Map<String, dynamic>>[
  {
    'type': 'Visit',
    'date': '08 JUN',
    'facility': 'Kigali University Hospital',
    'title': 'Routine endocrinology check-up',
    'person': 'Dr. Amara Diallo',
    'note': 'HbA1c improved to 6.8%. Continue current regimen. Encouraged consistent meal timing.',
    'tags': <String>['Diabetes', 'Follow-up'],
    'icon': Icons.medical_services,
  },
  {
    'type': 'Lab',
    'date': '29 MAY',
    'facility': 'Central Pathology',
    'title': 'Lipid panel & HbA1c',
    'person': 'Lab · Central Pathology',
    'note': 'LDL 102 mg/dl, HDL 48, HbA1c 6.8%. Triglycerides within range.',
    'tags': <String>['Lab result'],
    'icon': Icons.science,
  },
  {
    'type': 'Prescription',
    'date': '14 MAY',
    'facility': "St. Mary's Medical Center",
    'title': 'Atorvastatin 20mg added',
    'person': 'Dr. Henrik Vos',
    'note': 'Begin once-daily evening dose. Re-evaluate liver enzymes in 8 weeks.',
    'tags': <String>['New med'],
    'icon': Icons.medication,
  },
  {
    'type': 'Procedure',
    'date': '02 APR',
    'facility': 'Riverside Clinic',
    'title': 'Ophthalmology screening – retina',
    'person': 'Dr. Lin Wei',
    'note': 'No diabetic retinopathy detected. Recommend yearly screening.',
    'tags': <String>['Screening', 'Annual'],
    'icon': Icons.monitor_heart,
  },
  {
    'type': 'Visit',
    'date': '18 MAR',
    'facility': "St. Mary's Medical Center",
    'title': 'Cardiology consultation',
    'person': 'Dr. Henrik Vos',
    'note': 'Blood pressure trending high. Adjusted Lisinopril to 10mg. Home monitoring advised.',
    'tags': <String>['New med'],
    'icon': Icons.medical_services,
  },
];

const journalTabs = ['All', 'Visits', 'Labs', 'Prescriptions', 'Procedures'];
const tabToType = {
  'Visits': 'Visit',
  'Labs': 'Lab',
  'Prescriptions': 'Prescription',
  'Procedures': 'Procedure',
};
