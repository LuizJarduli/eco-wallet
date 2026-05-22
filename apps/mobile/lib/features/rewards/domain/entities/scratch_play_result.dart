import 'package:equatable/equatable.dart';

class ScratchPlayResult extends Equatable {
  const ScratchPlayResult({
    required this.playId,
    required this.campaignId,
    required this.outcomeKey,
    required this.discountPercent,
    required this.rarity,
    required this.costCoins,
    required this.availableBalance,
  });

  final String playId;
  final String campaignId;
  final String outcomeKey;
  final int discountPercent;
  final String rarity;
  final int costCoins;
  final int availableBalance;

  bool get isRare => rarity == 'rare' || discountPercent >= 10;

  @override
  List<Object?> get props => [
    playId,
    campaignId,
    outcomeKey,
    discountPercent,
    rarity,
    costCoins,
    availableBalance,
  ];
}
