import 'package:eco_wallet/core/notifications/device_token_repository.dart';
import 'package:eco_wallet/core/notifications/push_token_service.dart';

class DeviceTokenRegistrar {
  DeviceTokenRegistrar({
    required PushTokenService pushTokenService,
    required DeviceTokenRepository deviceTokenRepository,
  }) : _pushTokenService = pushTokenService,
       _deviceTokenRepository = deviceTokenRepository;

  final PushTokenService _pushTokenService;
  final DeviceTokenRepository _deviceTokenRepository;

  Future<void> registerForUser(String userId) async {
    final granted = await _pushTokenService.requestPermission();
    if (!granted) {
      return;
    }

    final token = await _pushTokenService.getToken();
    if (token == null || token.isEmpty) {
      return;
    }

    await _deviceTokenRepository.upsertToken(userId: userId, token: token);
  }
}
