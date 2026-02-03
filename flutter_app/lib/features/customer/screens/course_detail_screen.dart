import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../models/course.dart';
import '../../../models/enrollment.dart';
import '../../../models/session.dart';
import '../../../services/auth_service.dart';
import '../../../services/course_service.dart';
import '../../../services/payment_service.dart';
import '../../../widgets/app_scaffold.dart';
import '../../../widgets/primary_button.dart';

class CourseDetailScreen extends ConsumerStatefulWidget {
  const CourseDetailScreen({super.key, required this.courseId});

  final String courseId;

  @override
  ConsumerState<CourseDetailScreen> createState() => _CourseDetailScreenState();
}

class _CourseDetailScreenState extends ConsumerState<CourseDetailScreen> {
  final Set<String> _selectedSessions = {};
  bool _isPaying = false;
  String? _message;

  Future<void> _payFull() async {
    setState(() {
      _isPaying = true;
      _message = null;
    });
    try {
      await ref.read(paymentServiceProvider).payFull(courseId: widget.courseId);
      setState(() {
        _message = 'Pago iniciado. Espera la confirmación del webhook.';
      });
    } catch (error) {
      setState(() {
        _message = error.toString();
      });
    } finally {
      setState(() {
        _isPaying = false;
      });
    }
  }

  Future<void> _paySessions() async {
    if (_selectedSessions.isEmpty) {
      setState(() {
        _message = 'Selecciona al menos una sesión.';
      });
      return;
    }
    setState(() {
      _isPaying = true;
      _message = null;
    });
    try {
      await ref.read(paymentServiceProvider).paySessions(
            courseId: widget.courseId,
            sessionIds: _selectedSessions.toList(),
          );
      setState(() {
        _message = 'Pago iniciado. Espera la confirmación del webhook.';
      });
    } catch (error) {
      setState(() {
        _message = error.toString();
      });
    } finally {
      setState(() {
        _isPaying = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final courseStream = ref.watch(courseServiceProvider).watchCourse(widget.courseId);
    final sessionsStream = ref.watch(courseServiceProvider).watchSessions(widget.courseId);
    final uid = ref.watch(authStateProvider).valueOrNull?.uid;

    return AppScaffold(
      title: 'Detalle del curso',
      body: StreamBuilder<Course?>(
        stream: courseStream,
        builder: (context, courseSnapshot) {
          if (!courseSnapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final course = courseSnapshot.data;
          if (course == null) {
            return const Center(child: Text('Curso no encontrado'));
          }

          return StreamBuilder<List<Session>>(
            stream: sessionsStream,
            builder: (context, sessionSnapshot) {
              final sessions = sessionSnapshot.data ?? [];
              return StreamBuilder<Enrollment?>(
                stream: uid == null
                    ? Stream<Enrollment?>.empty()
                    : ref.watch(courseServiceProvider).watchEnrollment(widget.courseId, uid),
                builder: (context, enrollmentSnapshot) {
                  final enrollment = enrollmentSnapshot.data;
                  final canPayFull = course.paymentModeAllowed != 'per_session_only';
                  final canPaySessions = course.paymentModeAllowed != 'full_only';
                  return ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      Text(course.title, style: Theme.of(context).textTheme.headlineSmall),
                      const SizedBox(height: 8),
                      Text(course.description),
                      const SizedBox(height: 16),
                      Text('Precio completo: MXN ${course.priceFull.toStringAsFixed(2)}'),
                      const SizedBox(height: 16),
                      if (enrollment != null)
                        Card(
                          child: ListTile(
                            title: const Text('Estado de inscripción'),
                            subtitle: Text(enrollment.status),
                            trailing: enrollment.status == 'active'
                                ? TextButton(
                                    onPressed: () => context.go('/courses/${course.id}/qr'),
                                    child: const Text('Ver QR'),
                                  )
                                : null,
                          ),
                        ),
                      const SizedBox(height: 16),
                      if (sessions.isNotEmpty) Text('Sesiones', style: Theme.of(context).textTheme.titleMedium),
                      ...sessions.map(
                        (session) => CheckboxListTile(
                          title: Text(session.title),
                          subtitle: Text('MXN ${session.price.toStringAsFixed(2)} | ${session.dateTime}'),
                          value: _selectedSessions.contains(session.id),
                          onChanged: canPaySessions
                              ? (value) {
                                  setState(() {
                                    if (value == true) {
                                      _selectedSessions.add(session.id);
                                    } else {
                                      _selectedSessions.remove(session.id);
                                    }
                                  });
                                }
                              : null,
                        ),
                      ),
                      if (_message != null)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          child: Text(_message!, style: const TextStyle(color: Colors.blueGrey)),
                        ),
                      if (canPayFull)
                        PrimaryButton(
                          label: 'Pagar curso completo',
                          onPressed: _isPaying ? null : _payFull,
                          isLoading: _isPaying,
                        ),
                      if (canPaySessions)
                        Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: PrimaryButton(
                            label: 'Pagar sesiones seleccionadas',
                            onPressed: _isPaying ? null : _paySessions,
                            isLoading: _isPaying,
                          ),
                        ),
                    ],
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}
