import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';

String deviceTokenPlatform() {
  if (kIsWeb) {
    return 'web';
  }
  if (Platform.isIOS) {
    return 'ios';
  }
  return 'android';
}
