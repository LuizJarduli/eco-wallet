/// Obtains the device push token from the platform messaging SDK.
abstract class PushTokenService {
  Future<bool> requestPermission();

  Future<String?> getToken();
}
