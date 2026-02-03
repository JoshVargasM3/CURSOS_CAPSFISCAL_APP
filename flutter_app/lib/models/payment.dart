import 'package:cloud_firestore/cloud_firestore.dart';

class Payment {
  Payment({
    required this.id,
    required this.uid,
    required this.courseId,
    required this.type,
    required this.amount,
    required this.currency,
    required this.status,
  });

  final String id;
  final String uid;
  final String courseId;
  final String type;
  final int amount;
  final String currency;
  final String status;

  factory Payment.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};
    return Payment(
      id: doc.id,
      uid: data['uid'] as String? ?? '',
      courseId: data['courseId'] as String? ?? '',
      type: data['type'] as String? ?? '',
      amount: data['amount'] as int? ?? 0,
      currency: data['currency'] as String? ?? '',
      status: data['status'] as String? ?? '',
    );
  }
}
