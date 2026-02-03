import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../services/admin_service.dart';
import '../../../widgets/app_scaffold.dart';
import '../../../widgets/form_fields.dart';
import '../../../widgets/primary_button.dart';

class AssignRoleScreen extends ConsumerStatefulWidget {
  const AssignRoleScreen({super.key});

  @override
  ConsumerState<AssignRoleScreen> createState() => _AssignRoleScreenState();
}

class _AssignRoleScreenState extends ConsumerState<AssignRoleScreen> {
  final _emailController = TextEditingController();
  String _role = 'customer';
  String? _message;
  bool _isLoading = false;

  Future<void> _assign() async {
    setState(() {
      _isLoading = true;
      _message = null;
    });
    try {
      await ref.read(adminServiceProvider).assignRoleByEmail(
            email: _emailController.text.trim(),
            role: _role,
          );
      setState(() {
        _message = 'Rol asignado.';
      });
    } catch (error) {
      setState(() {
        _message = error.toString();
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: 'Asignar rol',
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextFieldGroup(label: 'Email', controller: _emailController, keyboardType: TextInputType.emailAddress),
            DropdownButtonFormField<String>(
              value: _role,
              decoration: const InputDecoration(labelText: 'Rol', border: OutlineInputBorder()),
              items: const [
                DropdownMenuItem(value: 'customer', child: Text('Customer')),
                DropdownMenuItem(value: 'checker', child: Text('Checker')),
                DropdownMenuItem(value: 'admin', child: Text('Admin')),
              ],
              onChanged: (value) => setState(() => _role = value ?? 'customer'),
            ),
            const SizedBox(height: 12),
            PrimaryButton(label: 'Asignar', onPressed: _isLoading ? null : _assign, isLoading: _isLoading),
            if (_message != null)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(_message!, style: const TextStyle(color: Colors.blueGrey)),
              ),
          ],
        ),
      ),
    );
  }
}
