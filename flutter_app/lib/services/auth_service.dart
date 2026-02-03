import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'firebase_service.dart';

class AuthService {
  AuthService(this._service);

  final FirebaseService _service;

  Stream<User?> authStateChanges() => _service.auth.authStateChanges();

  Future<void> signIn({required String email, required String password}) async {
    await _service.auth.signInWithEmailAndPassword(email: email, password: password);
  }

  Future<void> register({
    required String fullName,
    required String email,
    required String phone,
    required String password,
  }) async {
    final credential = await _service.auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );

    final uid = credential.user?.uid;
    if (uid == null) {
      throw StateError('No user created');
    }

    await _service.db.collection('users').doc(uid).set({
      'fullName': fullName,
      'email': email,
      'phone': phone,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> resetPassword(String email) async {
    await _service.auth.sendPasswordResetEmail(email: email);
  }

  Future<void> signOut() async {
    await _service.auth.signOut();
  }

  Future<String?> currentRole() async {
    final user = _service.auth.currentUser;
    if (user == null) {
      return null;
    }
    final token = await user.getIdTokenResult(true);
    return token.claims?['role'] as String?;
  }
}

final authServiceProvider = Provider<AuthService>((ref) {
  final firebase = ref.read(firebaseServiceProvider);
  return AuthService(firebase);
});

final authStateProvider = StreamProvider<User?>((ref) {
  return ref.read(authServiceProvider).authStateChanges();
});

final userRoleProvider = FutureProvider<String?>((ref) {
  return ref.read(authServiceProvider).currentRole();
});
