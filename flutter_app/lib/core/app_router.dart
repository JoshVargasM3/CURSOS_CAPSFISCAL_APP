import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../features/auth/auth_providers.dart';
import '../features/auth/screens/forgot_password_screen.dart';
import '../features/auth/screens/login_screen.dart';
import '../features/auth/screens/register_screen.dart';
import '../features/customer/screens/course_detail_screen.dart';
import '../features/customer/screens/course_list_screen.dart';
import '../features/customer/screens/course_qr_screen.dart';
import '../features/checker/screens/checker_screen.dart';
import '../features/admin/screens/admin_dashboard_screen.dart';

final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    routes: [
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/register',
        builder: (context, state) => const RegisterScreen(),
      ),
      GoRoute(
        path: '/forgot',
        builder: (context, state) => const ForgotPasswordScreen(),
      ),
      GoRoute(
        path: '/customer',
        builder: (context, state) => const CourseListScreen(),
        routes: [
          GoRoute(
            path: 'course/:id',
            builder: (context, state) => CourseDetailScreen(courseId: state.pathParameters['id']!),
          ),
          GoRoute(
            path: 'course/:id/qr',
            builder: (context, state) => CourseQrScreen(courseId: state.pathParameters['id']!),
          ),
        ],
      ),
      GoRoute(
        path: '/checker',
        builder: (context, state) => const CheckerScreen(),
      ),
      GoRoute(
        path: '/admin',
        builder: (context, state) => const AdminDashboardScreen(),
      ),
      GoRoute(
        path: '/',
        redirect: (_, __) => '/login',
      )
    ],
    redirect: (context, state) {
      final authState = ref.read(authStateProvider).asData?.value;
      final claims = ref.read(userClaimsProvider).asData?.value ?? {};
      final role = claims['role'] as String?;
      final isLoggingIn = state.matchedLocation == '/login' ||
          state.matchedLocation == '/register' ||
          state.matchedLocation == '/forgot';

      if (authState == null) {
        return isLoggingIn ? null : '/login';
      }

      if (role == 'admin') {
        return state.matchedLocation.startsWith('/admin') ? null : '/admin';
      }
      if (role == 'checker') {
        return state.matchedLocation.startsWith('/checker') ? null : '/checker';
      }
      return state.matchedLocation.startsWith('/customer') ? null : '/customer';
    },
    refreshListenable: GoRouterRefreshStream(ref.watch(authStateProvider).asStream()),
  );
});

class GoRouterRefreshStream extends ChangeNotifier {
  GoRouterRefreshStream(Stream<dynamic> stream) {
    stream.listen((_) => notifyListeners());
  }
}
