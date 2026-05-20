import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:eco_wallet/core/theme/app_colors.dart';
import 'package:eco_wallet/core/widgets/eco_primary_button.dart';
import 'package:eco_wallet/features/disposal/presentation/bloc/disposal_detail_bloc.dart';
import 'package:eco_wallet/features/disposal/presentation/widgets/disposal_status_timeline.dart';

class DisposalDetailPage extends StatefulWidget {
  const DisposalDetailPage({
    this.scoringTriggered = true,
    super.key,
  });

  final bool scoringTriggered;

  @override
  State<DisposalDetailPage> createState() => _DisposalDetailPageState();
}

class _DisposalDetailPageState extends State<DisposalDetailPage>
    with WidgetsBindingObserver {
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
      context.read<DisposalDetailBloc>().add(
        const DisposalDetailRefreshRequested(),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Status do descarte'),
      ),
      body: BlocBuilder<DisposalDetailBloc, DisposalDetailState>(
        builder: (context, state) {
          if (state is DisposalDetailLoading || state is DisposalDetailInitial) {
            return const Center(child: CircularProgressIndicator());
          }
          if (state is DisposalDetailFailure) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(state.message, textAlign: TextAlign.center),
              ),
            );
          }
          if (state is! DisposalDetailReady) {
            return const SizedBox.shrink();
          }

          final submission = state.submission;

          return RefreshIndicator(
            onRefresh: () async {
              context.read<DisposalDetailBloc>().add(
                const DisposalDetailRefreshRequested(),
              );
              await context.read<DisposalDetailBloc>().stream.firstWhere(
                (next) =>
                    next is DisposalDetailReady || next is DisposalDetailFailure,
              );
            },
            child: ListView(
              padding: const EdgeInsets.all(24),
              children: [
                _TrackingChip(code: submission.trackingCode),
                const SizedBox(height: 16),
                Text(
                  submission.dropOffName ?? 'Descarte de óleo',
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(
                      Icons.place_outlined,
                      size: 18,
                      color: AppColors.stone,
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        submission.dropOffName ?? 'Ponto de descarte',
                        style: const TextStyle(
                          fontSize: 14,
                          color: AppColors.stone,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                const Text(
                  'As moedas permanecem pendentes até a verificação da foto e a '
                  'auditoria da coleta no campus.',
                  style: TextStyle(fontSize: 14, color: AppColors.stone),
                ),
                if (!widget.scoringTriggered) ...[
                  const SizedBox(height: 12),
                  const Text(
                    'A análise automática será retomada em breve.',
                    style: TextStyle(
                      fontSize: 13,
                      color: AppColors.brandGreenDeep,
                    ),
                  ),
                ],
                const SizedBox(height: 24),
                DisposalStatusTimeline(submission: submission),
                const SizedBox(height: 24),
                EcoPrimaryButton(
                  label: 'Voltar ao início',
                  onPressed:
                      () => Navigator.of(
                        context,
                      ).popUntil((route) => route.isFirst),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _TrackingChip extends StatelessWidget {
  const _TrackingChip({required this.code});

  final String code;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.hairline),
      ),
      child: Text(
        'Código: $code',
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          fontFamily: 'monospace',
        ),
      ),
    );
  }
}
