import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../services/auth_service.dart';
import '../../../widgets/app_scaffold.dart';
import '../../../widgets/form_fields.dart';
import '../../../widgets/primary_button.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  String? _error;

  Future<void> _submit() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      await ref.read(authServiceProvider).signIn(
            email: _emailController.text.trim(),
            password: _passwordController.text,
          );
      if (mounted) {
        context.go('/courses');
      }
    } catch (error) {
      setState(() {
        _error = error.toString();
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: 'Iniciar sesión',
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextFieldGroup(label: 'Email', controller: _emailController, keyboardType: TextInputType.emailAddress),
            TextFieldGroup(label: 'Contraseña', controller: _passwordController, obscureText: true),
            if (_error != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Text(_error!, style: const TextStyle(color: Colors.red)),
              ),
            PrimaryButton(label: 'Entrar', onPressed: _isLoading ? null : _submit, isLoading: _isLoading),
            TextButton(
              onPressed: () => context.go('/register'),
              child: const Text('Crear cuenta'),
            ),
            TextButton(
              onPressed: () => context.go('/forgot'),
              child: const Text('Olvidé mi contraseña'),
            ),
          ],
        ),
      ),
    );
  }
}
