import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

class FirebaseEnvironment {
  static const String name = String.fromEnvironment(
    'APP_ENV',
    defaultValue: 'dev',
  );

  static bool get isProduction => name == 'prod';

  static String get envFile => isProduction ? '.env.prod' : '.env.dev';

  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      return isProduction ? _prodWeb : _devWeb;
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return isProduction ? _prodAndroid : _devAndroid;
      case TargetPlatform.iOS:
        return isProduction ? _prodIos : _devIos;
      default:
        throw UnsupportedError(
          'Firebase is not configured for this platform.',
        );
    }
  }

  static const FirebaseOptions _devAndroid = FirebaseOptions(
    apiKey: 'AIzaSyCKF0hkCPR2nhUfv_CsgZFsnWcx7hjkep4',
    appId: '1:401854471349:android:a4c4ddc4dbe5319585f2fc',
    messagingSenderId: '401854471349',
    projectId: 'cherry-mvp',
    storageBucket: 'cherry-mvp.firebasestorage.app',
  );

  static const FirebaseOptions _prodAndroid = FirebaseOptions(
    apiKey: 'AIzaSyD63LTq2uUSKad-owUwZ97RFsITuADvRE4',
    appId: '1:166746898861:android:7393858dd30a6241aca124',
    messagingSenderId: '166746898861',
    projectId: 'cherry-prod-d513e',
    storageBucket: 'cherry-prod-d513e.firebasestorage.app',
  );

  static const FirebaseOptions _devIos = FirebaseOptions(
    apiKey: 'AIzaSyB9jkZAhIsFB-7pmtJT-x3kw7ZLBUxOuHQ',
    appId: '1:401854471349:ios:6f29a0fb34d26a3b85f2fc',
    messagingSenderId: '401854471349',
    projectId: 'cherry-mvp',
    storageBucket: 'cherry-mvp.firebasestorage.app',
    iosBundleId: 'uk.org.cherry.app',
  );

  static const FirebaseOptions _prodIos = FirebaseOptions(
    apiKey: 'AIzaSyCYS8PH6o0UKLS6WANHYtRqH_A8ggpBAjQ',
    appId: '1:166746898861:ios:8541f0745ba3efcbaca124',
    messagingSenderId: '166746898861',
    projectId: 'cherry-prod-d513e',
    storageBucket: 'cherry-prod-d513e.firebasestorage.app',
    iosBundleId: 'uk.org.cherry.app',
  );

  static const FirebaseOptions _devWeb = FirebaseOptions(
    apiKey: 'AIzaSyBMgSlx4VI9Fizft4LzWSohYt09k_UtCdM',
    appId: '1:401854471349:web:9b9538f1c44b2d1e85f2fc',
    messagingSenderId: '401854471349',
    projectId: 'cherry-mvp',
    storageBucket: 'cherry-mvp.firebasestorage.app',
    authDomain: 'cherry-mvp.firebaseapp.com',
  );

  static const FirebaseOptions _prodWeb = FirebaseOptions(
    apiKey: 'AIzaSyDQA9q1qLUtyT4y6FuuuD7imVzuF297cc',
    appId: '1:166746898861:web:b11f630e263e17b3aca124',
    messagingSenderId: '166746898861',
    projectId: 'cherry-prod-d513e',
    storageBucket: 'cherry-prod-d513e.firebasestorage.app',
    authDomain: 'cherry-prod-d513e.firebaseapp.com',
  );
}
