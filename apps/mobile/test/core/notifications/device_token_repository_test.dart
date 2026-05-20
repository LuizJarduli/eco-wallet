import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:eco_wallet/core/notifications/device_token_repository.dart';

class _RecordingQueryBuilder implements SupabaseQueryBuilder {
  _RecordingQueryBuilder(this.onUpsert);

  final void Function(Map<String, dynamic> values, String? onConflict) onUpsert;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);

  @override
  PostgrestFilterBuilder<List<Map<String, dynamic>>> upsert(
    Object values, {
    String? onConflict,
    bool ignoreDuplicates = false,
    bool defaultToNull = true,
  }) {
    onUpsert(
      Map<String, dynamic>.from(values as Map),
      onConflict,
    );
    return _ImmediateFilterBuilder();
  }
}

class _ImmediateFilterBuilder
    implements PostgrestFilterBuilder<List<Map<String, dynamic>>> {
  @override
  Future<R> then<R>(
    FutureOr<R> Function(List<Map<String, dynamic>> value) onValue, {
    Function? onError,
  }) {
    return Future.value(<Map<String, dynamic>>[]).then(onValue);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => this;
}

class _RecordingSupabaseClient implements SupabaseClient {
  _RecordingSupabaseClient(this.queryBuilder);

  final SupabaseQueryBuilder queryBuilder;

  @override
  SupabaseQueryBuilder from(String table) {
    expect(table, 'device_tokens');
    return queryBuilder;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  test('upsert sends user, platform, and token with conflict target', () async {
    Map<String, dynamic>? captured;
    String? conflict;

    final client = _RecordingSupabaseClient(
      _RecordingQueryBuilder((values, onConflict) {
        captured = values;
        conflict = onConflict;
      }),
    );
    final repository = DeviceTokenRepository(client: client);

    await repository.upsertToken(
      userId: 'user-1',
      token: 'fcm-token',
      platform: 'android',
    );

    expect(captured, {
      'user_id': 'user-1',
      'platform': 'android',
      'token': 'fcm-token',
    });
    expect(conflict, 'user_id,token');
  });

  test('re-upserting the same token updates platform for the user', () async {
    final upserts = <Map<String, dynamic>>[];

    final client = _RecordingSupabaseClient(
      _RecordingQueryBuilder((values, _) {
        upserts.add(Map<String, dynamic>.from(values));
      }),
    );
    final repository = DeviceTokenRepository(client: client);

    await repository.upsertToken(
      userId: 'user-1',
      token: 'shared-token',
      platform: 'android',
    );
    await repository.upsertToken(
      userId: 'user-1',
      token: 'shared-token',
      platform: 'ios',
    );

    expect(upserts.last['platform'], 'ios');
    expect(upserts.last['token'], 'shared-token');
  });
}
