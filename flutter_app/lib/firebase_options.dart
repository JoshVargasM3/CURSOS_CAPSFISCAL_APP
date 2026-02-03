import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart' show defaultTargetPlatform, kIsWeb, TargetPlatform;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      throw UnsupportedError(_errorMessage('web'));
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        throw UnsupportedError(_errorMessage('android'));
      case TargetPlatform.iOS:
        throw UnsupportedError(_errorMessage('ios'));
      case TargetPlatform.macOS:
        throw UnsupportedError(_errorMessage('macos'));
      case TargetPlatform.windows:
        throw UnsupportedError(_errorMessage('windows'));
      case TargetPlatform.linux:
        throw UnsupportedError(_errorMessage('linux'));
      case TargetPlatform.fuchsia:
        throw UnsupportedError(_errorMessage('fuchsia'));
    }
  }

  static String _errorMessage(String platform) {
    return 'Missing firebase_options.dart for $platform. Run "flutterfire configure --project=capfiscal-app-cursos-dev --platforms=android,ios --android-package-name=com.capfiscal.cursos --ios-bundle-id=com.capfiscal.cursos" and re-run the app.';
  }
}
