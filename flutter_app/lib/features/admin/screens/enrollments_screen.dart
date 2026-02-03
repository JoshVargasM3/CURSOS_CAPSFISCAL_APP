import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../models/enrollment.dart';
import '../../../services/admin_service.dart';
import '../../../widgets/app_scaffold.dart';

class EnrollmentsScreen extends ConsumerStatefulWidget {
  const EnrollmentsScreen({super.key});

  @override
  ConsumerState<EnrollmentsScreen> createState() => _EnrollmentsScreenState();
}

class _EnrollmentsScreenState extends ConsumerState<EnrollmentsScreen> {
  final _courseController = TextEditingController();
  String _status = '';

  @override
  Widget build(BuildContext context) {
    final enrollmentsStream = ref.watch(adminServiceProvider).watchEnrollments(
          courseId: _courseController.text.isEmpty ? null : _courseController.text,
          status: _status.isEmpty ? null : _status,
        );

    return AppScaffold(
      title: 'Enrollments',
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                TextField(
                  controller: _courseController,
                  decoration: const InputDecoration(
                    labelText: 'Filtrar por courseId',
                    border: OutlineInputBorder(),
                  ),
                  onChanged: (_) => setState(() {}),
                ),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  value: _status.isEmpty ? null : _status,
                  decoration: const InputDecoration(labelText: 'Estado', border: OutlineInputBorder()),
                  items: const [
                    DropdownMenuItem(value: 'pending', child: Text('Pending')),
                    DropdownMenuItem(value: 'active', child: Text('Active')),
                    DropdownMenuItem(value: 'cancelled', child: Text('Cancelled')),
                    DropdownMenuItem(value: 'completed', child: Text('Completed')),
                  ],
                  onChanged: (value) => setState(() {
                    _status = value ?? '';
                  }),
                ),
              ],
            ),
          ),
          Expanded(
            child: StreamBuilder<List<Enrollment>>(
              stream: enrollmentsStream,
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }
                final enrollments = snapshot.data!;
                if (enrollments.isEmpty) {
                  return const Center(child: Text('Sin enrollments.'));
                }
                return ListView.builder(
                  itemCount: enrollments.length,
                  itemBuilder: (context, index) {
                    final enrollment = enrollments[index];
                    return ListTile(
                      title: Text('Course: ${enrollment.courseId}'),
                      subtitle: Text('UID: ${enrollment.uid} | Estado: ${enrollment.status}'),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
