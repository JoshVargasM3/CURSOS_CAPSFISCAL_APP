import 'dart:convert';

class AppConfig {
  final String functionsRegion;
  final String stripePublishableKey;
  final Map<String, dynamic> firebaseOptions;

  AppConfig({
    required this.functionsRegion,
    required this.stripePublishableKey,
    required this.firebaseOptions,
  });

  factory AppConfig.fromEnvironment() {
    const raw = String.fromEnvironment('APP_CONFIG');
    if (raw.isEmpty) {
      throw StateError('APP_CONFIG not provided');
    }
    final json = jsonDecode(raw) as Map<String, dynamic>;
    return AppConfig(
      functionsRegion: json['functionsRegion'] as String,
      stripePublishableKey: json['stripePublishableKey'] as String,
      firebaseOptions: json['firebaseOptions'] as Map<String, dynamic>,
    );
  }
}
