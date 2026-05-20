import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:mocktail/mocktail.dart';

import 'package:eco_wallet/core/errors/disposal_exception.dart';
import 'package:eco_wallet/features/disposal/data/datasources/disposal_api_client.dart';

class MockHttpClient extends Mock implements http.Client {}

void main() {
  late MockHttpClient httpClient;
  late DisposalApiClient apiClient;

  setUpAll(() {
    registerFallbackValue(Uri.parse('http://127.0.0.1:3000'));
  });

  setUp(() {
    httpClient = MockHttpClient();
    apiClient = DisposalApiClient(
      httpClient: httpClient,
      baseUrl: 'http://127.0.0.1:3000',
    );
  });

  test('triggerConfidenceScore succeeds on 200 response', () async {
    when(
      () => httpClient.post(
        any(),
        headers: any(named: 'headers'),
      ),
    ).thenAnswer(
      (_) async => http.Response('{"data":{}}', 200),
    );

    await apiClient.triggerConfidenceScore(
      submissionId: 'submission-1',
      accessToken: 'token-1',
    );

    verify(
      () => httpClient.post(
        Uri.parse('http://127.0.0.1:3000/v1/disposals/submission-1/score'),
        headers: {
          'Authorization': 'Bearer token-1',
          'Content-Type': 'application/json',
        },
      ),
    ).called(1);
  });

  test('triggerConfidenceScore throws DisposalException on API error body', () async {
    when(
      () => httpClient.post(
        any(),
        headers: any(named: 'headers'),
      ),
    ).thenAnswer(
      (_) async => http.Response(
        '{"error":{"message":"Falha na análise"}}',
        500,
      ),
    );

    expect(
      () => apiClient.triggerConfidenceScore(
        submissionId: 'submission-1',
        accessToken: 'token-1',
      ),
      throwsA(
        isA<DisposalException>().having(
          (error) => error.message,
          'message',
          'Falha na análise',
        ),
      ),
    );
  });

  test('triggerConfidenceScore throws when API base URL is missing', () async {
    final client = DisposalApiClient(httpClient: httpClient, baseUrl: '');

    expect(
      () => client.triggerConfidenceScore(
        submissionId: 'submission-1',
        accessToken: 'token-1',
      ),
      throwsA(isA<DisposalException>()),
    );
  });
}
