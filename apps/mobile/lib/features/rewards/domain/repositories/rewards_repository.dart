import 'package:eco_wallet/features/rewards/domain/entities/scratch_card_campaign.dart';
import 'package:eco_wallet/features/rewards/domain/entities/scratch_play_result.dart';

abstract class RewardsRepository {
  Future<ScratchCardCampaign?> fetchActiveCampaign();

  Future<ScratchPlayResult> playScratch({
    required String campaignId,
    required String accessToken,
  });
}
