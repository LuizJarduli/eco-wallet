import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';

import 'package:eco_wallet/core/theme/app_colors.dart';
import 'package:eco_wallet/core/widgets/eco_primary_button.dart';
import 'package:eco_wallet/features/disposal/domain/entities/drop_off_point.dart';
import 'package:eco_wallet/features/disposal/domain/repositories/disposal_repository.dart';
import 'package:eco_wallet/features/disposal/presentation/bloc/disposal_bloc.dart';
import 'package:eco_wallet/features/disposal/presentation/bloc/disposal_detail_bloc.dart';
import 'package:eco_wallet/features/disposal/presentation/pages/disposal_detail_page.dart';
import 'package:eco_wallet/features/disposal/presentation/widgets/disposal_step_indicator.dart';

class DisposalSubmissionPage extends StatefulWidget {
  const DisposalSubmissionPage({required this.userId, super.key});

  final String userId;

  @override
  State<DisposalSubmissionPage> createState() => _DisposalSubmissionPageState();
}

class _DisposalSubmissionPageState extends State<DisposalSubmissionPage> {
  final _volumeController = TextEditingController(text: '1');
  final _imagePicker = ImagePicker();

  @override
  void initState() {
    super.initState();
    context.read<DisposalBloc>().add(DisposalStarted(userId: widget.userId));
  }

  @override
  void dispose() {
    _volumeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<DisposalBloc, DisposalState>(
      listener: (context, state) {
        if (state is DisposalSubmitSuccess) {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute<void>(
              builder:
                  (routeContext) => BlocProvider(
                    create:
                        (_) => DisposalDetailBloc(
                          disposalRepository:
                              routeContext.read<DisposalRepository>(),
                        )..add(
                          DisposalDetailStarted(
                            userId: widget.userId,
                            submissionId: state.submission.id,
                            initialSubmission: state.submission,
                          ),
                        ),
                    child: DisposalDetailPage(
                      scoringTriggered: state.scoringTriggered,
                    ),
                  ),
            ),
          );
        }
      },
      builder: (context, state) {
        return Scaffold(
          appBar: AppBar(
            title: const Text('Novo descarte'),
          ),
          body: switch (state) {
            DisposalInitial() || DisposalLoading() => const Center(
              child: CircularProgressIndicator(),
            ),
            DisposalFailure(:final message) => _ErrorBody(message: message),
            DisposalFormReady() => _FormBody(
              state: state,
              volumeController: _volumeController,
              onPickPhoto: _pickPhoto,
            ),
            DisposalSubmitSuccess() => const SizedBox.shrink(),
          },
        );
      },
    );
  }

  Future<void> _pickPhoto() async {
    final file = await _imagePicker.pickImage(
      source: ImageSource.camera,
      imageQuality: 85,
    );
    if (file == null || !mounted) {
      return;
    }

    final bytes = await file.readAsBytes();
    if (!mounted) {
      return;
    }

    context.read<DisposalBloc>().add(DisposalPhotoSelected(bytes));
  }
}

class _ErrorBody extends StatelessWidget {
  const _ErrorBody({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            message,
            style: const TextStyle(color: AppColors.brandError),
          ),
          const SizedBox(height: 16),
          EcoPrimaryButton(
            label: 'Tentar novamente',
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
    );
  }
}

class _FormBody extends StatelessWidget {
  const _FormBody({
    required this.state,
    required this.volumeController,
    required this.onPickPhoto,
  });

  final DisposalFormReady state;
  final TextEditingController volumeController;
  final Future<void> Function() onPickPhoto;

  @override
  Widget build(BuildContext context) {
    final bloc = context.read<DisposalBloc>();
    final step = state.step;
    final locationEnabled = step == DisposalFormStep.location;
    final photoEnabled = step.index >= DisposalFormStep.photo.index;
    final detailsEnabled = step == DisposalFormStep.details;

    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                DisposalStepIndicator(currentStep: step),
                const SizedBox(height: 24),
                const Text(
                  'As moedas não são liberadas na hora. Elas ficam pendentes '
                  'até a verificação e a auditoria da coleta.',
                  style: TextStyle(fontSize: 13, color: AppColors.stone),
                ),
                if (state.infoMessage != null) ...[
                  const SizedBox(height: 12),
                  Text(
                    state.infoMessage!,
                    style: const TextStyle(
                      fontSize: 13,
                      color: AppColors.brandGreenDeep,
                    ),
                  ),
                ],
                const SizedBox(height: 24),
                _SectionCard(
                  title: 'Ponto de descarte',
                  enabled: locationEnabled,
                  child: Column(
                    children: [
                      ...state.dropOffPoints.map(
                        (point) => _DropOffTile(
                          point: point,
                          selected: state.selectedDropOffId == point.id,
                          enabled: locationEnabled,
                          onTap:
                              locationEnabled
                                  ? () => bloc.add(
                                    DisposalDropOffSelected(point.id),
                                  )
                                  : null,
                        ),
                      ),
                      const SizedBox(height: 12),
                      OutlinedButton.icon(
                        onPressed:
                            locationEnabled
                                ? () => bloc.add(const DisposalQrScanTapped())
                                : null,
                        style: OutlinedButton.styleFrom(
                          minimumSize: const Size(double.infinity, 48),
                          side: const BorderSide(
                            color: AppColors.stone,
                            style: BorderStyle.solid,
                          ),
                        ),
                        icon: const Icon(Icons.qr_code_scanner_outlined),
                        label: const Text('Escanear QR no local'),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                _SectionCard(
                  title: 'Registrar evidência',
                  enabled: photoEnabled,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Mostre claramente o frasco lacrado e o volume de óleo.',
                        style: TextStyle(fontSize: 13, color: AppColors.stone),
                      ),
                      const SizedBox(height: 12),
                      if (state.photoBytes != null)
                        Container(
                          height: 160,
                          width: double.infinity,
                          decoration: BoxDecoration(
                            color: AppColors.surface,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: AppColors.hairline),
                          ),
                          alignment: Alignment.center,
                          child: const Icon(
                            Icons.check_circle_outline,
                            color: AppColors.brandGreen,
                            size: 40,
                          ),
                        ),
                      const SizedBox(height: 12),
                      OutlinedButton.icon(
                        onPressed: photoEnabled ? onPickPhoto : null,
                        style: OutlinedButton.styleFrom(
                          minimumSize: const Size(double.infinity, 48),
                        ),
                        icon: const Icon(Icons.photo_camera_outlined),
                        label: Text(
                          state.photoBytes == null
                              ? 'Tirar foto'
                              : 'Trocar foto',
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                _SectionCard(
                  title: 'Volume estimado',
                  enabled: detailsEnabled,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      TextField(
                        controller: volumeController,
                        enabled: detailsEnabled,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        decoration: const InputDecoration(
                          labelText: 'Litros estimados',
                          suffixText: 'L',
                        ),
                        onChanged: (value) {
                          final liters = double.tryParse(
                            value.replaceAll(',', '.'),
                          );
                          if (liters != null && liters > 0) {
                            bloc.add(DisposalVolumeChanged(liters));
                          }
                        },
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Recompensa estimada: ${state.estimatedCoins} EC',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
            child: EcoPrimaryButton(
              label: _ctaLabel(step),
              isLoading: state.isSubmitting,
              onPressed: _ctaEnabled(state) ? () => _onCtaPressed(context) : null,
            ),
          ),
        ),
      ],
    );
  }

  String _ctaLabel(DisposalFormStep step) {
    return switch (step) {
      DisposalFormStep.location => 'Continuar para foto',
      DisposalFormStep.photo => 'Continuar para detalhes',
      DisposalFormStep.details => 'Enviar descarte',
    };
  }

  bool _ctaEnabled(DisposalFormReady state) {
    return switch (state.step) {
      DisposalFormStep.location => state.selectedDropOffId != null,
      DisposalFormStep.photo =>
        state.selectedDropOffId != null && state.photoBytes != null,
      DisposalFormStep.details => state.canSubmit,
    };
  }

  void _onCtaPressed(BuildContext context) {
    final bloc = context.read<DisposalBloc>();
    switch (state.step) {
      case DisposalFormStep.location:
        bloc.add(const DisposalStepChanged(1));
      case DisposalFormStep.photo:
        bloc.add(const DisposalStepChanged(2));
      case DisposalFormStep.details:
        bloc.add(const DisposalSubmitRequested());
    }
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({
    required this.title,
    required this.child,
    required this.enabled,
  });

  final String title;
  final Widget child;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: enabled ? 1 : 0.45,
      child: IgnorePointer(
        ignoring: !enabled,
        child: Container(
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
              Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 12),
              child,
            ],
          ),
        ),
      ),
    );
  }
}

class _DropOffTile extends StatelessWidget {
  const _DropOffTile({
    required this.point,
    required this.selected,
    required this.enabled,
    this.onTap,
  });

  final DropOffPoint point;
  final bool selected;
  final bool enabled;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        onTap: enabled ? onTap : null,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: selected ? AppColors.brandGreen : AppColors.hairline,
              width: selected ? 2 : 1,
            ),
          ),
          child: Row(
            children: [
              Icon(
                selected
                    ? Icons.radio_button_checked
                    : Icons.radio_button_off,
                color: selected ? AppColors.brandGreen : AppColors.stone,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      point.name,
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    Text(
                      point.campus,
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.stone,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
