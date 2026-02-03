import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../../../services/qr_service.dart';
import '../../../widgets/app_scaffold.dart';
import '../../../widgets/result_card.dart';

class CheckerScanScreen extends ConsumerStatefulWidget {
  const CheckerScanScreen({super.key, required this.courseId, required this.sessionId});

  final String courseId;
  final String sessionId;

  @override
  ConsumerState<CheckerScanScreen> createState() => _CheckerScanScreenState();
}

class _CheckerScanScreenState extends ConsumerState<CheckerScanScreen> {
  bool _isProcessing = false;
  Map<String, dynamic>? _result;

  Future<void> _handleToken(String token) async {
    if (_isProcessing) return;
    setState(() {
      _isProcessing = true;
    });
    try {
      final data = await ref.read(qrServiceProvider).validateQrToken(
            token: token,
            sessionId: widget.sessionId,
          );
      setState(() {
        _result = data;
      });
    } catch (error) {
      setState(() {
        _result = {
          'allowed': false,
          'reason': error.toString(),
        };
      });
    } finally {
      setState(() {
        _isProcessing = false;
      });
    }
  }

  String _reasonToSpanish(String? reason) {
    switch (reason) {
      case 'TOKEN_EXPIRED':
        return 'Token expirado.';
      case 'INVALID_TOKEN':
        return 'Token inválido.';
      case 'NOT_ENROLLED':
        return 'No inscrito.';
      case 'COURSE_INACTIVE':
        return 'Curso inactivo.';
      case 'PAYMENT_REQUIRED':
        return 'Pago requerido.';
      case 'SESSION_NOT_PAID':
        return 'Sesión no pagada.';
      case 'ALREADY_CHECKED_IN':
        return 'Ya registró asistencia.';
      default:
        return reason ?? 'Sin detalle';
    }
  }

  @override
  Widget build(BuildContext context) {
    final allowed = _result?['allowed'] == true;
    final reason = _result?['reason'] as String?;

    return AppScaffold(
      title: 'Escaneo de QR',
      body: Column(
        children: [
          Expanded(
            child: MobileScanner(
              onDetect: (capture) {
                final token = capture.barcodes.first.rawValue;
                if (token != null) {
                  _handleToken(token);
                }
              },
            ),
          ),
          if (_result != null)
            Padding(
              padding: const EdgeInsets.all(16),
              child: ResultCard(
                title: allowed ? 'Acceso permitido' : 'Acceso denegado',
                message: allowed ? 'Check-in registrado.' : _reasonToSpanish(reason),
                isSuccess: allowed,
              ),
            ),
        ],
      ),
    );
  }
}
