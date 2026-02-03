import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../../../services/providers.dart';
import '../../../services/qr_service.dart';

class CheckerScreen extends ConsumerStatefulWidget {
  const CheckerScreen({super.key});

  @override
  ConsumerState<CheckerScreen> createState() => _CheckerScreenState();
}

class _CheckerScreenState extends ConsumerState<CheckerScreen> {
  String? selectedCourseId;
  String? selectedSessionId;
  Map<String, dynamic>? result;
  bool isProcessing = false;

  Future<void> _handleScan(String token) async {
    if (selectedCourseId == null || selectedSessionId == null || isProcessing) {
      return;
    }
    setState(() => isProcessing = true);
    final service = QrService(ref.read(functionsProvider));
    try {
      final data = await service.validateCourseQrToken(
        token: token,
        sessionId: selectedSessionId,
      );
      setState(() => result = data);
    } catch (err) {
      setState(() => result = { 'allowed': false, 'reason': 'INVALID_TOKEN' });
    } finally {
      setState(() => isProcessing = false);
    }
  }

  String _reasonLabel(String? reason) {
    switch (reason) {
      case 'TOKEN_EXPIRED':
        return 'Token expirado';
      case 'INVALID_TOKEN':
        return 'QR inválido';
      case 'NOT_ENROLLED':
        return 'No inscrito';
      case 'COURSE_INACTIVE':
        return 'Curso inactivo';
      case 'PAYMENT_REQUIRED':
        return 'Pago requerido';
      case 'SESSION_NOT_PAID':
        return 'Sesión no pagada';
      case 'ALREADY_CHECKED_IN':
        return 'Ya registrado';
      default:
        return 'Acceso permitido';
    }
  }

  @override
  Widget build(BuildContext context) {
    final firestore = ref.watch(firestoreProvider);
    final allowed = result?['allowed'] == true;
    final reason = result?['reason'] as String?;
    final cardColor = allowed ? Colors.green.shade100 : Colors.red.shade100;
    return Scaffold(
      appBar: AppBar(title: const Text('Check-in')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                  stream: firestore.collection('courses').where('isActive', isEqualTo: true).snapshots(),
                  builder: (context, snapshot) {
                    final docs = snapshot.data?.docs ?? [];
                    return DropdownButtonFormField<String>(
                      value: selectedCourseId,
                      decoration: const InputDecoration(labelText: 'Curso'),
                      items: docs
                          .map((doc) => DropdownMenuItem(
                                value: doc.id,
                                child: Text(doc.data()['title'] as String? ?? doc.id),
                              ))
                          .toList(),
                      onChanged: (value) {
                        setState(() {
                          selectedCourseId = value;
                          selectedSessionId = null;
                        });
                      },
                    );
                  },
                ),
                const SizedBox(height: 12),
                if (selectedCourseId != null)
                  StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                    stream: firestore.collection('courses/$selectedCourseId/sessions').where('isActive', isEqualTo: true).snapshots(),
                    builder: (context, snapshot) {
                      final docs = snapshot.data?.docs ?? [];
                      return DropdownButtonFormField<String>(
                        value: selectedSessionId,
                        decoration: const InputDecoration(labelText: 'Sesión'),
                        items: docs
                            .map((doc) => DropdownMenuItem(
                                  value: doc.id,
                                  child: Text(doc.data()['title'] as String? ?? doc.id),
                                ))
                            .toList(),
                        onChanged: (value) => setState(() => selectedSessionId = value),
                      );
                    },
                  ),
              ],
            ),
          ),
          Expanded(
            child: MobileScanner(
              onDetect: (capture) {
                final barcode = capture.barcodes.first;
                final raw = barcode.rawValue;
                if (raw != null) {
                  _handleScan(raw);
                }
              },
            ),
          ),
          if (result != null)
            Padding(
              padding: const EdgeInsets.all(16),
              child: Card(
                color: cardColor,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        allowed ? 'ACCESO PERMITIDO' : 'ACCESO DENEGADO',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 8),
                      Text(_reasonLabel(reason)),
                      if (result?['userDisplay'] != null) ...[
                        const SizedBox(height: 8),
                        Text('Nombre: ${result?['userDisplay']['fullName']}'),
                        Text('Email: ${result?['userDisplay']['email']}'),
                        Text('Teléfono: ${result?['userDisplay']['phone']}'),
                      ]
                    ],
                  ),
                ),
              ),
            )
        ],
      ),
    );
  }
}
