import 'package:firebase_functions/firebase_functions.dart';

class QrService {
  QrService(this.functions);

  final FirebaseFunctions functions;

  Future<Map<String, dynamic>> issueCourseQrToken(String courseId) async {
    final callable = functions.httpsCallable('issueCourseQrToken');
    final result = await callable.call({ 'courseId': courseId });
    return Map<String, dynamic>.from(result.data as Map);
  }

  Future<Map<String, dynamic>> validateCourseQrToken({required String token, String? sessionId}) async {
    final callable = functions.httpsCallable('validateCourseQrToken');
    final result = await callable.call({
      'token': token,
      'sessionId': sessionId,
    });
    return Map<String, dynamic>.from(result.data as Map);
  }
}
