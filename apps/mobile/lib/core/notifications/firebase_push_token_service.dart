import 'package:firebase_messaging/firebase_messaging.dart';

import 'package:eco_wallet/core/notifications/push_token_service.dart';

class FirebasePushTokenService implements PushTokenService {
  FirebasePushTokenService({FirebaseMessaging? messaging})
    : _messaging = messaging ?? FirebaseMessaging.instance;

  final FirebaseMessaging _messaging;

  @override
  Future<bool> requestPermission() async {
    final settings = await _messaging.requestPermission();
    final status = settings.authorizationStatus;

    return status == AuthorizationStatus.authorized ||
        status == AuthorizationStatus.provisional;
  }

  @override
  Future<String?> getToken() => _messaging.getToken();
}
