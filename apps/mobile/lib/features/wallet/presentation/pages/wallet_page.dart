import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:eco_wallet/core/theme/app_colors.dart';
import 'package:eco_wallet/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:eco_wallet/features/disposal/domain/entities/disposal_submission.dart';
import 'package:eco_wallet/features/disposal/domain/utils/disposal_status_labels.dart';
import 'package:eco_wallet/features/disposal/presentation/bloc/disposal_detail_bloc.dart';
import 'package:eco_wallet/features/disposal/presentation/pages/disposal_detail_page.dart';
import 'package:eco_wallet/features/disposal/domain/repositories/disposal_repository.dart';
import 'package:eco_wallet/features/wallet/presentation/bloc/wallet_bloc.dart';
import 'package:eco_wallet/features/wallet/presentation/widgets/wallet_balance_card.dart';

class WalletPage extends StatefulWidget {
  const WalletPage({super.key});

  @override
  State<WalletPage> createState() => _WalletPageState();
}

class _WalletPageState extends State<WalletPage> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      context.read<WalletBloc>().add(const WalletRefreshRequested());
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<WalletBloc, WalletState>(
      builder: (context, state) {
        if (state is WalletLoading || state is WalletInitial) {
          return const Center(child: CircularProgressIndicator());
        }
        if (state is WalletFailure) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Text(state.message, textAlign: TextAlign.center),
            ),
          );
        }
        if (state is! WalletReady) {
          return const SizedBox.shrink();
        }

        return RefreshIndicator(
          onRefresh: () async {
            context.read<WalletBloc>().add(const WalletRefreshRequested());
            await context.read<WalletBloc>().stream.firstWhere(
              (next) => next is WalletReady || next is WalletFailure,
            );
          },
          child: ListView(
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
            children: [
              WalletBalanceCard(
                wallet: state.wallet,
                onGetMoreCoins: () => _showEarnInfo(context),
                onHowToEarn: () => _showEarnInfo(context),
              ),
              const SizedBox(height: 28),
              const Text(
                'Histórico de descartes',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 12),
              if (state.submissions.isEmpty)
                const Text(
                  'Nenhum descarte registrado ainda.',
                  style: TextStyle(color: AppColors.stone),
                )
              else
                ...state.submissions.map(
                  (submission) => _DisposalHistoryTile(
                    submission: submission,
                    onTap: () => _openDetail(context, submission),
                  ),
                ),
            ],
          ),
        );
      },
    );
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

  void _openDetail(BuildContext context, DisposalSubmission submission) {
    final authState = context.read<AuthBloc>().state;
    if (authState is! AuthAuthenticated) {
      return;
    }

    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder:
            (routeContext) => BlocProvider(
              create:
                  (_) => DisposalDetailBloc(
                    disposalRepository: routeContext.read<DisposalRepository>(),
                  )..add(
                    DisposalDetailStarted(
                      userId: authState.user.id,
                      submissionId: submission.id,
                      initialSubmission: submission,
                    ),
                  ),
              child: const DisposalDetailPage(),
            ),
      ),
    );
  }
}

class _DisposalHistoryTile extends StatelessWidget {
  const _DisposalHistoryTile({
    required this.submission,
    required this.onTap,
  });

  final DisposalSubmission submission;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(8),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(8),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppColors.hairline),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        submission.dropOffName ?? 'Descarte de óleo',
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        disposalStatusLabel(submission.status),
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.stone,
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right, color: AppColors.stone),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
