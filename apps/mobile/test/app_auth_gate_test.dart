import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:eco_wallet/app.dart';
import 'package:eco_wallet/features/auth/domain/entities/auth_user.dart';
import 'package:eco_wallet/features/auth/domain/repositories/auth_repository.dart';
import 'package:eco_wallet/features/disposal/domain/repositories/disposal_repository.dart';
import 'package:eco_wallet/features/wallet/domain/entities/coin_wallet.dart';
import 'package:eco_wallet/features/wallet/domain/repositories/wallet_repository.dart';

class MockAuthRepository extends Mock implements AuthRepository {}

class MockDisposalRepository extends Mock implements DisposalRepository {}

class MockWalletRepository extends Mock implements WalletRepository {}

void main() {
  late MockAuthRepository authRepository;
  late MockDisposalRepository disposalRepository;
  late MockWalletRepository walletRepository;

  const testUser = AuthUser(id: 'user-1', email: 'student@unifacens.edu.br');

  setUp(() {
    authRepository = MockAuthRepository();
    disposalRepository = MockDisposalRepository();
    walletRepository = MockWalletRepository();

    when(() => authRepository.signOut()).thenAnswer((_) async {});
    when(() => disposalRepository.fetchMySubmissions(userId: testUser.id))
        .thenAnswer((_) async => []);
    when(() => disposalRepository.unsubscribeFromMySubmissions()).thenReturn(null);
    when(
      () => disposalRepository.subscribeToMySubmissions(
        userId: any(named: 'userId'),
        onChanged: any(named: 'onChanged'),
      ),
    ).thenReturn(null);
    when(() => walletRepository.fetchWallet(userId: testUser.id)).thenAnswer(
      (_) async => CoinWallet(
        userId: testUser.id,
        pendingBalance: 0,
        availableBalance: 0,
        updatedAt: DateTime.utc(2026, 5, 18),
      ),
    );
    when(() => walletRepository.fetchLedger(userId: testUser.id))
        .thenAnswer((_) async => []);
    when(() => walletRepository.unsubscribeFromWallet()).thenReturn(null);
    when(
      () => walletRepository.subscribeToWallet(
        userId: any(named: 'userId'),
        onChanged: any(named: 'onChanged'),
      ),
    ).thenReturn(null);
  });

  testWidgets('navigates to home when session exists on cold start', (
    tester,
  ) async {
    when(() => authRepository.currentUser).thenReturn(testUser);
    when(() => authRepository.restoreSession()).thenAnswer((_) async => testUser);

    await tester.pumpWidget(
      EcoWalletApp(
        authRepository: authRepository,
        disposalRepository: disposalRepository,
        walletRepository: walletRepository,
      ),
    );
    await tester.pump();
    await tester.pump();

    expect(find.text('Olá, Estudante'), findsOneWidget);
    expect(find.text('Entrar'), findsNothing);
  });

  testWidgets('shows login when no session on cold start', (tester) async {
    when(() => authRepository.currentUser).thenReturn(null);
    when(() => authRepository.restoreSession()).thenAnswer((_) async => null);

    await tester.pumpWidget(
      EcoWalletApp(
        authRepository: authRepository,
        disposalRepository: disposalRepository,
        walletRepository: walletRepository,
      ),
    );
    await tester.pump();
    await tester.pump();

    expect(find.text('Entrar'), findsOneWidget);
    expect(find.text('Olá, Estudante'), findsNothing);
  });
}
