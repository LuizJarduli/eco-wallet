import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:mocktail/mocktail.dart';

import 'package:eco_wallet/core/errors/rewards_exception.dart';
import 'package:eco_wallet/features/rewards/data/datasources/rewards_api_client.dart';

class MockHttpClient extends Mock implements http.Client {}

void main() {
  late MockHttpClient httpClient;
  late RewardsApiClient apiClient;

  setUpAll(() {
    registerFallbackValue(Uri.parse('http://localhost'));
  });

  setUp(() {
    httpClient = MockHttpClient();
    apiClient = RewardsApiClient(
      httpClient: httpClient,
      baseUrl: 'http://localhost:3000',
    );
  });

  test('maps successful scratch play response', () async {
    when(
      () => httpClient.post(
        any(),
        headers: any(named: 'headers'),
        body: any(named: 'body'),
      ),
    ).thenAnswer(
      (_) async => http.Response(
        jsonEncode({
          'data': {
            'playId': 'play-1',
            'campaignId': 'campaign-1',
            'outcomeKey': 'common_discount_5',
            'discountPercent': 5,
            'rarity': 'common',
            'costCoins': 10,
            'availableBalance': 15,
          },
        }),
        201,
      ),
    );

    final result = await apiClient.playScratch(
      campaignId: 'campaign-1',
      accessToken: 'token-1',
    );

    expect(result.discountPercent, 5);
    expect(result.availableBalance, 15);
  });

  test('throws INSUFFICIENT_BALANCE message for 422 response', () async {
    when(
      () => httpClient.post(
        any(),
        headers: any(named: 'headers'),
        body: any(named: 'body'),
      ),
    ).thenAnswer(
      (_) async => http.Response(
        jsonEncode({
          'error': {
            'code': 'INSUFFICIENT_BALANCE',
            'message': 'Available coin balance is insufficient.',
          },
        }),
        422,
      ),
    );

    expect(
      () => apiClient.playScratch(
        campaignId: 'campaign-1',
        accessToken: 'token-1',
      ),
      throwsA(
        isA<RewardsException>().having(
          (error) => error.code,
          'code',
          'INSUFFICIENT_BALANCE',
        ),
      ),
    );
  });
}
