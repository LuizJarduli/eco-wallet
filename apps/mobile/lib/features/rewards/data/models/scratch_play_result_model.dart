import 'package:eco_wallet/features/rewards/domain/entities/scratch_play_result.dart';

class ScratchPlayResultModel {
  ScratchPlayResultModel({
    required this.playId,
    required this.campaignId,
    required this.outcomeKey,
    required this.discountPercent,
    required this.rarity,
    required this.costCoins,
    required this.availableBalance,
  });

  factory ScratchPlayResultModel.fromJson(Map<String, dynamic> json) {
    return ScratchPlayResultModel(
      playId: json['playId'] as String,
      campaignId: json['campaignId'] as String,
      outcomeKey: json['outcomeKey'] as String,
      discountPercent: json['discountPercent'] as int,
      rarity: json['rarity'] as String,
      costCoins: json['costCoins'] as int,
      availableBalance: json['availableBalance'] as int,
    );
  }

  final String playId;
  final String campaignId;
  final String outcomeKey;
  final int discountPercent;
  final String rarity;
  final int costCoins;
  final int availableBalance;

  ScratchPlayResult toEntity() {
    return ScratchPlayResult(
      playId: playId,
      campaignId: campaignId,
      outcomeKey: outcomeKey,
      discountPercent: discountPercent,
      rarity: rarity,
      costCoins: costCoins,
      availableBalance: availableBalance,
    );
  }
}
