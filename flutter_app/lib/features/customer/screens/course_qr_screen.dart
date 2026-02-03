import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../../../services/qr_service.dart';
import '../../../widgets/app_scaffold.dart';
import '../../../widgets/primary_button.dart';

class CourseQrScreen extends ConsumerStatefulWidget {
  const CourseQrScreen({super.key, required this.courseId});

  final String courseId;

  @override
  ConsumerState<CourseQrScreen> createState() => _CourseQrScreenState();
}

class _CourseQrScreenState extends ConsumerState<CourseQrScreen> {
  String? _token;
  int? _exp;
  bool _isLoading = false;
  String? _error;

  Future<void> _load() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final data = await ref.read(qrServiceProvider).issueCourseQrToken(widget.courseId);
      setState(() {
        _token = data['token'] as String?;
        _exp = data['exp'] as int?;
      });
    } catch (error) {
      setState(() {
        _error = error.toString();
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: 'Mi QR',
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (_token != null)
                QrImageView(
                  data: _token!,
                  size: 240,
                ),
              if (_exp != null)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text('Expira: ${DateTime.fromMillisecondsSinceEpoch(_exp! * 1000)}'),
                ),
              if (_error != null)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(_error!, style: const TextStyle(color: Colors.red)),
                ),
              const SizedBox(height: 16),
              PrimaryButton(label: 'Actualizar QR', onPressed: _isLoading ? null : _load, isLoading: _isLoading),
            ],
          ),
        ),
      ),
    );
  }
}
