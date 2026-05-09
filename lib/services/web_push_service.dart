import 'package:flutter/foundation.dart';

class WebPushService {
  Future<void> onUserSignedIn() async {
    debugPrint('Web push sign-in hook is not configured.');
  }

  Future<void> onUserSignedOut() async {
    debugPrint('Web push sign-out hook is not configured.');
  }
}
