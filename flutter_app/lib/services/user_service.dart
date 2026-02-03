import 'package:cloud_firestore/cloud_firestore.dart';

class UserService {
  UserService(this.firestore);

  final FirebaseFirestore firestore;

  Future<void> createProfile({
    required String uid,
    required String fullName,
    required String email,
    required String phone,
  }) async {
    await firestore.doc('users/$uid').set({
      'fullName': fullName,
      'email': email,
      'phone': phone,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }
}
