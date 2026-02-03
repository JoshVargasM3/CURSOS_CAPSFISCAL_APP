import 'package:cloud_firestore/cloud_firestore.dart';

class Session {
  Session({
    required this.id,
    required this.title,
    required this.dateTime,
    required this.price,
    required this.isActive,
  });

  final String id;
  final String title;
  final String dateTime;
  final double price;
  final bool isActive;

  factory Session.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};
    return Session(
      id: doc.id,
      title: data['title'] as String? ?? '',
      dateTime: data['dateTime'] as String? ?? '',
      price: (data['price'] as num?)?.toDouble() ?? 0,
      isActive: data['isActive'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'title': title,
      'dateTime': dateTime,
      'price': price,
      'isActive': isActive,
    };
  }
}
