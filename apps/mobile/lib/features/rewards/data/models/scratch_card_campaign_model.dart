import 'package:eco_wallet/features/rewards/domain/entities/scratch_card_campaign.dart';

class ScratchCardCampaignModel {
  ScratchCardCampaignModel({
    required this.id,
    required this.name,
    required this.costCoins,
    required this.active,
  });

  factory ScratchCardCampaignModel.fromJson(Map<String, dynamic> json) {
    return ScratchCardCampaignModel(
      id: json['id'] as String,
      name: json['name'] as String,
      costCoins: json['cost_coins'] as int,
      active: json['active'] as bool,
    );
  }

  final String id;
  final String name;
  final int costCoins;
  final bool active;

  ScratchCardCampaign toEntity() {
    return ScratchCardCampaign(
      id: id,
      name: name,
      costCoins: costCoins,
      active: active,
    );
  }
}
