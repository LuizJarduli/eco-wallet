import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:eco_wallet/core/errors/wallet_exception.dart';
import 'package:eco_wallet/features/disposal/domain/entities/disposal_submission.dart';
import 'package:eco_wallet/features/disposal/domain/repositories/disposal_repository.dart';
import 'package:eco_wallet/features/wallet/domain/entities/coin_ledger_entry.dart';
import 'package:eco_wallet/features/wallet/domain/entities/coin_wallet.dart';
import 'package:eco_wallet/features/wallet/domain/repositories/wallet_repository.dart';
import 'package:eco_wallet/features/wallet/domain/utils/ledger_balances.dart';

part 'wallet_event.dart';
part 'wallet_state.dart';

class WalletBloc extends Bloc<WalletEvent, WalletState> {
  WalletBloc({
    required WalletRepository walletRepository,
    required DisposalRepository disposalRepository,
  }) : _walletRepository = walletRepository,
       _disposalRepository = disposalRepository,
       super(const WalletInitial()) {
    on<WalletStarted>(_onStarted);
    on<WalletRefreshRequested>(_onRefreshRequested);
    on<WalletRealtimeWalletUpdated>(_onRealtimeWalletUpdated);
    on<WalletRealtimeSubmissionUpdated>(_onRealtimeSubmissionUpdated);
    on<WalletStopped>(_onStopped);
  }

  final WalletRepository _walletRepository;
  final DisposalRepository _disposalRepository;
  String? _userId;

  Future<void> _onStarted(
    WalletStarted event,
    Emitter<WalletState> emit,
  ) async {
    _userId = event.userId;
    emit(const WalletLoading());
    await _loadAndSubscribe(emit);
  }

  Future<void> _onRefreshRequested(
    WalletRefreshRequested event,
    Emitter<WalletState> emit,
  ) async {
    final userId = _userId;
    if (userId == null) {
      return;
    }
    await _loadAndSubscribe(emit, showLoading: false);
  }

  void _onRealtimeWalletUpdated(
    WalletRealtimeWalletUpdated event,
    Emitter<WalletState> emit,
  ) {
    final current = state;
    if (current is! WalletReady) {
      return;
    }
    emit(
      WalletReady(
        wallet: event.wallet,
        ledger: current.ledger,
        submissions: current.submissions,
        ledgerBalances: current.ledgerBalances,
      ),
    );
  }

  void _onRealtimeSubmissionUpdated(
    WalletRealtimeSubmissionUpdated event,
    Emitter<WalletState> emit,
  ) async {
    final userId = _userId;
    if (userId == null) {
      return;
    }

    if (event.submission.status == DisposalStatus.rewarded) {
      add(const WalletRefreshRequested());
      return;
    }

    final current = state;
    if (current is! WalletReady) {
      return;
    }

    final updated = _mergeSubmission(current.submissions, event.submission);
    emit(
      WalletReady(
        wallet: current.wallet,
        ledger: current.ledger,
        submissions: updated,
        ledgerBalances: current.ledgerBalances,
      ),
    );
  }

  Future<void> _onStopped(WalletStopped event, Emitter<WalletState> emit) async {
    _disposalRepository.unsubscribeFromMySubmissions();
    _walletRepository.unsubscribeFromWallet();
    _userId = null;
    emit(const WalletInitial());
  }

  Future<void> _loadAndSubscribe(
    Emitter<WalletState> emit, {
    bool showLoading = true,
  }) async {
    final userId = _userId;
    if (userId == null) {
      return;
    }

    if (showLoading) {
      emit(const WalletLoading());
    }

    try {
      final wallet = await _walletRepository.fetchWallet(userId: userId);
      final ledger = await _walletRepository.fetchLedger(userId: userId);
      final submissions = await _disposalRepository.fetchMySubmissions(
        userId: userId,
      );

      emit(
        WalletReady(
          wallet: wallet,
          ledger: ledger,
          submissions: submissions,
          ledgerBalances: balancesFromLedgerEntries(ledger),
        ),
      );

      _walletRepository.subscribeToWallet(
        userId: userId,
        onChanged: (updated) => add(WalletRealtimeWalletUpdated(updated)),
      );
      _disposalRepository.subscribeToMySubmissions(
        userId: userId,
        onChanged:
            (submission) => add(WalletRealtimeSubmissionUpdated(submission)),
      );
    } on WalletException catch (error) {
      emit(WalletFailure(error.message));
    } catch (_) {
      emit(
        const WalletFailure(
          'Não foi possível carregar a carteira. Tente novamente.',
        ),
      );
    }
  }

  List<DisposalSubmission> _mergeSubmission(
    List<DisposalSubmission> current,
    DisposalSubmission updated,
  ) {
    final index = current.indexWhere((item) => item.id == updated.id);
    if (index < 0) {
      return [updated, ...current];
    }
    final next = List<DisposalSubmission>.from(current);
    next[index] = updated;
    return next;
  }

  @override
  Future<void> close() {
    _disposalRepository.unsubscribeFromMySubmissions();
    _walletRepository.unsubscribeFromWallet();
    return super.close();
  }
}
