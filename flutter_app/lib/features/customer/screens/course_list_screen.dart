import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/role_guard.dart';
import '../../../models/course.dart';
import '../../../services/auth_service.dart';
import '../../../services/course_service.dart';
import '../../../widgets/app_scaffold.dart';

class CourseListScreen extends ConsumerWidget {
  const CourseListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final coursesStream = ref.watch(courseServiceProvider).watchActiveCourses();
    final roleAsync = ref.watch(userRoleProvider);

    return AppScaffold(
      title: 'Cursos disponibles',
      actions: [
        if (roleAsync.valueOrNull != null)
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await ref.read(authServiceProvider).signOut();
              if (context.mounted) {
                context.go('/login');
              }
            },
          ),
      ],
      body: StreamBuilder<List<Course>>(
        stream: coursesStream,
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final courses = snapshot.data!;
          if (courses.isEmpty) {
            return const Center(child: Text('No hay cursos activos.'));
          }
          return ListView(
            children: [
              if (roleAsync.valueOrNull != null)
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      if (roleAllows(parseRole(roleAsync.value), [UserRole.admin]))
                        ElevatedButton(
                          onPressed: () => context.go('/admin'),
                          child: const Text('Panel admin'),
                        ),
                      if (roleAllows(parseRole(roleAsync.value), [UserRole.checker]))
                        ElevatedButton(
                          onPressed: () => context.go('/checker'),
                          child: const Text('Checker'),
                        ),
                    ],
                  ),
                ),
              ...courses.map(
                (course) => ListTile(
                  title: Text(course.title),
                  subtitle: Text(course.description),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => context.go('/courses/${course.id}'),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
