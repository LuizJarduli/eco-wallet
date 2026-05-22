import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as sb;

import 'package:eco_wallet/core/errors/rewards_exception.dart';
import 'package:eco_wallet/features/rewards/domain/entities/scratch_card_campaign.dart';
import 'package:eco_wallet/features/rewards/domain/entities/scratch_play_result.dart';
import 'package:eco_wallet/features/rewards/domain/repositories/rewards_repository.dart';

part 'rewards_event.dart';
part 'rewards_state.dart';

class RewardsBloc extends Bloc<RewardsEvent, RewardsState> {
  RewardsBloc({
    required RewardsRepository rewardsRepository,
    sb.GoTrueClient? auth,
  }) : _rewardsRepository = rewardsRepository,
       _auth = auth ?? sb.Supabase.instance.client.auth,
       super(const RewardsInitial()) {
    on<RewardsStarted>(_onStarted);
    on<RewardsBalanceUpdated>(_onBalanceUpdated);
    on<RewardsPlayRequested>(_onPlayRequested);
    on<RewardsRevealFinished>(_onRevealFinished);
    on<RewardsResultDismissed>(_onResultDismissed);
  }

  final RewardsRepository _rewardsRepository;
  final sb.GoTrueClient _auth;

  Future<void> _onStarted(
    RewardsStarted event,
    Emitter<RewardsState> emit,
  ) async {
    emit(const RewardsLoading());
    try {
      final campaign = await _rewardsRepository.fetchActiveCampaign();
      if (campaign == null) {
        emit(RewardsEmpty(availableBalance: event.availableBalance));
        return;
      }
      emit(
        RewardsReady(
          campaign: campaign,
          availableBalance: event.availableBalance,
        ),
      );
    } on RewardsException catch (error) {
      emit(RewardsFailure(error.message));
    } catch (_) {
      emit(
        const RewardsFailure(
          'Não foi possível carregar as recompensas. Tente novamente.',
        ),
      );
    }
  }

  void _onBalanceUpdated(
    RewardsBalanceUpdated event,
    Emitter<RewardsState> emit,
  ) {
    final current = state;
    if (current is RewardsReady) {
      emit(current.copyWith(availableBalance: event.availableBalance));
      return;
    }
    if (current is RewardsEmpty) {
      emit(RewardsEmpty(availableBalance: event.availableBalance));
    }
  }

  Future<void> _onPlayRequested(
    RewardsPlayRequested event,
    Emitter<RewardsState> emit,
  ) async {
    final current = state;
    if (current is! RewardsReady) {
      return;
    }

    if (!current.canPlay) {
      emit(
        current.copyWith(
          playError: 'Saldo insuficiente para raspar esta carta.',
        ),
      );
      return;
    }

    final accessToken = _auth.currentSession?.accessToken;
    if (accessToken == null || accessToken.isEmpty) {
      emit(
        current.copyWith(
          playError: 'Sessão expirada. Entre novamente para raspar a carta.',
        ),
      );
      return;
    }

    emit(current.copyWith(isPlaying: true, clearPlayError: true));

    try {
      final result = await _rewardsRepository.playScratch(
        campaignId: current.campaign.id,
        accessToken: accessToken,
      );

      emit(
        RewardsRevealing(
          campaign: current.campaign,
          playResult: result,
          availableBalance: result.availableBalance,
        ),
      );
    } on RewardsException catch (error) {
      emit(
        current.copyWith(
          isPlaying: false,
          playError: error.message,
        ),
      );
    } catch (_) {
      emit(
        current.copyWith(
          isPlaying: false,
          playError:
              'Não foi possível raspar a carta. Verifique sua conexão e tente novamente.',
        ),
      );
    }
  }

  void _onRevealFinished(
    RewardsRevealFinished event,
    Emitter<RewardsState> emit,
  ) {
    final current = state;
    if (current is! RewardsRevealing) {
      return;
    }

    emit(
      RewardsReady(
        campaign: current.campaign,
        availableBalance: current.availableBalance,
        lastResult: current.playResult,
      ),
    );
  }

  void _onResultDismissed(
    RewardsResultDismissed event,
    Emitter<RewardsState> emit,
  ) {
    final current = state;
    if (current is! RewardsReady) {
      return;
    }

    emit(current.copyWith(clearLastResult: true, clearPlayError: true));
  }
}
