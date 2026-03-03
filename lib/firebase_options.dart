// Not generated anymore: reads Firebase config from .env (flutter_dotenv).
// Secrets live in .env which is ignored by git.

import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;
import 'package:flutter_dotenv/flutter_dotenv.dart';

class DefaultFirebaseOptions {
  static String _req(String key) {
    final v = dotenv.env[key];
    if (v == null || v.isEmpty) {
      throw StateError('Missing env var: $key (set it in .env)');
    }
    return v;
  }

  static FirebaseOptions get currentPlatform {
    if (kIsWeb) return web;

    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      case TargetPlatform.windows:
        return windows;
      case TargetPlatform.macOS:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for macos.',
        );
      case TargetPlatform.linux:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for linux.',
        );
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not supported for this platform.',
        );
    }
  }

  static FirebaseOptions get web => FirebaseOptions(
    apiKey: _req('FIREBASE_WEB_API_KEY'),
    appId: _req('FIREBASE_WEB_APP_ID'),
    messagingSenderId: _req('FIREBASE_SENDER_ID'),
    projectId: _req('FIREBASE_PROJECT_ID'),
    authDomain: _req('FIREBASE_WEB_AUTH_DOMAIN'),
    storageBucket: _req('FIREBASE_STORAGE_BUCKET'),
    measurementId: _req('FIREBASE_WEB_MEASUREMENT_ID'),
  );

  static FirebaseOptions get android => FirebaseOptions(
    apiKey: _req('FIREBASE_ANDROID_API_KEY'),
    appId: _req('FIREBASE_ANDROID_APP_ID'),
    messagingSenderId: _req('FIREBASE_SENDER_ID'),
    projectId: _req('FIREBASE_PROJECT_ID'),
    storageBucket: _req('FIREBASE_STORAGE_BUCKET'),
  );

  static FirebaseOptions get ios => FirebaseOptions(
    apiKey: _req('FIREBASE_IOS_API_KEY'),
    appId: _req('FIREBASE_IOS_APP_ID'),
    messagingSenderId: _req('FIREBASE_SENDER_ID'),
    projectId: _req('FIREBASE_PROJECT_ID'),
    storageBucket: _req('FIREBASE_STORAGE_BUCKET'),
    iosBundleId: _req('FIREBASE_IOS_BUNDLE_ID'),
  );

  static FirebaseOptions get windows => FirebaseOptions(
    apiKey: _req('FIREBASE_WINDOWS_API_KEY'),
    appId: _req('FIREBASE_WINDOWS_APP_ID'),
    messagingSenderId: _req('FIREBASE_SENDER_ID'),
    projectId: _req('FIREBASE_PROJECT_ID'),
    authDomain: _req('FIREBASE_WINDOWS_AUTH_DOMAIN'),
    storageBucket: _req('FIREBASE_STORAGE_BUCKET'),
    measurementId: _req('FIREBASE_WINDOWS_MEASUREMENT_ID'),
  );
}