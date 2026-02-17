import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      return web;
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not supported for this platform.',
        );
    }
  }

  // Web config
  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyBo7c8F5brDOKa0YjGDGwBX8PKl3MNKnf0',
    appId: '1:97858231380:web:80e16278020b29b28b21c1',
    messagingSenderId: '97858231380',
    projectId: 'smartexpense-25de0',
    authDomain: 'smartexpense-25de0.firebaseapp.com',
    storageBucket: 'smartexpense-25de0.firebasestorage.app',
  );

  // Android config (from google-services.json)
  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyB697hZW-77T3H_4LhtNHxTF_nE9ooTC04',
    appId: '1:97858231380:android:0a7b22c55023cf2e8b21c1',
    messagingSenderId: '97858231380',
    projectId: 'smartexpense-25de0',
    storageBucket: 'smartexpense-25de0.firebasestorage.app',
  );

  // iOS config (same project, update appId when you add iOS app)
  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyBo7c8F5brDOKa0YjGDGwBX8PKl3MNKnf0',
    appId: '1:97858231380:web:80e16278020b29b28b21c1',
    messagingSenderId: '97858231380',
    projectId: 'smartexpense-25de0',
    storageBucket: 'smartexpense-25de0.firebasestorage.app',
    iosBundleId: 'com.example.smartexpense',
  );
}