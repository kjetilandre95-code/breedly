class WebPushService {
  static final WebPushService _instance = WebPushService._internal();

  factory WebPushService() => _instance;

  WebPushService._internal();

  Future<void> onUserSignedIn() async {}

  Future<void> onUserSignedOut() async {}
}
