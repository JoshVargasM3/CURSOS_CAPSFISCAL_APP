import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../../../services/providers.dart';
import '../../../services/qr_service.dart';

class CourseQrScreen extends ConsumerStatefulWidget {
  const CourseQrScreen({super.key, required this.courseId});

  final String courseId;

  @override
  ConsumerState<CourseQrScreen> createState() => _CourseQrScreenState();
}

class _CourseQrScreenState extends ConsumerState<CourseQrScreen> {
  String? token;
  String? message;

  Future<void> _generate() async {
    setState(() => message = null);
    try {
      final service = QrService(ref.read(functionsProvider));
      final result = await service.issueCourseQrToken(widget.courseId);
      setState(() {
        token = result['token'] as String;
      });
    } catch (err) {
      setState(() => message = err.toString());
    }
  }

  @override
  void initState() {
    super.initState();
    _generate();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Mi QR del curso')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (token != null) QrImageView(data: token!, size: 240),
              if (message != null) Text(message!),
              const SizedBox(height: 12),
              ElevatedButton(onPressed: _generate, child: const Text('Regenerar QR')),
              const SizedBox(height: 8),
              const Text('El QR no contiene datos personales.'),
            ],
          ),
        ),
      ),
    );
  }
}
