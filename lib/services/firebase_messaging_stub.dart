class RemoteMessage {
  const RemoteMessage();
}

typedef BackgroundMessageHandler = Future<void> Function(RemoteMessage message);

class FirebaseMessaging {
  static void onBackgroundMessage(BackgroundMessageHandler handler) {}
}
