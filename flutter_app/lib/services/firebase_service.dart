import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_functions/firebase_functions.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/app_config.dart';

class FirebaseService {
  FirebaseService(this.config);

  final AppConfig config;

  FirebaseAuth get auth => FirebaseAuth.instance;
  FirebaseFirestore get db => FirebaseFirestore.instance;
  FirebaseFunctions get functions => FirebaseFunctions.instanceFor(region: config.functionsRegion);
}

final appConfigProvider = Provider<AppConfig>((ref) {
  return AppConfig.fromEnvironment();
});

final firebaseServiceProvider = Provider<FirebaseService>((ref) {
  final config = ref.read(appConfigProvider);
  return FirebaseService(config);
});
