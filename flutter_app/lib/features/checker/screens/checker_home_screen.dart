import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../models/course.dart';
import '../../../models/session.dart';
import '../../../services/course_service.dart';
import '../../../widgets/app_scaffold.dart';
import '../../../widgets/primary_button.dart';

class CheckerHomeScreen extends ConsumerStatefulWidget {
  const CheckerHomeScreen({super.key});

  @override
  ConsumerState<CheckerHomeScreen> createState() => _CheckerHomeScreenState();
}

class _CheckerHomeScreenState extends ConsumerState<CheckerHomeScreen> {
  Course? _selectedCourse;
  Session? _selectedSession;

  @override
  Widget build(BuildContext context) {
    final coursesStream = ref.watch(courseServiceProvider).watchActiveCourses();

    return AppScaffold(
      title: 'Checker',
      body: StreamBuilder<List<Course>>(
        stream: coursesStream,
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final courses = snapshot.data!;
          return Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                DropdownButtonFormField<Course>(
                  value: _selectedCourse,
                  decoration: const InputDecoration(labelText: 'Curso', border: OutlineInputBorder()),
                  items: courses
                      .map((course) => DropdownMenuItem(value: course, child: Text(course.title)))
                      .toList(),
                  onChanged: (course) {
                    setState(() {
                      _selectedCourse = course;
                      _selectedSession = null;
                    });
                  },
                ),
                const SizedBox(height: 16),
                if (_selectedCourse != null)
                  StreamBuilder<List<Session>>(
                    stream: ref.watch(courseServiceProvider).watchSessions(_selectedCourse!.id),
                    builder: (context, sessionSnapshot) {
                      final sessions = sessionSnapshot.data ?? [];
                      return DropdownButtonFormField<Session>(
                        value: _selectedSession,
                        decoration: const InputDecoration(labelText: 'Sesión', border: OutlineInputBorder()),
                        items: sessions
                            .map((session) => DropdownMenuItem(
                                  value: session,
                                  child: Text('${session.title} (${session.dateTime})'),
                                ))
                            .toList(),
                        onChanged: (session) {
                          setState(() {
                            _selectedSession = session;
                          });
                        },
                      );
                    },
                  ),
                const Spacer(),
                PrimaryButton(
                  label: 'Escanear QR',
                  onPressed: (_selectedCourse != null && _selectedSession != null)
                      ? () => context.go('/checker/scan?courseId=${_selectedCourse!.id}&sessionId=${_selectedSession!.id}')
                      : null,
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
