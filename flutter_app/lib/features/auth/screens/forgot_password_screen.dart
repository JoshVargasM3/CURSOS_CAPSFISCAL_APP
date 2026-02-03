import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../services/auth_service.dart';
import '../../../widgets/app_scaffold.dart';
import '../../../widgets/form_fields.dart';
import '../../../widgets/primary_button.dart';

class ForgotPasswordScreen extends ConsumerStatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  ConsumerState<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends ConsumerState<ForgotPasswordScreen> {
  final _emailController = TextEditingController();
  bool _isLoading = false;
  String? _message;

  Future<void> _submit() async {
    setState(() {
      _isLoading = true;
      _message = null;
    });
    try {
      await ref.read(authServiceProvider).resetPassword(_emailController.text.trim());
      setState(() {
        _message = 'Revisa tu correo para restablecer tu contraseña.';
      });
    } catch (error) {
      setState(() {
        _message = error.toString();
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
      title: 'Recuperar contraseña',
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextFieldGroup(label: 'Email', controller: _emailController, keyboardType: TextInputType.emailAddress),
            if (_message != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Text(_message!, style: const TextStyle(color: Colors.blueGrey)),
              ),
            PrimaryButton(label: 'Enviar', onPressed: _isLoading ? null : _submit, isLoading: _isLoading),
            TextButton(
              onPressed: () => context.go('/login'),
              child: const Text('Volver a login'),
            ),
          ],
        ),
      ),
    );
  }
}
