import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../services/providers.dart';

final authStateProvider = StreamProvider<User?>((ref) {
  final auth = ref.watch(firebaseAuthProvider);
  return auth.authStateChanges();
});

final userClaimsProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  final auth = ref.watch(firebaseAuthProvider);
  final user = auth.currentUser;
  if (user == null) {
    return {};
  }
  final token = await user.getIdTokenResult(true);
  return token.claims ?? {};
});
