import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart' show defaultTargetPlatform, kIsWeb, TargetPlatform;

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

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyCKF0hkCPR2nhUfv_CsgZFsnWcx7hjkep4',
    appId: '1:401854471349:web:9b9538f1c44b2d1e85f2fc',
    messagingSenderId: '401854471349',
    projectId: 'cherry-mvp',
    authDomain: 'cherry-mvp.firebaseapp.com',
    storageBucket: 'cherry-mvp.firebasestorage.app',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyCKF0hkCPR2nhUfv_CsgZFsnWcx7hjkep4',
    appId: '1:401854471349:android:8cff1aa597379a8c85f2fc',
    messagingSenderId: '401854471349',
    projectId: 'cherry-mvp',
    storageBucket: 'cherry-mvp.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyB9jkZAhIsFB-7pmtJT-x3kw7ZLBUxOuHQ',
    appId: '1:401854471349:ios:6f29a0fb34d26a3b85f2fc',
    messagingSenderId: '401854471349',
    projectId: 'cherry-mvp',
    storageBucket: 'cherry-mvp.firebasestorage.app',
    iosClientId: '401854471349-oh11bqm8vk5i5vo8m73mf037qn9lgkoh.apps.googleusercontent.com',
    iosBundleId: 'uk.org.cherry.app',
  );
}
