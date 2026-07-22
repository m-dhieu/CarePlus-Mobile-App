import 'package:cloud_firestore/cloud_firestore.dart';

class AppUser {
  const AppUser({
    required this.uid,
    required this.fullName,
    required this.email,
    this.phone = '',
    required this.role,
    required this.status,
  });

  final String uid;
  final String fullName;
  final String email;
  final String phone;
  final String role;
  final String status;

  factory AppUser.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? const {};
    return AppUser(
      uid: doc.id,
      fullName: data['fullName'] as String? ?? '',
      email: data['email'] as String? ?? '',
      phone: data['phone'] as String? ?? '',
      role: data['role'] as String? ?? 'patient',
      status: data['status'] as String? ?? 'active',
    );
  }

  Map<String, dynamic> toNewDoc() {
    return {
      'fullName': fullName,
      'email': email,
      'phone': phone,
      'role': role,
      'status': status,
      'createdAt': FieldValue.serverTimestamp(),
      'lastLogin': FieldValue.serverTimestamp(),
    };
  }
}
