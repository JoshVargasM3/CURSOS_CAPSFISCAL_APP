import 'package:cloud_firestore/cloud_firestore.dart';

class Course {
  Course({
    required this.id,
    required this.title,
    required this.description,
    required this.stateId,
    required this.sedeId,
    required this.startDate,
    required this.endDate,
    required this.priceFull,
    required this.paymentModeAllowed,
    required this.isActive,
  });

  final String id;
  final String title;
  final String description;
  final String stateId;
  final String sedeId;
  final DateTime startDate;
  final DateTime endDate;
  final double priceFull;
  final String paymentModeAllowed;
  final bool isActive;

  factory Course.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data()!;
    return Course(
      id: doc.id,
      title: data['title'] as String? ?? '',
      description: data['description'] as String? ?? '',
      stateId: data['stateId'] as String? ?? '',
      sedeId: data['sedeId'] as String? ?? '',
      startDate: (data['startDate'] as Timestamp).toDate(),
      endDate: (data['endDate'] as Timestamp).toDate(),
      priceFull: (data['priceFull'] as num?)?.toDouble() ?? 0,
      paymentModeAllowed: data['paymentModeAllowed'] as String? ?? 'full_only',
      isActive: data['isActive'] as bool? ?? false,
    );
  }
}
