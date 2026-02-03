import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'firebase_service.dart';

class QrService {
  QrService(this._service);

  final FirebaseService _service;

  Future<Map<String, dynamic>> issueCourseQrToken(String courseId) async {
    final callable = _service.functions.httpsCallable('issueCourseQrToken');
    final result = await callable.call({'courseId': courseId});
    return Map<String, dynamic>.from(result.data as Map);
  }

  Future<Map<String, dynamic>> validateQrToken({required String token, required String sessionId}) async {
    final callable = _service.functions.httpsCallable('validateCourseQrToken');
    final result = await callable.call({
      'token': token,
      'sessionId': sessionId,
    });
    return Map<String, dynamic>.from(result.data as Map);
  }
}

final qrServiceProvider = Provider<QrService>((ref) {
  final firebase = ref.read(firebaseServiceProvider);
  return QrService(firebase);
});
