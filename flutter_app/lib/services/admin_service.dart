import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/course.dart';
import '../models/session.dart';
import '../models/enrollment.dart';
import 'firebase_service.dart';

class AdminService {
  AdminService(this._service);

  final FirebaseService _service;

  Future<void> saveCourse(Course course) async {
    final ref = _service.db.collection('courses').doc(course.id);
    await ref.set(course.toFirestore(), SetOptions(merge: true));
  }

  Future<void> saveSession(String courseId, Session session) async {
    final ref = _service.db
        .collection('courses')
        .doc(courseId)
        .collection('sessions')
        .doc(session.id);
    await ref.set(session.toFirestore(), SetOptions(merge: true));
  }

  Stream<List<Course>> watchAllCourses() {
    return _service.db.collection('courses').snapshots().map((snapshot) {
      return snapshot.docs.map((doc) => Course.fromFirestore(doc)).toList();
    });
  }

  Stream<List<Session>> watchAllSessions(String courseId) {
    return _service.db
        .collection('courses')
        .doc(courseId)
        .collection('sessions')
        .orderBy('dateTime')
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => Session.fromFirestore(doc)).toList());
  }

  Stream<List<Enrollment>> watchEnrollments({String? courseId, String? status}) {
    Query query = _service.db.collection('enrollments');
    if (courseId != null && courseId.isNotEmpty) {
      query = query.where('courseId', isEqualTo: courseId);
    }
    if (status != null && status.isNotEmpty) {
      query = query.where('status', isEqualTo: status);
    }
    return query.snapshots().map((snapshot) {
      return snapshot.docs.map((doc) => Enrollment.fromFirestore(doc)).toList();
    });
  }

  Future<void> assignRoleByEmail({required String email, required String role}) async {
    final userSnap = await _service.db.collection('users').where('email', isEqualTo: email).limit(1).get();
    if (userSnap.docs.isEmpty) {
      throw StateError('No user found for email');
    }
    final uid = userSnap.docs.first.id;
    final callable = _service.functions.httpsCallable('setRole');
    await callable.call({'uid': uid, 'role': role});
  }
}

final adminServiceProvider = Provider<AdminService>((ref) {
  final firebase = ref.read(firebaseServiceProvider);
  return AdminService(firebase);
});
