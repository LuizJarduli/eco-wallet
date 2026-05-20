import 'package:eco_wallet/core/notifications/push_token_service.dart';

class NoOpPushTokenService implements PushTokenService {
  @override
  Future<bool> requestPermission() async => false;

  @override
  Future<String?> getToken() async => null;
}
