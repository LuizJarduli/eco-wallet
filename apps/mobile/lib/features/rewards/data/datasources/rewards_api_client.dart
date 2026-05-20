import 'dart:convert';

import 'package:http/http.dart' as http;

import 'package:eco_wallet/core/constants/env.dart';
import 'package:eco_wallet/core/errors/rewards_exception.dart';
import 'package:eco_wallet/features/rewards/data/models/scratch_play_result_model.dart';

class RewardsApiClient {
  RewardsApiClient({
    http.Client? httpClient,
    String? baseUrl,
  }) : _httpClient = httpClient ?? http.Client(),
       _baseUrl = baseUrl ?? Env.apiBaseUrl;

  final http.Client _httpClient;
  final String _baseUrl;

  Future<ScratchPlayResultModel> playScratch({
    required String campaignId,
    required String accessToken,
  }) async {
    if (_baseUrl.isEmpty) {
      throw const RewardsException(
        'Serviço de recompensas indisponível. Tente novamente em instantes.',
      );
    }

    final uri = Uri.parse('$_baseUrl/v1/rewards/scratch/play');
    final response = await _httpClient.post(
      uri,
      headers: {
        'Authorization': 'Bearer $accessToken',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({'campaignId': campaignId}),
    );

    if (response.statusCode >= 200 && response.statusCode < 300) {
      final body = jsonDecode(response.body) as Map<String, dynamic>;
      final data = body['data'] as Map<String, dynamic>;
      return ScratchPlayResultModel.fromJson(data);
    }

    throw RewardsException(
      _messageForStatus(response),
      code: _codeForStatus(response),
    );
  }

  String? _codeForStatus(http.Response response) {
    try {
      final body = jsonDecode(response.body) as Map<String, dynamic>;
      final error = body['error'] as Map<String, dynamic>?;
      return error?['code'] as String?;
    } catch (_) {
      return null;
    }
  }

  String _messageForStatus(http.Response response) {
    try {
      final body = jsonDecode(response.body) as Map<String, dynamic>;
      final error = body['error'] as Map<String, dynamic>?;
      final code = error?['code'] as String?;
      final message = error?['message'] as String?;
      if (code == 'INSUFFICIENT_BALANCE') {
        return 'Saldo insuficiente para raspar esta carta.';
      }
      if (message != null && message.isNotEmpty) {
        return message;
      }
    } catch (_) {
      // Fall through to default message.
    }

    return 'Não foi possível raspar a carta. Verifique sua conexão e tente novamente.';
  }

  void dispose() {
    _httpClient.close();
  }
}
