import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/course.dart';
import '../models/session.dart';
import '../models/enrollment.dart';
import 'firebase_service.dart';

class CourseService {
  CourseService(this._service);

  final FirebaseService _service;

  Stream<List<Course>> watchActiveCourses() {
    return _service.db
        .collection('courses')
        .where('isActive', isEqualTo: true)
        .orderBy('startDate')
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => Course.fromFirestore(doc))
            .toList());
  }

  Stream<Course?> watchCourse(String courseId) {
    return _service.db.collection('courses').doc(courseId).snapshots().map((doc) {
      if (!doc.exists) {
        return null;
      }
      return Course.fromFirestore(doc);
    });
  }

  Stream<List<Session>> watchSessions(String courseId) {
    return _service.db
        .collection('courses')
        .doc(courseId)
        .collection('sessions')
        .where('isActive', isEqualTo: true)
        .orderBy('dateTime')
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => Session.fromFirestore(doc))
            .toList());
  }

  Stream<Enrollment?> watchEnrollment(String courseId, String uid) {
    return _service.db
        .collection('enrollments')
        .where('courseId', isEqualTo: courseId)
        .where('uid', isEqualTo: uid)
        .limit(1)
        .snapshots()
        .map((snapshot) {
      if (snapshot.docs.isEmpty) {
        return null;
      }
      return Enrollment.fromFirestore(snapshot.docs.first);
    });
  }
}

final courseServiceProvider = Provider<CourseService>((ref) {
  final firebase = ref.read(firebaseServiceProvider);
  return CourseService(firebase);
});
