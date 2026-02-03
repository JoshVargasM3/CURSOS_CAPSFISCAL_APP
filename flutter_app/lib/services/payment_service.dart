import 'package:firebase_functions/firebase_functions.dart';
import 'package:flutter_stripe/flutter_stripe.dart';

class PaymentService {
  PaymentService({required this.functions});

  final FirebaseFunctions functions;

  Future<void> payFullCourse({required String courseId}) async {
    final callable = functions.httpsCallable('createPaymentIntentFull');
    final result = await callable.call({ 'courseId': courseId });
    final clientSecret = result.data['clientSecret'] as String;

    await Stripe.instance.initPaymentSheet(
      paymentSheetParameters: SetupPaymentSheetParameters(
        paymentIntentClientSecret: clientSecret,
        style: ThemeMode.system,
        merchantDisplayName: 'CAPFISCAL',
      ),
    );
    await Stripe.instance.presentPaymentSheet();
  }

  Future<void> paySessions({required String courseId, required List<String> sessionIds}) async {
    final callable = functions.httpsCallable('createPaymentIntentSessions');
    final result = await callable.call({ 'courseId': courseId, 'sessionIds': sessionIds });
    final clientSecret = result.data['clientSecret'] as String;

    await Stripe.instance.initPaymentSheet(
      paymentSheetParameters: SetupPaymentSheetParameters(
        paymentIntentClientSecret: clientSecret,
        style: ThemeMode.system,
        merchantDisplayName: 'CAPFISCAL',
      ),
    );
    await Stripe.instance.presentPaymentSheet();
  }
}
