import 'package:flutter/material.dart';

import 'package:eco_wallet/core/theme/app_colors.dart';
import 'package:eco_wallet/features/rewards/domain/entities/scratch_card_campaign.dart';
import 'package:eco_wallet/features/rewards/domain/entities/scratch_play_result.dart';
import 'package:eco_wallet/features/rewards/domain/utils/scratch_outcome_labels.dart';

class ScratchCardTile extends StatefulWidget {
  const ScratchCardTile({
    required this.campaign,
    required this.canPlay,
    required this.isPlaying,
    this.onPlay,
    this.revealResult,
    this.isRevealing = false,
    this.onRevealFinished,
    super.key,
  });

  final ScratchCardCampaign campaign;
  final bool canPlay;
  final bool isPlaying;
  final VoidCallback? onPlay;
  final ScratchPlayResult? revealResult;
  final bool isRevealing;
  final VoidCallback? onRevealFinished;

  @override
  State<ScratchCardTile> createState() => _ScratchCardTileState();
}

class _ScratchCardTileState extends State<ScratchCardTile>
    with SingleTickerProviderStateMixin {
  late final AnimationController _revealController;
  late final Animation<double> _revealAnimation;

  @override
  void initState() {
    super.initState();
    _revealController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _revealAnimation = CurvedAnimation(
      parent: _revealController,
      curve: Curves.easeOutCubic,
    );
    _revealController.addStatusListener(_onRevealStatus);
  }

  @override
  void didUpdateWidget(ScratchCardTile oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isRevealing &&
        widget.revealResult != null &&
        !oldWidget.isRevealing) {
      _revealController.forward(from: 0);
    }
  }

  void _onRevealStatus(AnimationStatus status) {
    if (status == AnimationStatus.completed) {
      widget.onRevealFinished?.call();
    }
  }

  @override
  void dispose() {
    _revealController
      ..removeStatusListener(_onRevealStatus)
      ..dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final result = widget.revealResult;
    final showOutcome =
        result != null &&
        (widget.isRevealing ||
            _revealController.isAnimating ||
            _revealController.isCompleted);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.hairline),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _Badge(
                label: result != null && result.isRare ? 'Premium' : 'Oferta quente',
                accent: result != null && result.isRare
                    ? AppColors.rewardCoral
                    : AppColors.brandGreen,
              ),
              const Spacer(),
              Text(
                '${widget.campaign.costCoins} EC',
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  color: AppColors.stone,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            widget.campaign.name,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 4),
          const Text(
            'Desconto na parcela do pedido no campus',
            style: TextStyle(fontSize: 12, color: AppColors.stone),
          ),
          const SizedBox(height: 16),
          AspectRatio(
            aspectRatio: 16 / 9,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppColors.heroDarkFrom,
                      AppColors.walletCard,
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  border: Border.all(
                    color: AppColors.onDarkMuted,
                    style: BorderStyle.solid,
                  ),
                ),
                child: showOutcome
                    ? FadeTransition(
                      opacity: _revealAnimation,
                      child: _OutcomePanel(result: result),
                    )
                    : _ScratchOverlay(progress: _revealAnimation.value),
              ),
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: widget.canPlay && !widget.isPlaying ? widget.onPlay : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.brandGreen,
                foregroundColor: AppColors.primary,
                disabledBackgroundColor: AppColors.hairline,
                disabledForegroundColor: AppColors.stone,
              ),
              child: widget.isPlaying
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Raspar agora'),
            ),
          ),
          if (!widget.canPlay) ...[
            const SizedBox(height: 8),
            const Text(
              'Saldo insuficiente para raspar esta carta.',
              style: TextStyle(fontSize: 12, color: AppColors.brandError),
            ),
          ],
        ],
      ),
    );
  }
}

class _ScratchOverlay extends StatelessWidget {
  const _ScratchOverlay({required this.progress});

  final double progress;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _DashedScratchPainter(revealProgress: progress),
      child: const Center(
        child: Icon(
          Icons.auto_awesome_outlined,
          color: AppColors.onDarkMuted,
          size: 40,
        ),
      ),
    );
  }
}

class _OutcomePanel extends StatelessWidget {
  const _OutcomePanel({required this.result});

  final ScratchPlayResult result;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            scratchDiscountLabel(result),
            key: ValueKey('discount-${result.discountPercent}'),
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: AppColors.onDark,
              fontSize: 22,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            scratchRedemptionCopy(result),
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: AppColors.onDarkMuted,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  const _Badge({required this.label, required this.accent});

  final String label;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: accent,
        ),
      ),
    );
  }
}

class _DashedScratchPainter extends CustomPainter {
  _DashedScratchPainter({required this.revealProgress});

  final double revealProgress;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.onDarkMuted.withValues(alpha: 1 - revealProgress)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    const dashWidth = 8.0;
    const dashSpace = 6.0;
    final rect = RRect.fromRectAndRadius(
      Rect.fromLTWH(12, 12, size.width - 24, size.height - 24),
      const Radius.circular(6),
    );

    final path = Path()..addRRect(rect);
    for (final metric in path.computeMetrics()) {
      var distance = 0.0;
      while (distance < metric.length) {
        final next = distance + dashWidth;
        final extract = metric.extractPath(
          distance,
          next.clamp(0, metric.length),
        );
        canvas.drawPath(extract, paint);
        distance = next + dashSpace;
      }
    }
  }

  @override
  bool shouldRepaint(covariant _DashedScratchPainter oldDelegate) {
    return oldDelegate.revealProgress != revealProgress;
  }
}
