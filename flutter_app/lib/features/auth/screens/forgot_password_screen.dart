import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../services/providers.dart';

class ForgotPasswordScreen extends ConsumerStatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  ConsumerState<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends ConsumerState<ForgotPasswordScreen> {
  final emailController = TextEditingController();
  String? message;

  @override
  void dispose() {
    emailController.dispose();
    super.dispose();
  }

  Future<void> _sendReset() async {
    final auth = ref.read(firebaseAuthProvider);
    setState(() => message = null);
    try {
      await auth.sendPasswordResetEmail(email: emailController.text.trim());
      setState(() => message = 'Correo de recuperación enviado');
    } catch (err) {
      setState(() => message = err.toString());
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Recuperar contraseña')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: emailController,
              decoration: const InputDecoration(labelText: 'Email'),
            ),
            const SizedBox(height: 16),
            if (message != null) Text(message!),
            ElevatedButton(onPressed: _sendReset, child: const Text('Enviar')),
            TextButton(
              onPressed: () => context.go('/login'),
              child: const Text('Volver'),
            )
          ],
        ),
      ),
    );
  }
}
