import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:eco_wallet/app.dart';
import 'package:eco_wallet/core/notifications/device_token_registrar.dart';
import 'package:eco_wallet/core/notifications/device_token_repository.dart';
import 'package:eco_wallet/core/notifications/noop_push_token_service.dart';
import 'package:eco_wallet/features/auth/domain/entities/auth_user.dart';
import 'package:eco_wallet/features/auth/domain/repositories/auth_repository.dart';
import 'package:eco_wallet/features/disposal/domain/repositories/disposal_repository.dart';
import 'package:eco_wallet/features/wallet/domain/entities/coin_wallet.dart';
import 'package:eco_wallet/features/rewards/domain/entities/scratch_card_campaign.dart';
import 'package:eco_wallet/features/rewards/domain/repositories/rewards_repository.dart';
import 'package:eco_wallet/features/wallet/domain/repositories/wallet_repository.dart';

class MockAuthRepository extends Mock implements AuthRepository {}

class MockDisposalRepository extends Mock implements DisposalRepository {}

class MockRewardsRepository extends Mock implements RewardsRepository {}

class MockWalletRepository extends Mock implements WalletRepository {}

class MockDeviceTokenRepository extends Mock implements DeviceTokenRepository {}

void main() {
  late MockAuthRepository authRepository;
  late MockDisposalRepository disposalRepository;
  late MockRewardsRepository rewardsRepository;
  late MockWalletRepository walletRepository;
  late DeviceTokenRegistrar deviceTokenRegistrar;
  late MockDeviceTokenRepository deviceTokenRepository;

  const testUser = AuthUser(id: 'user-1', email: 'student@unifacens.edu.br');

  setUp(() {
    authRepository = MockAuthRepository();
    disposalRepository = MockDisposalRepository();
    rewardsRepository = MockRewardsRepository();
    walletRepository = MockWalletRepository();
    when(() => rewardsRepository.fetchActiveCampaign()).thenAnswer(
      (_) async => const ScratchCardCampaign(
        id: 'campaign-1',
        name: 'Campanha teste',
        costCoins: 10,
        active: true,
      ),
    );
    deviceTokenRepository = MockDeviceTokenRepository();
    when(
      () => deviceTokenRepository.upsertToken(
        userId: any(named: 'userId'),
        token: any(named: 'token'),
        platform: any(named: 'platform'),
      ),
    ).thenAnswer((_) async {});
    deviceTokenRegistrar = DeviceTokenRegistrar(
      deviceTokenRepository: deviceTokenRepository,
      pushTokenService: NoOpPushTokenService(),
    );

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
        deviceTokenRegistrar: deviceTokenRegistrar,
        disposalRepository: disposalRepository,
        rewardsRepository: rewardsRepository,
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
        deviceTokenRegistrar: deviceTokenRegistrar,
        disposalRepository: disposalRepository,
        rewardsRepository: rewardsRepository,
        walletRepository: walletRepository,
      ),
    );
    await tester.pump();
    await tester.pump();

    expect(find.text('Entrar'), findsOneWidget);
    expect(find.text('Olá, Estudante'), findsNothing);
  });
}
