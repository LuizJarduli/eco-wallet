import 'dart:convert';

import 'package:http/http.dart' as http;

import 'package:eco_wallet/core/constants/env.dart';
import 'package:eco_wallet/core/errors/disposal_exception.dart';

class DisposalApiClient {
  DisposalApiClient({
    http.Client? httpClient,
    String? baseUrl,
  }) : _httpClient = httpClient ?? http.Client(),
       _baseUrl = baseUrl ?? Env.apiBaseUrl;

  final http.Client _httpClient;
  final String _baseUrl;

  Future<void> triggerConfidenceScore({
    required String submissionId,
    required String accessToken,
  }) async {
    if (_baseUrl.isEmpty) {
      throw const DisposalException(
        'Serviço de análise indisponível. Tente novamente em instantes.',
      );
    }

    final uri = Uri.parse('$_baseUrl/v1/disposals/$submissionId/score');
    final response = await _httpClient.post(
      uri,
      headers: {
        'Authorization': 'Bearer $accessToken',
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode >= 200 && response.statusCode < 300) {
      return;
    }

    throw DisposalException(_messageForStatus(response));
  }

  String _messageForStatus(http.Response response) {
    try {
      final body = jsonDecode(response.body) as Map<String, dynamic>;
      final error = body['error'] as Map<String, dynamic>?;
      final message = error?['message'] as String?;
      if (message != null && message.isNotEmpty) {
        return message;
      }
    } catch (_) {
      // Fall through to default message.
    }

    return 'Não foi possível iniciar a análise do descarte. Tente novamente.';
  }

  void dispose() {
    _httpClient.close();
  }
}
