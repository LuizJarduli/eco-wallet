import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:eco_wallet/features/disposal/domain/entities/disposal_submission.dart';
import 'package:eco_wallet/features/disposal/domain/entities/rejection_reason.dart';
import 'package:eco_wallet/features/disposal/domain/repositories/disposal_repository.dart';
import 'package:eco_wallet/features/wallet/domain/entities/coin_ledger_entry.dart';
import 'package:eco_wallet/features/wallet/domain/entities/coin_wallet.dart';
import 'package:eco_wallet/features/wallet/domain/utils/ledger_balances.dart';
import 'package:eco_wallet/features/wallet/presentation/bloc/wallet_bloc.dart';

import '../../../disposal/__mocks__/mock_disposal_repository.dart';
import '../../__mocks__/mock_wallet_repository.dart';

void main() {
  late MockWalletRepository walletRepository;
  late MockDisposalRepository disposalRepository;

  const userId = 'user-1';
  final updatedAt = DateTime.utc(2026, 5, 18, 12);
  final submittedAt = DateTime.utc(2026, 5, 18, 10);

  final initialWallet = CoinWallet(
    userId: userId,
    pendingBalance: 10,
    availableBalance: 0,
    updatedAt: updatedAt,
  );

  final rewardedWallet = CoinWallet(
    userId: userId,
    pendingBalance: 0,
    availableBalance: 10,
    updatedAt: updatedAt.add(const Duration(hours: 2)),
  );

  final ledger = [
    CoinLedgerEntry(
      id: 'ledger-1',
      amount: 10,
      type: CoinEntryType.pending,
      createdAt: updatedAt,
    ),
  ];

  DisposalSubmissionChanged? submissionChanged;

  DisposalSubmission submission({
    required DisposalStatus status,
    RejectionReasonCode? rejectionReason,
  }) {
    return DisposalSubmission(
      id: 'submission-1',
      dropOffId: 'drop-1',
      storagePath: 'user-1/submission-1.jpg',
      status: status,
      submittedAt: submittedAt,
      updatedAt: updatedAt,
      rejectionReason: rejectionReason,
    );
  }

  setUp(() {
    walletRepository = MockWalletRepository();
    disposalRepository = MockDisposalRepository();
    submissionChanged = null;

    when(
      () => walletRepository.fetchWallet(userId: userId),
    ).thenAnswer((_) async => initialWallet);
    when(
      () => walletRepository.fetchLedger(userId: userId),
    ).thenAnswer((_) async => ledger);
    when(
      () => disposalRepository.fetchMySubmissions(userId: userId),
    ).thenAnswer((_) async => [submission(status: DisposalStatus.awaitingAudit)]);
    when(() => walletRepository.unsubscribeFromWallet()).thenReturn(null);
    when(() => disposalRepository.unsubscribeFromMySubmissions()).thenReturn(null);
    when(
      () => walletRepository.subscribeToWallet(
        userId: any(named: 'userId'),
        onChanged: any(named: 'onChanged'),
      ),
    ).thenReturn(null);
    when(
      () => disposalRepository.subscribeToMySubmissions(
        userId: any(named: 'userId'),
        onChanged: any(named: 'onChanged'),
      ),
    ).thenAnswer((invocation) {
      submissionChanged =
          invocation.namedArguments[#onChanged] as DisposalSubmissionChanged;
    });
  });

  WalletBloc buildBloc() {
    return WalletBloc(
      walletRepository: walletRepository,
      disposalRepository: disposalRepository,
    );
  }

  blocTest<WalletBloc, WalletState>(
    'emits ready state with ledger balances from entries',
    build: buildBloc,
    act: (bloc) => bloc.add(const WalletStarted(userId)),
    expect:
        () => [
          const WalletLoading(),
          isA<WalletReady>()
              .having((s) => s.wallet.pendingBalance, 'pending', 10)
              .having((s) => s.wallet.availableBalance, 'available', 0)
              .having((s) => s.ledgerBalances.pendingTotal, 'ledger pending', 10)
              .having((s) => s.ledgerBalances.availableTotal, 'ledger available', 0),
        ],
    verify: (_) {
      verify(() => walletRepository.subscribeToWallet(userId: userId, onChanged: any(named: 'onChanged'))).called(1);
      verify(() => disposalRepository.subscribeToMySubmissions(userId: userId, onChanged: any(named: 'onChanged'))).called(1);
    },
  );

  blocTest<WalletBloc, WalletState>(
    'realtime wallet update replaces balances without full reload',
    build: buildBloc,
    seed:
        () => WalletReady(
          wallet: initialWallet,
          ledger: ledger,
          submissions: const [],
          ledgerBalances: balancesFromLedgerEntries(ledger),
        ),
    act: (bloc) => bloc.add(WalletRealtimeWalletUpdated(rewardedWallet)),
    expect:
        () => [
          isA<WalletReady>().having(
            (s) => s.wallet.availableBalance,
            'available',
            10,
          ),
        ],
  );

  blocTest<WalletBloc, WalletState>(
    'realtime rewarded submission triggers wallet refresh with updated available balance',
    build: buildBloc,
    act: (bloc) async {
      bloc.add(const WalletStarted(userId));
      await bloc.stream.firstWhere((state) => state is WalletReady);

      when(
        () => walletRepository.fetchWallet(userId: userId),
      ).thenAnswer((_) async => rewardedWallet);

      submissionChanged!(
        submission(status: DisposalStatus.rewarded),
      );
      await bloc.stream.firstWhere(
        (state) =>
            state is WalletReady && state.wallet.availableBalance == 10,
      );
    },
    verify: (_) {
      verify(() => walletRepository.fetchWallet(userId: userId)).called(2);
    },
  );

  blocTest<WalletBloc, WalletState>(
    'realtime non-rewarded submission merges into disposal history',
    build: buildBloc,
    act: (bloc) async {
      bloc.add(const WalletStarted(userId));
      await bloc.stream.firstWhere((state) => state is WalletReady);

      bloc.add(
        WalletRealtimeSubmissionUpdated(
          submission(status: DisposalStatus.approved),
        ),
      );
    },
    expect:
        () => [
          const WalletLoading(),
          isA<WalletReady>(),
          isA<WalletReady>().having(
            (s) => s.submissions.single.status,
            'status',
            DisposalStatus.approved,
          ),
        ],
    verify: (_) {
      verify(() => walletRepository.fetchWallet(userId: userId)).called(1);
    },
  );
}
