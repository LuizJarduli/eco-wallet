import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:eco_wallet/core/notifications/device_platform.dart';

class DeviceTokenRepository {
  DeviceTokenRepository({SupabaseClient? client})
    : _client = client ?? Supabase.instance.client;

  final SupabaseClient _client;

  Future<void> upsertToken({
    required String userId,
    required String token,
    String? platform,
  }) async {
    await _client.from('device_tokens').upsert(
      {
        'user_id': userId,
        'platform': platform ?? deviceTokenPlatform(),
        'token': token,
      },
      onConflict: 'user_id,token',
    );
  }
}
