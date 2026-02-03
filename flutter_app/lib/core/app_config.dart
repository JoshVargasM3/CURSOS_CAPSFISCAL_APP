class AppConfig {
  final String environment;
  final String functionsRegion;
  final String stripePublishableKey;

  const AppConfig({
    required this.environment,
    required this.functionsRegion,
    required this.stripePublishableKey,
  });

  factory AppConfig.fromEnvironment() {
    const environment = String.fromEnvironment('APP_CONFIG', defaultValue: 'dev');
    const functionsRegion =
        String.fromEnvironment('FUNCTIONS_REGION', defaultValue: 'us-central1');
    const stripePublishableKey =
        String.fromEnvironment('STRIPE_PUBLISHABLE_KEY', defaultValue: '');
    return const AppConfig(
      environment: environment,
      functionsRegion: functionsRegion,
      stripePublishableKey: stripePublishableKey,
    );
  }
}
