import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as sb;

import 'package:eco_wallet/core/errors/disposal_exception.dart';
import 'package:eco_wallet/features/disposal/domain/entities/disposal_submission.dart';
import 'package:eco_wallet/features/disposal/domain/entities/drop_off_point.dart';
import 'package:eco_wallet/features/disposal/domain/entities/reward_rule.dart';
import 'package:eco_wallet/features/disposal/domain/repositories/disposal_repository.dart';
import 'package:eco_wallet/features/disposal/domain/services/disposal_location_provider.dart';

part 'disposal_event.dart';
part 'disposal_state.dart';

class DisposalBloc extends Bloc<DisposalEvent, DisposalState> {
  DisposalBloc({
    required DisposalRepository disposalRepository,
    required DisposalLocationProvider locationProvider,
    sb.GoTrueClient? auth,
  }) : _disposalRepository = disposalRepository,
       _locationProvider = locationProvider,
       _auth = auth ?? sb.Supabase.instance.client.auth,
       super(const DisposalInitial()) {
    on<DisposalStarted>(_onStarted);
    on<DisposalDropOffSelected>(_onDropOffSelected);
    on<DisposalPhotoSelected>(_onPhotoSelected);
    on<DisposalVolumeChanged>(_onVolumeChanged);
    on<DisposalStepChanged>(_onStepChanged);
    on<DisposalSubmitRequested>(_onSubmitRequested);
    on<DisposalQrScanTapped>(_onQrScanTapped);
  }

  final DisposalRepository _disposalRepository;
  final DisposalLocationProvider _locationProvider;
  final sb.GoTrueClient _auth;

  Future<void> _onStarted(
    DisposalStarted event,
    Emitter<DisposalState> emit,
  ) async {
    emit(const DisposalLoading());
    try {
      final dropOffPoints =
          await _disposalRepository.fetchActiveDropOffPoints();
      final rewardRule = await _disposalRepository.fetchActiveRewardRule();

      if (dropOffPoints.isEmpty) {
        emit(
          const DisposalFailure(
            'Nenhum ponto de descarte ativo está disponível no momento.',
          ),
        );
        return;
      }

      emit(
        DisposalFormReady(
          userId: event.userId,
          dropOffPoints: dropOffPoints,
          step: DisposalFormStep.location,
          rewardRule: rewardRule,
        ),
      );
    } on DisposalException catch (error) {
      emit(DisposalFailure(error.message));
    } catch (_) {
      emit(
        const DisposalFailure(
          'Não foi possível carregar os pontos de descarte. Tente novamente.',
        ),
      );
    }
  }

  void _onDropOffSelected(
    DisposalDropOffSelected event,
    Emitter<DisposalState> emit,
  ) {
    final current = state;
    if (current is! DisposalFormReady) {
      return;
    }

    emit(
      current.copyWith(
        selectedDropOffId: event.dropOffId,
        clearInfoMessage: true,
      ),
    );
  }

  void _onPhotoSelected(
    DisposalPhotoSelected event,
    Emitter<DisposalState> emit,
  ) {
    final current = state;
    if (current is! DisposalFormReady) {
      return;
    }

    emit(
      current.copyWith(
        photoBytes: event.photoBytes,
        clearInfoMessage: true,
      ),
    );
  }

  void _onVolumeChanged(
    DisposalVolumeChanged event,
    Emitter<DisposalState> emit,
  ) {
    final current = state;
    if (current is! DisposalFormReady) {
      return;
    }

    emit(current.copyWith(estimatedLiters: event.liters));
  }

  void _onStepChanged(
    DisposalStepChanged event,
    Emitter<DisposalState> emit,
  ) {
    final current = state;
    if (current is! DisposalFormReady) {
      return;
    }

    final step = DisposalFormStep.values[event.step.clamp(0, 2)];
    emit(current.copyWith(step: step));
  }

  void _onQrScanTapped(
    DisposalQrScanTapped event,
    Emitter<DisposalState> emit,
  ) {
    final current = state;
    if (current is! DisposalFormReady) {
      return;
    }

    emit(
      current.copyWith(
        infoMessage: 'Leitura de QR em breve. Selecione o ponto manualmente.',
      ),
    );
  }

  Future<void> _onSubmitRequested(
    DisposalSubmitRequested event,
    Emitter<DisposalState> emit,
  ) async {
    final current = state;
    if (current is! DisposalFormReady || !current.canSubmit) {
      return;
    }

    final dropOffId = current.selectedDropOffId;
    final photoBytes = current.photoBytes;
    if (dropOffId == null || photoBytes == null) {
      return;
    }

    emit(current.copyWith(isSubmitting: true, clearInfoMessage: true));

    try {
      final coordinates = await _locationProvider.getCurrentPosition();
      final submission = await _disposalRepository.createSubmission(
        CreateDisposalInput(
          userId: current.userId,
          dropOffId: dropOffId,
          photoBytes: photoBytes,
          estimatedLiters: current.estimatedLiters,
          captureLatitude: coordinates.latitude,
          captureLongitude: coordinates.longitude,
        ),
      );

      var scoringTriggered = true;
      try {
        final accessToken = _auth.currentSession?.accessToken;
        if (accessToken == null || accessToken.isEmpty) {
          throw const DisposalException(
            'Sessão expirada. Entre novamente para concluir o envio.',
          );
        }

        await _disposalRepository.requestConfidenceScore(
          submissionId: submission.id,
          accessToken: accessToken,
        );
      } on DisposalException {
        scoringTriggered = false;
      }

      emit(
        DisposalSubmitSuccess(
          submission: submission,
          scoringTriggered: scoringTriggered,
        ),
      );
    } on DisposalException catch (error) {
      emit(DisposalFailure(error.message));
    } catch (_) {
      emit(
        const DisposalFailure(
          'Não foi possível enviar o descarte. Tente novamente.',
        ),
      );
    }
  }
}
