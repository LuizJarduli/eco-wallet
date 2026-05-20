part of 'wallet_bloc.dart';

sealed class WalletState extends Equatable {
  const WalletState();

  @override
  List<Object?> get props => [];
}

final class WalletInitial extends WalletState {
  const WalletInitial();
}

final class WalletLoading extends WalletState {
  const WalletLoading();
}

final class WalletReady extends WalletState {
  const WalletReady({
    required this.wallet,
    required this.ledger,
    required this.submissions,
    required this.ledgerBalances,
  });

  final CoinWallet wallet;
  final List<CoinLedgerEntry> ledger;
  final List<DisposalSubmission> submissions;
  final LedgerBalances ledgerBalances;

  @override
  List<Object?> get props => [wallet, ledger, submissions, ledgerBalances];
}

final class WalletFailure extends WalletState {
  const WalletFailure(this.message);

  final String message;

  @override
  List<Object?> get props => [message];
}
