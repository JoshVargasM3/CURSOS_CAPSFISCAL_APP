import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../features/auth/screens/login_screen.dart';
import '../features/auth/screens/register_screen.dart';
import '../features/auth/screens/forgot_password_screen.dart';
import '../features/customer/screens/course_list_screen.dart';
import '../features/customer/screens/course_detail_screen.dart';
import '../features/customer/screens/course_qr_screen.dart';
import '../features/checker/screens/checker_home_screen.dart';
import '../features/checker/screens/checker_scan_screen.dart';
import '../features/admin/screens/admin_dashboard_screen.dart';
import '../features/admin/screens/course_edit_screen.dart';
import '../features/admin/screens/session_edit_screen.dart';
import '../features/admin/screens/enrollments_screen.dart';
import '../features/admin/screens/assign_role_screen.dart';
import '../services/auth_service.dart';
import 'role_guard.dart';

final routerProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authStateProvider);
  final roleState = ref.watch(userRoleProvider);

  return GoRouter(
    initialLocation: '/login',
    refreshListenable: GoRouterRefreshStream(ref.watch(authServiceProvider).authStateChanges()),
    redirect: (context, state) {
      final isLoggedIn = authState.valueOrNull != null;
      final loggingIn = state.matchedLocation == '/login' ||
          state.matchedLocation == '/register' ||
          state.matchedLocation == '/forgot';

      if (!isLoggedIn && !loggingIn) {
        return '/login';
      }

      if (isLoggedIn && loggingIn) {
        return '/courses';
      }

      final role = parseRole(roleState.valueOrNull);
      final path = state.matchedLocation;
      if (path.startsWith('/admin') && !roleAllows(role, [UserRole.admin])) {
        return '/courses';
      }
      if (path.startsWith('/checker') && !roleAllows(role, [UserRole.checker])) {
        return '/courses';
      }
      return null;
    },
    routes: [
      GoRoute(
        path: '/login',
        name: 'login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/register',
        name: 'register',
        builder: (context, state) => const RegisterScreen(),
      ),
      GoRoute(
        path: '/forgot',
        name: 'forgot',
        builder: (context, state) => const ForgotPasswordScreen(),
      ),
      GoRoute(
        path: '/courses',
        name: 'courses',
        builder: (context, state) => const CourseListScreen(),
      ),
      GoRoute(
        path: '/courses/:courseId',
        name: 'course-detail',
        builder: (context, state) => CourseDetailScreen(courseId: state.pathParameters['courseId']!),
      ),
      GoRoute(
        path: '/courses/:courseId/qr',
        name: 'course-qr',
        builder: (context, state) => CourseQrScreen(courseId: state.pathParameters['courseId']!),
      ),
      GoRoute(
        path: '/checker',
        name: 'checker',
        builder: (context, state) => const CheckerHomeScreen(),
      ),
      GoRoute(
        path: '/checker/scan',
        name: 'checker-scan',
        builder: (context, state) {
          final courseId = state.uri.queryParameters['courseId'] ?? '';
          final sessionId = state.uri.queryParameters['sessionId'] ?? '';
          return CheckerScanScreen(courseId: courseId, sessionId: sessionId);
        },
      ),
      GoRoute(
        path: '/admin',
        name: 'admin',
        builder: (context, state) => const AdminDashboardScreen(),
      ),
      GoRoute(
        path: '/admin/courses/new',
        name: 'course-new',
        builder: (context, state) => const CourseEditScreen(),
      ),
      GoRoute(
        path: '/admin/courses/:courseId/edit',
        name: 'course-edit',
        builder: (context, state) => CourseEditScreen(courseId: state.pathParameters['courseId']),
      ),
      GoRoute(
        path: '/admin/courses/:courseId/sessions/new',
        name: 'session-new',
        builder: (context, state) => SessionEditScreen(courseId: state.pathParameters['courseId']!),
      ),
      GoRoute(
        path: '/admin/courses/:courseId/sessions/:sessionId/edit',
        name: 'session-edit',
        builder: (context, state) => SessionEditScreen(
          courseId: state.pathParameters['courseId']!,
          sessionId: state.pathParameters['sessionId'],
        ),
      ),
      GoRoute(
        path: '/admin/enrollments',
        name: 'enrollments',
        builder: (context, state) => const EnrollmentsScreen(),
      ),
      GoRoute(
        path: '/admin/assign-role',
        name: 'assign-role',
        builder: (context, state) => const AssignRoleScreen(),
      ),
    ],
  );
});

class GoRouterRefreshStream extends ChangeNotifier {
  GoRouterRefreshStream(Stream<dynamic> stream) {
    _subscription = stream.asBroadcastStream().listen((_) {
      notifyListeners();
    });
  }

  late final StreamSubscription<dynamic> _subscription;

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }
}
