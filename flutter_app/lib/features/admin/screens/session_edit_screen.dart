import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../models/session.dart';
import '../../../services/admin_service.dart';
import '../../../services/firebase_service.dart';
import '../../../widgets/app_scaffold.dart';
import '../../../widgets/form_fields.dart';
import '../../../widgets/primary_button.dart';

class SessionEditScreen extends ConsumerStatefulWidget {
  const SessionEditScreen({super.key, required this.courseId, this.sessionId});

  final String courseId;
  final String? sessionId;

  @override
  ConsumerState<SessionEditScreen> createState() => _SessionEditScreenState();
}

class _SessionEditScreenState extends ConsumerState<SessionEditScreen> {
  final _titleController = TextEditingController();
  final _dateController = TextEditingController();
  final _priceController = TextEditingController();
  bool _isActive = true;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    if (widget.sessionId != null) {
      _load();
    }
  }

  Future<void> _load() async {
    final db = ref.read(firebaseServiceProvider).db;
    final doc = await db
        .collection('courses')
        .doc(widget.courseId)
        .collection('sessions')
        .doc(widget.sessionId)
        .get();
    if (doc.exists) {
      final data = doc.data() ?? {};
      setState(() {
        _titleController.text = data['title'] as String? ?? '';
        _dateController.text = data['dateTime'] as String? ?? '';
        _priceController.text = (data['price'] ?? '').toString();
        _isActive = data['isActive'] as bool? ?? true;
      });
    }
  }

  Future<void> _save() async {
    setState(() {
      _isLoading = true;
    });
    final id = widget.sessionId ??
        ref.read(firebaseServiceProvider).db.collection('courses').doc(widget.courseId).collection('sessions').doc().id;
    final session = Session(
      id: id,
      title: _titleController.text.trim(),
      dateTime: _dateController.text.trim(),
      price: double.tryParse(_priceController.text) ?? 0,
      isActive: _isActive,
    );

    await ref.read(adminServiceProvider).saveSession(widget.courseId, session);
    if (mounted) {
      context.go('/admin');
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: widget.sessionId == null ? 'Nueva sesión' : 'Editar sesión',
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          TextFieldGroup(label: 'Título', controller: _titleController),
          TextFieldGroup(label: 'Fecha/hora (ISO)', controller: _dateController),
          TextFieldGroup(
            label: 'Precio',
            controller: _priceController,
            keyboardType: TextInputType.number,
          ),
          SwitchListTile(
            value: _isActive,
            onChanged: (value) => setState(() => _isActive = value),
            title: const Text('Activo'),
          ),
          PrimaryButton(label: 'Guardar', onPressed: _isLoading ? null : _save, isLoading: _isLoading),
        ],
      ),
    );
  }
}
