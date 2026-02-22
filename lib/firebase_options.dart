// File generated from firebase.json / FlutterFire config.
// Project: littermate-f0eb9

import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

/// Default [FirebaseOptions] for use with your Firebase apps.
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
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for linux - '
          'you can reconfigure this by running the FlutterFire CLI again.',
        );
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not supported for this platform.',
        );
    }
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyBGTbYfwJaZovfFCgky_0pygFW1jvS558U',
    appId: '1:871797340538:web:83602a955a3d809c167ec3',
    messagingSenderId: '871797340538',
    projectId: 'littermate-f0eb9',
    authDomain: 'littermate-f0eb9.firebaseapp.com',
    storageBucket: 'littermate-f0eb9.firebasestorage.app',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyBGTbYfwJaZovfFCgky_0pygFW1jvS558U',
    appId: '1:871797340538:android:315a4706be868526167ec3',
    messagingSenderId: '871797340538',
    projectId: 'littermate-f0eb9',
    storageBucket: 'littermate-f0eb9.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyBGTbYfwJaZovfFCgky_0pygFW1jvS558U',
    appId: '1:871797340538:ios:1b756e8b4f00577a167ec3',
    messagingSenderId: '871797340538',
    projectId: 'littermate-f0eb9',
    storageBucket: 'littermate-f0eb9.firebasestorage.app',
    iosBundleId: 'com.breedly.app',
  );

  static const FirebaseOptions macos = FirebaseOptions(
    apiKey: 'AIzaSyBGTbYfwJaZovfFCgky_0pygFW1jvS558U',
    appId: '1:871797340538:ios:472ec66533b63cc8167ec3',
    messagingSenderId: '871797340538',
    projectId: 'littermate-f0eb9',
    storageBucket: 'littermate-f0eb9.firebasestorage.app',
    iosBundleId: 'com.breedly.app',
  );

  static const FirebaseOptions windows = FirebaseOptions(
    apiKey: 'AIzaSyBGTbYfwJaZovfFCgky_0pygFW1jvS558U',
    appId: '1:871797340538:web:e2e937586860237a167ec3',
    messagingSenderId: '871797340538',
    projectId: 'littermate-f0eb9',
    authDomain: 'littermate-f0eb9.firebaseapp.com',
    storageBucket: 'littermate-f0eb9.firebasestorage.app',
  );
}
