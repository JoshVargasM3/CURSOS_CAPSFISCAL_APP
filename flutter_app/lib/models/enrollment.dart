import 'package:cloud_firestore/cloud_firestore.dart';

class Enrollment {
  Enrollment({
    required this.id,
    required this.uid,
    required this.courseId,
    required this.stateId,
    required this.sedeId,
    required this.status,
    required this.paidFull,
    required this.sessionsPaid,
  });

  final String id;
  final String uid;
  final String courseId;
  final String stateId;
  final String sedeId;
  final String status;
  final bool paidFull;
  final List<String> sessionsPaid;

  factory Enrollment.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};
    return Enrollment(
      id: doc.id,
      uid: data['uid'] as String? ?? '',
      courseId: data['courseId'] as String? ?? '',
      stateId: data['stateId'] as String? ?? '',
      sedeId: data['sedeId'] as String? ?? '',
      status: data['status'] as String? ?? 'pending',
      paidFull: data['paidFull'] as bool? ?? false,
      sessionsPaid: (data['sessionsPaid'] as List?)?.cast<String>() ?? [],
    );
  }
}
