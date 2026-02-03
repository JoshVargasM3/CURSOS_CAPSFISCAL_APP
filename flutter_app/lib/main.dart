import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_stripe/flutter_stripe.dart';
import 'core/app_config.dart';
import 'core/app_router.dart';
import 'services/firebase_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final config = AppConfig.fromEnvironment();
  await Firebase.initializeApp(options: buildFirebaseOptions(config.firebaseOptions));
  Stripe.publishableKey = config.stripePublishableKey;
  runApp(const ProviderScope(child: CapfiscalApp()));
}

class CapfiscalApp extends ConsumerWidget {
  const CapfiscalApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);
    return MaterialApp.router(
      title: 'CAPFISCAL',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.indigo),
        useMaterial3: true,
      ),
      routerConfig: router,
    );
  }
}
