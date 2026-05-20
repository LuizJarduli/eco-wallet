import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:eco_wallet/core/errors/disposal_exception.dart';
import 'package:eco_wallet/features/disposal/domain/entities/disposal_submission.dart';
import 'package:eco_wallet/features/disposal/domain/repositories/disposal_repository.dart';

part 'disposal_detail_event.dart';
part 'disposal_detail_state.dart';

class DisposalDetailBloc extends Bloc<DisposalDetailEvent, DisposalDetailState> {
  DisposalDetailBloc({required DisposalRepository disposalRepository})
    : _disposalRepository = disposalRepository,
      super(const DisposalDetailInitial()) {
    on<DisposalDetailStarted>(_onStarted);
    on<DisposalDetailRefreshRequested>(_onRefreshRequested);
    on<DisposalDetailRealtimeUpdated>(_onRealtimeUpdated);
    on<DisposalDetailStopped>(_onStopped);
  }

  final DisposalRepository _disposalRepository;
  String? _userId;
  String? _submissionId;

  Future<void> _onStarted(
    DisposalDetailStarted event,
    Emitter<DisposalDetailState> emit,
  ) async {
    _userId = event.userId;
    _submissionId = event.submissionId;

    final initial = event.initialSubmission;
    if (initial != null) {
      emit(DisposalDetailReady(initial));
    } else {
      emit(const DisposalDetailLoading());
    }

    await _load(emit);
    _subscribe(event.userId);
  }

  Future<void> _onRefreshRequested(
    DisposalDetailRefreshRequested event,
    Emitter<DisposalDetailState> emit,
  ) async {
    await _load(emit);
  }

  void _onRealtimeUpdated(
    DisposalDetailRealtimeUpdated event,
    Emitter<DisposalDetailState> emit,
  ) {
    if (event.submission.id != _submissionId) {
      return;
    }
    emit(DisposalDetailReady(event.submission));
  }

  Future<void> _onStopped(
    DisposalDetailStopped event,
    Emitter<DisposalDetailState> emit,
  ) async {
    _disposalRepository.unsubscribeFromMySubmissions();
    _userId = null;
    _submissionId = null;
    emit(const DisposalDetailInitial());
  }

  Future<void> _load(Emitter<DisposalDetailState> emit) async {
    final userId = _userId;
    final submissionId = _submissionId;
    if (userId == null || submissionId == null) {
      return;
    }

    try {
      final submission = await _disposalRepository.fetchSubmissionById(
        userId: userId,
        submissionId: submissionId,
      );
      if (submission == null) {
        emit(const DisposalDetailFailure('Descarte não encontrado.'));
        return;
      }
      emit(DisposalDetailReady(submission));
    } on DisposalException catch (error) {
      emit(DisposalDetailFailure(error.message));
    } catch (_) {
      emit(
        const DisposalDetailFailure(
          'Não foi possível carregar o descarte. Tente novamente.',
        ),
      );
    }
  }

  void _subscribe(String userId) {
    _disposalRepository.subscribeToMySubmissions(
      userId: userId,
      onChanged:
          (submission) => add(DisposalDetailRealtimeUpdated(submission)),
    );
  }

  @override
  Future<void> close() {
    _disposalRepository.unsubscribeFromMySubmissions();
    return super.close();
  }
}
