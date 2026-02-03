import 'package:firebase_core/firebase_core.dart';

FirebaseOptions buildFirebaseOptions(Map<String, dynamic> raw) {
  return FirebaseOptions(
    apiKey: raw['apiKey'] as String,
    appId: raw['appId'] as String,
    messagingSenderId: raw['messagingSenderId'] as String,
    projectId: raw['projectId'] as String,
    authDomain: raw['authDomain'] as String?,
    storageBucket: raw['storageBucket'] as String?,
    measurementId: raw['measurementId'] as String?,
  );
}
