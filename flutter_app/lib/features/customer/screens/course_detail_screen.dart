import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../models/course.dart';
import '../../../models/session.dart';
import '../../../services/payment_service.dart';
import '../../../services/providers.dart';

class CourseDetailScreen extends ConsumerStatefulWidget {
  const CourseDetailScreen({super.key, required this.courseId});

  final String courseId;

  @override
  ConsumerState<CourseDetailScreen> createState() => _CourseDetailScreenState();
}

class _CourseDetailScreenState extends ConsumerState<CourseDetailScreen> {
  final selectedSessions = <String>{};
  String? message;

  Future<void> _payFull() async {
    setState(() => message = null);
    try {
      final paymentService = PaymentService(functions: ref.read(functionsProvider));
      await paymentService.payFullCourse(courseId: widget.courseId);
      setState(() => message = 'Pago iniciado. Espera confirmación.');
    } catch (err) {
      setState(() => message = err.toString());
    }
  }

  Future<void> _paySessions() async {
    if (selectedSessions.isEmpty) {
      setState(() => message = 'Selecciona sesiones.');
      return;
    }
    setState(() => message = null);
    try {
      final paymentService = PaymentService(functions: ref.read(functionsProvider));
      await paymentService.paySessions(courseId: widget.courseId, sessionIds: selectedSessions.toList());
      setState(() => message = 'Pago iniciado. Espera confirmación.');
    } catch (err) {
      setState(() => message = err.toString());
    }
  }

  @override
  Widget build(BuildContext context) {
    final firestore = ref.watch(firestoreProvider);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Detalle del curso'),
        actions: [
          IconButton(
            onPressed: () => context.go('/customer/course/${widget.courseId}/qr'),
            icon: const Icon(Icons.qr_code),
          )
        ],
      ),
      body: FutureBuilder<DocumentSnapshot<Map<String, dynamic>>>(
        future: firestore.doc('courses/${widget.courseId}').get(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final course = Course.fromDoc(snapshot.data!);
          final format = DateFormat('dd/MM/yyyy HH:mm');
          return Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(course.title, style: Theme.of(context).textTheme.headlineSmall),
                Text(course.description),
                const SizedBox(height: 8),
                Text('Inicio: ${format.format(course.startDate)}'),
                Text('Fin: ${format.format(course.endDate)}'),
                const SizedBox(height: 16),
                Text('Sesiones', style: Theme.of(context).textTheme.titleMedium),
                Expanded(
                  child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                    stream: firestore.collection('courses/${widget.courseId}/sessions').where('isActive', isEqualTo: true).snapshots(),
                    builder: (context, sessionSnap) {
                      if (!sessionSnap.hasData) {
                        return const Center(child: CircularProgressIndicator());
                      }
                      final sessions = sessionSnap.data!.docs.map(CourseSession.fromDoc).toList();
                      return ListView.builder(
                        itemCount: sessions.length,
                        itemBuilder: (context, index) {
                          final session = sessions[index];
                          final selected = selectedSessions.contains(session.id);
                          return CheckboxListTile(
                            value: selected,
                            onChanged: (value) {
                              setState(() {
                                if (value == true) {
                                  selectedSessions.add(session.id);
                                } else {
                                  selectedSessions.remove(session.id);
                                }
                              });
                            },
                            title: Text(session.title),
                            subtitle: Text('${format.format(session.dateTime)} - ${session.price.toStringAsFixed(2)}'),
                          );
                        },
                      );
                    },
                  ),
                ),
                if (message != null) Text(message!, style: const TextStyle(color: Colors.indigo)),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        onPressed: course.paymentModeAllowed == 'per_session_only' ? null : _payFull,
                        child: Text('Pagar curso (${course.priceFull.toStringAsFixed(2)})'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: OutlinedButton(
                        onPressed: course.paymentModeAllowed == 'full_only' ? null : _paySessions,
                        child: const Text('Pagar sesiones'),
                      ),
                    )
                  ],
                )
              ],
            ),
          );
        },
      ),
    );
  }
}
