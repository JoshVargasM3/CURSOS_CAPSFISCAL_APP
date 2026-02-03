import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../widgets/app_scaffold.dart';

class AdminDashboardScreen extends StatelessWidget {
  const AdminDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: 'Admin Dashboard',
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          ListTile(
            title: const Text('Cursos'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.go('/admin/courses/new'),
          ),
          ListTile(
            title: const Text('Enrollments'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.go('/admin/enrollments'),
          ),
          ListTile(
            title: const Text('Asignar roles'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.go('/admin/assign-role'),
          ),
        ],
      ),
    );
  }
}
