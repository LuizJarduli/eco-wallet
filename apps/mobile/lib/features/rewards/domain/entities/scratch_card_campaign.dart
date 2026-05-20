import 'package:equatable/equatable.dart';

class ScratchCardCampaign extends Equatable {
  const ScratchCardCampaign({
    required this.id,
    required this.name,
    required this.costCoins,
    required this.active,
  });

  final String id;
  final String name;
  final int costCoins;
  final bool active;

  @override
  List<Object?> get props => [id, name, costCoins, active];
}
