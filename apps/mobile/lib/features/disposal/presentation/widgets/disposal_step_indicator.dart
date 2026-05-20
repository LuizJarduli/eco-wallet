import 'package:flutter/material.dart';

import 'package:eco_wallet/core/theme/app_colors.dart';
import 'package:eco_wallet/features/disposal/presentation/bloc/disposal_bloc.dart';

class DisposalStepIndicator extends StatelessWidget {
  const DisposalStepIndicator({required this.currentStep, super.key});

  final DisposalFormStep currentStep;

  static const _labels = ['Local', 'Foto', 'Detalhes'];

  @override
  Widget build(BuildContext context) {
    final currentIndex = currentStep.index;

    return Row(
      children: List.generate(_labels.length, (index) {
        final isActive = index <= currentIndex;
        final isCurrent = index == currentIndex;

        return Expanded(
          child: Column(
            children: [
              Row(
                children: [
                  if (index > 0)
                    Expanded(
                      child: Container(
                        height: 2,
                        color:
                            isActive ? AppColors.brandGreen : AppColors.hairline,
                      ),
                    ),
                  Container(
                    width: 28,
                    height: 28,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color:
                          isActive ? AppColors.brandGreen : AppColors.surface,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color:
                            isActive ? AppColors.brandGreen : AppColors.hairline,
                      ),
                    ),
                    child: Text(
                      '${index + 1}',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: isActive ? AppColors.primary : AppColors.stone,
                      ),
                    ),
                  ),
                  if (index < _labels.length - 1)
                    Expanded(
                      child: Container(
                        height: 2,
                        color:
                            index < currentIndex
                                ? AppColors.brandGreen
                                : AppColors.hairline,
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                _labels[index],
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: isCurrent ? FontWeight.w600 : FontWeight.w500,
                  color: isActive ? AppColors.ink : AppColors.stone,
                ),
              ),
            ],
          ),
        );
      }),
    );
  }
}
