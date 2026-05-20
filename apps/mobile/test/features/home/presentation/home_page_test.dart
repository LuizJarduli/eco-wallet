import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:eco_wallet/features/disposal/domain/repositories/disposal_repository.dart';
import 'package:eco_wallet/features/home/presentation/pages/home_page.dart';
import 'package:eco_wallet/features/wallet/domain/entities/coin_wallet.dart';
import 'package:eco_wallet/features/wallet/domain/repositories/wallet_repository.dart';
import 'package:eco_wallet/features/wallet/presentation/bloc/wallet_bloc.dart';

import '../../disposal/__mocks__/mock_disposal_repository.dart';
import '../../wallet/__mocks__/mock_wallet_repository.dart';

void main() {
  late MockWalletRepository walletRepository;
  late MockDisposalRepository disposalRepository;

  setUp(() {
    walletRepository = MockWalletRepository();
    disposalRepository = MockDisposalRepository();

    when(() => walletRepository.fetchWallet(userId: 'user-1')).thenAnswer(
      (_) async => CoinWallet(
        userId: 'user-1',
        pendingBalance: 5,
        availableBalance: 10,
        updatedAt: DateTime.utc(2026, 5, 18),
      ),
    );
    when(() => walletRepository.fetchLedger(userId: 'user-1'))
        .thenAnswer((_) async => []);
    when(() => disposalRepository.fetchMySubmissions(userId: 'user-1'))
        .thenAnswer((_) async => []);
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
    ).thenReturn(null);
  });

  Widget buildSubject() {
    return MaterialApp(
      home: RepositoryProvider<WalletRepository>.value(
        value: walletRepository,
        child: RepositoryProvider<DisposalRepository>.value(
          value: disposalRepository,
          child: BlocProvider(
            create:
                (_) => WalletBloc(
                  walletRepository: walletRepository,
                  disposalRepository: disposalRepository,
                )..add(const WalletStarted('user-1')),
            child: const HomePage(),
          ),
        ),
      ),
    );
  }

  testWidgets('renders dashboard shell content', (tester) async {
    await tester.pumpWidget(buildSubject());
    await tester.pumpAndSettle();

    expect(find.text('UniFacens EcoWallet'), findsOneWidget);
    expect(find.text('Olá, Estudante'), findsOneWidget);
    expect(find.text('Novo descarte'), findsOneWidget);
    expect(find.text('Atividade recente'), findsOneWidget);
    expect(find.text('Início'), findsOneWidget);
    expect(find.text('Descartes'), findsOneWidget);
  });

  testWidgets('highlights selected bottom navigation tab', (tester) async {
    await tester.pumpWidget(buildSubject());
    await tester.pumpAndSettle();

    await tester.tap(find.text('Recompensas'));
    await tester.pumpAndSettle();

    final rewardsLabel = tester.widget<Text>(find.text('Recompensas'));
    expect(rewardsLabel.style?.color, isNotNull);
  });
}
