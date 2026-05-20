part of 'rewards_bloc.dart';

sealed class RewardsState extends Equatable {
  const RewardsState();

  @override
  List<Object?> get props => [];
}

final class RewardsInitial extends RewardsState {
  const RewardsInitial();
}

final class RewardsLoading extends RewardsState {
  const RewardsLoading();
}

final class RewardsReady extends RewardsState {
  const RewardsReady({
    required this.campaign,
    required this.availableBalance,
    this.isPlaying = false,
    this.lastResult,
    this.playError,
  });

  final ScratchCardCampaign campaign;
  final int availableBalance;
  final bool isPlaying;
  final ScratchPlayResult? lastResult;
  final String? playError;

  bool get canPlay => availableBalance >= campaign.costCoins && !isPlaying;

  RewardsReady copyWith({
    ScratchCardCampaign? campaign,
    int? availableBalance,
    bool? isPlaying,
    ScratchPlayResult? lastResult,
    String? playError,
    bool clearLastResult = false,
    bool clearPlayError = false,
  }) {
    return RewardsReady(
      campaign: campaign ?? this.campaign,
      availableBalance: availableBalance ?? this.availableBalance,
      isPlaying: isPlaying ?? this.isPlaying,
      lastResult: clearLastResult ? null : (lastResult ?? this.lastResult),
      playError: clearPlayError ? null : (playError ?? this.playError),
    );
  }

  @override
  List<Object?> get props => [
    campaign,
    availableBalance,
    isPlaying,
    lastResult,
    playError,
  ];
}

final class RewardsRevealing extends RewardsState {
  const RewardsRevealing({
    required this.campaign,
    required this.playResult,
    required this.availableBalance,
  });

  final ScratchCardCampaign campaign;
  final ScratchPlayResult playResult;
  final int availableBalance;

  @override
  List<Object?> get props => [campaign, playResult, availableBalance];
}

final class RewardsEmpty extends RewardsState {
  const RewardsEmpty({required this.availableBalance});

  final int availableBalance;

  @override
  List<Object?> get props => [availableBalance];
}

final class RewardsFailure extends RewardsState {
  const RewardsFailure(this.message);

  final String message;

  @override
  List<Object?> get props => [message];
}
