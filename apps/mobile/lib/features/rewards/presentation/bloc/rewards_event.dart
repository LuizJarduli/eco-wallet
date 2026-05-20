part of 'rewards_bloc.dart';

sealed class RewardsEvent extends Equatable {
  const RewardsEvent();

  @override
  List<Object?> get props => [];
}

final class RewardsStarted extends RewardsEvent {
  const RewardsStarted({
    required this.userId,
    required this.availableBalance,
  });

  final String userId;
  final int availableBalance;

  @override
  List<Object?> get props => [userId, availableBalance];
}

final class RewardsBalanceUpdated extends RewardsEvent {
  const RewardsBalanceUpdated(this.availableBalance);

  final int availableBalance;

  @override
  List<Object?> get props => [availableBalance];
}

final class RewardsPlayRequested extends RewardsEvent {
  const RewardsPlayRequested();
}

final class RewardsRevealFinished extends RewardsEvent {
  const RewardsRevealFinished();
}

final class RewardsResultDismissed extends RewardsEvent {
  const RewardsResultDismissed();
}
