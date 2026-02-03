import 'package:cloud_firestore/cloud_firestore.dart';

class CourseSession {
  CourseSession({
    required this.id,
    required this.title,
    required this.dateTime,
    required this.price,
    required this.isActive,
  });

  final String id;
  final String title;
  final DateTime dateTime;
  final double price;
  final bool isActive;

  factory CourseSession.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data()!;
    return CourseSession(
      id: doc.id,
      title: data['title'] as String? ?? '',
      dateTime: (data['dateTime'] as Timestamp).toDate(),
      price: (data['price'] as num?)?.toDouble() ?? 0,
      isActive: data['isActive'] as bool? ?? false,
    );
  }
}
