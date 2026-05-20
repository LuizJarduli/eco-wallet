import 'package:equatable/equatable.dart';

class RewardRule extends Equatable {
  const RewardRule({
    required this.coinsPerLiter,
    required this.minLiters,
  });

  final int coinsPerLiter;
  final double minLiters;

  int estimateCoins(double liters) => (liters * coinsPerLiter).floor();

  @override
  List<Object?> get props => [coinsPerLiter, minLiters];
}
