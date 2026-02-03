import 'package:flutter_stripe/flutter_stripe.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'firebase_service.dart';

class PaymentService {
  PaymentService(this._service);

  final FirebaseService _service;

  Future<void> payFull({required String courseId}) async {
    final callable = _service.functions.httpsCallable('createPaymentIntentFull');
    final result = await callable.call({
      'courseId': courseId,
    });
    final clientSecret = result.data['clientSecret'] as String?;
    if (clientSecret == null) {
      throw StateError('Missing client secret');
    }

    await Stripe.instance.initPaymentSheet(
      paymentSheetParameters: SetupPaymentSheetParameters(
        paymentIntentClientSecret: clientSecret,
        merchantDisplayName: 'CAPFISCAL',
      ),
    );

    await Stripe.instance.presentPaymentSheet();
  }

  Future<void> paySessions({required String courseId, required List<String> sessionIds}) async {
    final callable = _service.functions.httpsCallable('createPaymentIntentSessions');
    final result = await callable.call({
      'courseId': courseId,
      'sessionIds': sessionIds,
    });
    final clientSecret = result.data['clientSecret'] as String?;
    if (clientSecret == null) {
      throw StateError('Missing client secret');
    }

    await Stripe.instance.initPaymentSheet(
      paymentSheetParameters: SetupPaymentSheetParameters(
        paymentIntentClientSecret: clientSecret,
        merchantDisplayName: 'CAPFISCAL',
      ),
    );

    await Stripe.instance.presentPaymentSheet();
  }
}

final paymentServiceProvider = Provider<PaymentService>((ref) {
  final firebase = ref.read(firebaseServiceProvider);
  return PaymentService(firebase);
});
