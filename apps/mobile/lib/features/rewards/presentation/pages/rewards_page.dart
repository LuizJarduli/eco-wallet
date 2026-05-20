import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:eco_wallet/core/theme/app_colors.dart';
import 'package:eco_wallet/features/rewards/domain/entities/scratch_play_result.dart';
import 'package:eco_wallet/features/rewards/domain/utils/scratch_outcome_labels.dart';
import 'package:eco_wallet/features/rewards/presentation/bloc/rewards_bloc.dart';
import 'package:eco_wallet/features/rewards/presentation/widgets/scratch_card_tile.dart';
import 'package:eco_wallet/features/wallet/domain/entities/coin_wallet.dart';
import 'package:eco_wallet/features/wallet/presentation/bloc/wallet_bloc.dart';
import 'package:eco_wallet/features/wallet/presentation/widgets/wallet_balance_card.dart';

class RewardsPage extends StatefulWidget {
  const RewardsPage({required this.userId, super.key});

  final String userId;

  @override
  State<RewardsPage> createState() => _RewardsPageState();
}

class _RewardsPageState extends State<RewardsPage> {
  var _started = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) {
      return;
    }
    _started = true;

    final walletState = context.read<WalletBloc>().state;
    final balance =
        walletState is WalletReady ? walletState.wallet.availableBalance : 0;
    context.read<RewardsBloc>().add(
      RewardsStarted(
        userId: widget.userId,
        availableBalance: balance,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocListener(
      listeners: [
        BlocListener<WalletBloc, WalletState>(
          listenWhen: (previous, current) =>
              current is WalletReady &&
              (previous is! WalletReady ||
                  previous.wallet.availableBalance !=
                      current.wallet.availableBalance),
          listener: (context, state) {
            if (state is WalletReady) {
              context.read<RewardsBloc>().add(
                RewardsBalanceUpdated(state.wallet.availableBalance),
              );
            }
          },
        ),
        BlocListener<RewardsBloc, RewardsState>(
          listenWhen: (previous, current) =>
              current is RewardsRevealing ||
              (current is RewardsReady &&
                  current.lastResult != null &&
                  (previous is! RewardsReady ||
                      previous.lastResult?.playId !=
                          current.lastResult?.playId)),
          listener: (context, state) {
            if (state is RewardsRevealing ||
                (state is RewardsReady && state.lastResult != null)) {
              context.read<WalletBloc>().add(const WalletRefreshRequested());
            }
          },
        ),
      ],
      child: BlocBuilder<WalletBloc, WalletState>(
        builder: (context, walletState) {
          final wallet = walletState is WalletReady ? walletState.wallet : null;

          return BlocBuilder<RewardsBloc, RewardsState>(
            builder: (context, rewardsState) {
              if (rewardsState is RewardsLoading ||
                  rewardsState is RewardsInitial) {
                return const Center(child: CircularProgressIndicator());
              }

              if (rewardsState is RewardsFailure) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Text(
                      rewardsState.message,
                      textAlign: TextAlign.center,
                    ),
                  ),
                );
              }

              final availableBalance = _availableBalance(
                rewardsState,
                wallet,
              );

              return RefreshIndicator(
                onRefresh: () async {
                  context.read<WalletBloc>().add(
                    const WalletRefreshRequested(),
                  );
                  await context.read<WalletBloc>().stream.firstWhere(
                    (next) => next is WalletReady || next is WalletFailure,
                  );
                },
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
                  children: [
                    if (wallet != null)
                      WalletBalanceCard(
                        wallet: wallet,
                        onGetMoreCoins: () => _showEarnInfo(context),
                        onHowToEarn: () => _showEarnInfo(context),
                      )
                    else
                      _BalanceFallback(availableBalance: availableBalance),
                    const SizedBox(height: 28),
                    Row(
                      children: [
                        const Expanded(
                          child: Text(
                            'Desbloquear recompensas',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        TextButton(
                          onPressed: () {},
                          child: const Text('Ver todas'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    ..._buildRewardsBody(context, rewardsState),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }

  int _availableBalance(RewardsState rewardsState, CoinWallet? wallet) {
    if (rewardsState is RewardsReady) {
      return rewardsState.availableBalance;
    }
    if (rewardsState is RewardsRevealing) {
      return rewardsState.availableBalance;
    }
    if (rewardsState is RewardsEmpty) {
      return rewardsState.availableBalance;
    }
    return wallet?.availableBalance ?? 0;
  }

  List<Widget> _buildRewardsBody(
    BuildContext context,
    RewardsState rewardsState,
  ) {
    if (rewardsState is RewardsEmpty) {
      return const [
        Text(
          'Nenhuma campanha de raspadinha ativa no momento.',
          style: TextStyle(color: AppColors.stone),
        ),
      ];
    }

    if (rewardsState is RewardsRevealing) {
      return [
        ScratchCardTile(
          campaign: rewardsState.campaign,
          canPlay: false,
          isPlaying: false,
          onPlay: () {},
          revealResult: rewardsState.playResult,
          isRevealing: true,
          onRevealFinished: () {
            context.read<RewardsBloc>().add(const RewardsRevealFinished());
          },
        ),
      ];
    }

    if (rewardsState is RewardsReady) {
      return [
        if (rewardsState.playError != null) ...[
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            margin: const EdgeInsets.only(bottom: 12),
            decoration: BoxDecoration(
              color: AppColors.brandError.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: AppColors.brandError.withValues(alpha: 0.3),
              ),
            ),
            child: Text(
              rewardsState.playError!,
              style: const TextStyle(
                color: AppColors.brandError,
                fontSize: 13,
              ),
            ),
          ),
        ],
        ScratchCardTile(
          campaign: rewardsState.campaign,
          canPlay: rewardsState.canPlay,
          isPlaying: rewardsState.isPlaying,
          revealResult: rewardsState.lastResult,
          onPlay: () {
            context.read<RewardsBloc>().add(const RewardsPlayRequested());
          },
        ),
        if (rewardsState.lastResult != null) ...[
          const SizedBox(height: 16),
          _ResultSummaryCard(
            result: rewardsState.lastResult!,
            onDismiss: () {
              context.read<RewardsBloc>().add(const RewardsResultDismissed());
            },
          ),
        ],
      ];
    }

    return const [];
  }

  void _showEarnInfo(BuildContext context) {
    showDialog<void>(
      context: context,
      builder:
          (dialogContext) => AlertDialog(
            title: const Text('Como ganhar EcoCoins'),
            content: const Text(
              'Envie fotos de descarte de óleo nos pontos do campus. '
              'As moedas ficam pendentes até a verificação e a auditoria da coleta.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(),
                child: const Text('Entendi'),
              ),
            ],
          ),
    );
  }
}

class _BalanceFallback extends StatelessWidget {
  const _BalanceFallback({required this.availableBalance});

  final int availableBalance;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.walletCard,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Saldo EcoCoin',
            style: TextStyle(color: AppColors.onDarkMuted, fontSize: 13),
          ),
          const SizedBox(height: 8),
          Text(
            '$availableBalance EC disponíveis',
            style: const TextStyle(
              color: AppColors.onDark,
              fontSize: 24,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _ResultSummaryCard extends StatelessWidget {
  const _ResultSummaryCard({
    required this.result,
    required this.onDismiss,
  });

  final ScratchPlayResult result;
  final VoidCallback onDismiss;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.brandGreen.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.brandGreen),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            scratchDiscountLabel(result),
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            scratchRedemptionCopy(result),
            style: const TextStyle(color: AppColors.stone, fontSize: 13),
          ),
          const SizedBox(height: 12),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: onDismiss,
              child: const Text('Fechar'),
            ),
          ),
        ],
      ),
    );
  }
}
