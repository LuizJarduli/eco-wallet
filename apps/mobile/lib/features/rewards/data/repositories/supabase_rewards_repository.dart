import 'package:supabase_flutter/supabase_flutter.dart' as sb;

import 'package:eco_wallet/core/errors/rewards_exception.dart';
import 'package:eco_wallet/features/rewards/data/datasources/rewards_api_client.dart';
import 'package:eco_wallet/features/rewards/data/models/scratch_card_campaign_model.dart';
import 'package:eco_wallet/features/rewards/domain/entities/scratch_card_campaign.dart';
import 'package:eco_wallet/features/rewards/domain/entities/scratch_play_result.dart';
import 'package:eco_wallet/features/rewards/domain/repositories/rewards_repository.dart';

class SupabaseRewardsRepository implements RewardsRepository {
  SupabaseRewardsRepository({
    sb.SupabaseClient? client,
    RewardsApiClient? apiClient,
  }) : _client = client ?? sb.Supabase.instance.client,
       _apiClient = apiClient ?? RewardsApiClient();

  final sb.SupabaseClient _client;
  final RewardsApiClient _apiClient;

  @override
  Future<ScratchCardCampaign?> fetchActiveCampaign() async {
    try {
      final row =
          await _client
              .from('scratch_card_campaigns')
              .select('id,name,cost_coins,active')
              .eq('active', true)
              .order('created_at', ascending: false)
              .limit(1)
              .maybeSingle();

      if (row == null) {
        return null;
      }

      return ScratchCardCampaignModel.fromJson(row).toEntity();
    } on sb.PostgrestException catch (error) {
      throw RewardsException(_messageFromPostgrest(error));
    }
  }

  @override
  Future<ScratchPlayResult> playScratch({
    required String campaignId,
    required String accessToken,
  }) async {
    try {
      final result = await _apiClient.playScratch(
        campaignId: campaignId,
        accessToken: accessToken,
      );
      return result.toEntity();
    } on RewardsException {
      rethrow;
    } catch (_) {
      throw const RewardsException(
        'Não foi possível raspar a carta. Verifique sua conexão e tente novamente.',
      );
    }
  }

  String _messageFromPostgrest(sb.PostgrestException error) {
    final message = error.message.toLowerCase();
    if (message.contains('permission') || message.contains('policy')) {
      return 'Sem permissão para carregar recompensas. Entre novamente.';
    }
    return 'Não foi possível carregar as recompensas. Tente novamente.';
  }
}
