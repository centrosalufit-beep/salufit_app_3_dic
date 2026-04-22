import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// Detects if the app is running inside Firebase Test Lab (Android).
///
/// Used to trigger auto-login with the reviewer demo account so that
/// Robo tests can bypass the login screen — Flutter's TextEditingController
/// doesn't receive Robo's VIEW_TEXT_CHANGED events, so typed credentials
/// never reach the form validator.
class TestLabDetector {
  static const _channel = MethodChannel('com.salufit.app/test_lab');

  static Future<bool> isFirebaseTestLab() async {
    if (!Platform.isAndroid) return false;
    try {
      final result = await _channel.invokeMethod<bool>('isFirebaseTestLab');
      return result ?? false;
    } on PlatformException catch (e) {
      debugPrint('TestLabDetector error: $e');
      return false;
    }
  }
}
