part of 'wallet_bloc.dart';

sealed class WalletEvent extends Equatable {
  const WalletEvent();

  @override
  List<Object?> get props => [];
}

final class WalletStarted extends WalletEvent {
  const WalletStarted(this.userId);

  final String userId;

  @override
  List<Object?> get props => [userId];
}

final class WalletRefreshRequested extends WalletEvent {
  const WalletRefreshRequested();
}

final class WalletRealtimeWalletUpdated extends WalletEvent {
  const WalletRealtimeWalletUpdated(this.wallet);

  final CoinWallet wallet;

  @override
  List<Object?> get props => [wallet];
}

final class WalletRealtimeSubmissionUpdated extends WalletEvent {
  const WalletRealtimeSubmissionUpdated(this.submission);

  final DisposalSubmission submission;

  @override
  List<Object?> get props => [submission];
}

final class WalletStopped extends WalletEvent {
  const WalletStopped();
}
