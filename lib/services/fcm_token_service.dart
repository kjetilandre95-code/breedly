class FcmTokenService {
  static final FcmTokenService _instance = FcmTokenService._internal();

  factory FcmTokenService() => _instance;

  FcmTokenService._internal();

  Future<void> onUserSignedIn() async {}

  Future<void> onUserSignedOut() async {}
}
