import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../models/course.dart';
import '../../../services/admin_service.dart';
import '../../../services/firebase_service.dart';
import '../../../widgets/app_scaffold.dart';
import '../../../widgets/form_fields.dart';
import '../../../widgets/primary_button.dart';

class CourseEditScreen extends ConsumerStatefulWidget {
  const CourseEditScreen({super.key, this.courseId});

  final String? courseId;

  @override
  ConsumerState<CourseEditScreen> createState() => _CourseEditScreenState();
}

class _CourseEditScreenState extends ConsumerState<CourseEditScreen> {
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _stateController = TextEditingController();
  final _sedeController = TextEditingController();
  final _startDateController = TextEditingController();
  final _endDateController = TextEditingController();
  final _priceController = TextEditingController();
  String _paymentModeAllowed = 'both';
  bool _isActive = true;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    if (widget.courseId != null) {
      _load();
    }
  }

  Future<void> _load() async {
    final db = ref.read(firebaseServiceProvider).db;
    final doc = await db.collection('courses').doc(widget.courseId).get();
    if (doc.exists) {
      final data = doc.data() ?? {};
      setState(() {
        _titleController.text = data['title'] as String? ?? '';
        _descriptionController.text = data['description'] as String? ?? '';
        _stateController.text = data['stateId'] as String? ?? '';
        _sedeController.text = data['sedeId'] as String? ?? '';
        _startDateController.text = data['startDate'] as String? ?? '';
        _endDateController.text = data['endDate'] as String? ?? '';
        _priceController.text = (data['priceFull'] ?? '').toString();
        _paymentModeAllowed = data['paymentModeAllowed'] as String? ?? 'both';
        _isActive = data['isActive'] as bool? ?? true;
      });
    }
  }

  Future<void> _save() async {
    setState(() {
      _isLoading = true;
    });
    final id = widget.courseId ?? ref.read(firebaseServiceProvider).db.collection('courses').doc().id;
    final course = Course(
      id: id,
      title: _titleController.text.trim(),
      description: _descriptionController.text.trim(),
      stateId: _stateController.text.trim(),
      sedeId: _sedeController.text.trim(),
      startDate: _startDateController.text.trim(),
      endDate: _endDateController.text.trim(),
      priceFull: double.tryParse(_priceController.text) ?? 0,
      paymentModeAllowed: _paymentModeAllowed,
      isActive: _isActive,
    );

    await ref.read(adminServiceProvider).saveCourse(course);
    if (mounted) {
      context.go('/admin');
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: widget.courseId == null ? 'Nuevo curso' : 'Editar curso',
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          TextFieldGroup(label: 'Título', controller: _titleController),
          TextFieldGroup(label: 'Descripción', controller: _descriptionController),
          TextFieldGroup(label: 'Estado (stateId)', controller: _stateController),
          TextFieldGroup(label: 'Sede (sedeId)', controller: _sedeController),
          TextFieldGroup(label: 'Fecha inicio (YYYY-MM-DD)', controller: _startDateController),
          TextFieldGroup(label: 'Fecha fin (YYYY-MM-DD)', controller: _endDateController),
          TextFieldGroup(
            label: 'Precio completo',
            controller: _priceController,
            keyboardType: TextInputType.number,
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            value: _paymentModeAllowed,
            decoration: const InputDecoration(labelText: 'Modo de pago', border: OutlineInputBorder()),
            items: const [
              DropdownMenuItem(value: 'full_only', child: Text('Solo curso completo')),
              DropdownMenuItem(value: 'per_session_only', child: Text('Solo sesiones')),
              DropdownMenuItem(value: 'both', child: Text('Ambos')),
            ],
            onChanged: (value) {
              setState(() {
                _paymentModeAllowed = value ?? 'both';
              });
            },
          ),
          SwitchListTile(
            value: _isActive,
            onChanged: (value) => setState(() => _isActive = value),
            title: const Text('Activo'),
          ),
          PrimaryButton(label: 'Guardar', onPressed: _isLoading ? null : _save, isLoading: _isLoading),
          if (widget.courseId != null)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: ElevatedButton(
                onPressed: () => context.go('/admin/courses/${widget.courseId}/sessions/new'),
                child: const Text('Agregar sesión'),
              ),
            ),
        ],
      ),
    );
  }
}
