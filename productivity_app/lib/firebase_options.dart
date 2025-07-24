// File generated manually with Android + Web Firebase config
// ignore_for_file: type=lint
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
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for iOS.',
        );
      case TargetPlatform.macOS:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for macOS.',
        );
      case TargetPlatform.windows:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for Windows.',
        );
      case TargetPlatform.linux:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for Linux.',
        );
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not supported for this platform.',
        );
    }
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyCLYf-smrmEpFjtuKWqcWLWNahpwU2-7YY',
    authDomain: 'productivity-app-c9c23.firebaseapp.com',
    projectId: 'productivity-app-c9c23',
    storageBucket: 'productivity-app-c9c23.firebasestorage.app',
    messagingSenderId: '825770877454',
    appId: '1:825770877454:web:0869657145bc51d7f0925f',
    measurementId: 'G-N5ZEXN1DW1',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyBgjfRJBH1veGuFPDHDAY4w4h0938dD97A',
    appId: '1:825770877454:android:2da27b28613462e1f0925f',
    messagingSenderId: '825770877454',
    projectId: 'productivity-app-c9c23',
    storageBucket: 'productivity-app-c9c23.firebasestorage.app',
  );
}
