import 'package:flutter/material.dart';

import 'package:eco_wallet/core/theme/app_colors.dart';
import 'package:eco_wallet/core/utils/date_format.dart';
import 'package:eco_wallet/features/disposal/domain/entities/disposal_submission.dart';
import 'package:eco_wallet/features/disposal/domain/utils/disposal_timeline.dart';
import 'package:eco_wallet/features/disposal/domain/utils/rejection_reason_labels.dart';

class DisposalStatusTimeline extends StatelessWidget {
  const DisposalStatusTimeline({
    required this.submission,
    super.key,
  });

  final DisposalSubmission submission;

  @override
  Widget build(BuildContext context) {
    final steps = buildDisposalTimeline(submission);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.hairline),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Linha do tempo',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 16),
          for (var i = 0; i < steps.length; i++)
            _TimelineRow(
              step: steps[i],
              isLast: i == steps.length - 1,
              rejectionLabel:
                  submission.status == DisposalStatus.rejected &&
                          steps[i].status == DisposalStatus.rejected &&
                          submission.rejectionReason != null
                      ? rejectionReasonLabel(submission.rejectionReason!)
                      : null,
            ),
        ],
      ),
    );
  }
}

class _TimelineRow extends StatelessWidget {
  const _TimelineRow({
    required this.step,
    required this.isLast,
    this.rejectionLabel,
  });

  final DisposalTimelineStep step;
  final bool isLast;
  final String? rejectionLabel;

  @override
  Widget build(BuildContext context) {
    final isCompleted = step.state == TimelineStepState.completed;
    final isCurrent = step.state == TimelineStepState.current;
    final isUpcoming = step.state == TimelineStepState.upcoming;

    final iconColor =
        isCompleted || isCurrent ? AppColors.brandGreen : AppColors.stone;

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 28,
            child: Column(
              children: [
                Icon(
                  isCompleted
                      ? Icons.check_circle
                      : isCurrent
                      ? Icons.radio_button_checked
                      : Icons.radio_button_unchecked,
                  color: iconColor,
                  size: 22,
                ),
                if (!isLast)
                  Expanded(
                    child: Container(
                      width: 2,
                      margin: const EdgeInsets.symmetric(vertical: 4),
                      color:
                          isUpcoming
                              ? AppColors.hairline
                              : AppColors.brandGreenSoft,
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(bottom: isLast ? 0 : 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    step.title,
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: isCurrent ? AppColors.ink : AppColors.stone,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    step.description,
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.stone,
                    ),
                  ),
                  if (step.timestamp != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      formatPtBrDateTime(step.timestamp!),
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppColors.steel,
                      ),
                    ),
                  ],
                  if (rejectionLabel != null) ...[
                    const SizedBox(height: 8),
                    Text(
                      rejectionLabel!,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: AppColors.brandError,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
