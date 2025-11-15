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
      case TargetPlatform.macOS:
        return macos;
      case TargetPlatform.windows:
        return windows;
      case TargetPlatform.linux:
        throw UnsupportedError(_missingConfigMessage);
      default:
        throw UnsupportedError('DefaultFirebaseOptions is not supported for this platform.');
    }
  }

  static const String _missingConfigMessage =
      'DefaultFirebaseOptions have not been configured. Run flutterfire configure to generate firebase_options.dart.';

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyDQ3b20KDU8Zb_ZBuQ35kFqTAn2Mmmgq24',
    appId: '1:36053652354:web:90b94216769a9acba4359b',
    messagingSenderId: '36053652354',
    projectId: 'maxdiagnostico-b67c1',
    authDomain: 'maxdiagnostico-b67c1.firebaseapp.com',
    storageBucket: 'maxdiagnostico-b67c1.firebasestorage.app',
    measurementId: 'G-CV8NQG31SF',
  );

  static const FirebaseOptions macos = FirebaseOptions(
    apiKey: 'AIzaSyDTRpONJngYTZJyvSbh1FuEB5f5gIudxZ0',
    appId: '1:36053652354:ios:75fd8184605fd95ba4359b',
    messagingSenderId: '36053652354',
    projectId: 'maxdiagnostico-b67c1',
    storageBucket: 'maxdiagnostico-b67c1.firebasestorage.app',
    iosClientId: '36053652354-528b5imr2qnseqk90kkvbu2hinr5qufp.apps.googleusercontent.com',
    iosBundleId: 'com.example.maxtDiagnostic',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyDTRpONJngYTZJyvSbh1FuEB5f5gIudxZ0',
    appId: '1:36053652354:ios:7f05e163442d0478a4359b',
    messagingSenderId: '36053652354',
    projectId: 'maxdiagnostico-b67c1',
    storageBucket: 'maxdiagnostico-b67c1.firebasestorage.app',
    iosClientId: '36053652354-suq9iunlten5drm0beql4v0i8pjqf616.apps.googleusercontent.com',
    iosBundleId: 'br.com.yagoborba.maxtDiagnostic',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyAiZHSeN6eLkiG7FufohBhXWC83OofKNEU',
    appId: '1:36053652354:android:bf30fcbfb4d2fd02a4359b',
    messagingSenderId: '36053652354',
    projectId: 'maxdiagnostico-b67c1',
    storageBucket: 'maxdiagnostico-b67c1.firebasestorage.app',
  );

  static const FirebaseOptions windows = FirebaseOptions(
    apiKey: 'AIzaSyDQ3b20KDU8Zb_ZBuQ35kFqTAn2Mmmgq24',
    appId: '1:36053652354:web:941e77593ea1fb13a4359b',
    messagingSenderId: '36053652354',
    projectId: 'maxdiagnostico-b67c1',
    authDomain: 'maxdiagnostico-b67c1.firebaseapp.com',
    storageBucket: 'maxdiagnostico-b67c1.firebasestorage.app',
    measurementId: 'G-7VXTNYMGX0',
  );

}