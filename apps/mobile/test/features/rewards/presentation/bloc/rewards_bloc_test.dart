import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as sb;

import 'package:eco_wallet/core/errors/rewards_exception.dart';
import 'package:eco_wallet/features/rewards/domain/entities/scratch_card_campaign.dart';
import 'package:eco_wallet/features/rewards/domain/entities/scratch_play_result.dart';
import 'package:eco_wallet/features/rewards/presentation/bloc/rewards_bloc.dart';

import '../../__mocks__/mock_rewards_repository.dart';

class MockGoTrueClient extends Mock implements sb.GoTrueClient {}

class MockSession extends Mock implements sb.Session {}

void main() {
  late MockRewardsRepository rewardsRepository;
  late MockGoTrueClient auth;
  late MockSession session;

  const userId = 'user-1';
  const campaign = ScratchCardCampaign(
    id: 'campaign-1',
    name: 'Desconto mensal',
    costCoins: 10,
    active: true,
  );

  const playResult5 = ScratchPlayResult(
    playId: 'play-1',
    campaignId: 'campaign-1',
    outcomeKey: 'common_discount_5',
    discountPercent: 5,
    rarity: 'common',
    costCoins: 10,
    availableBalance: 15,
  );

  const playResult10 = ScratchPlayResult(
    playId: 'play-2',
    campaignId: 'campaign-1',
    outcomeKey: 'rare_discount_10',
    discountPercent: 10,
    rarity: 'rare',
    costCoins: 10,
    availableBalance: 20,
  );

  RewardsBloc buildBloc() {
    return RewardsBloc(
      rewardsRepository: rewardsRepository,
      auth: auth,
    );
  }

  setUp(() {
    rewardsRepository = MockRewardsRepository();
    auth = MockGoTrueClient();
    session = MockSession();

    when(() => auth.currentSession).thenReturn(session);
    when(() => session.accessToken).thenReturn('access-token');
    when(() => rewardsRepository.fetchActiveCampaign()).thenAnswer(
      (_) async => campaign,
    );
  });

  blocTest<RewardsBloc, RewardsState>(
    'emits ready with campaign after start',
    build: buildBloc,
    act: (bloc) => bloc.add(const RewardsStarted(userId: userId, availableBalance: 25)),
    expect: () => [
      const RewardsLoading(),
      const RewardsReady(campaign: campaign, availableBalance: 25),
    ],
  );

  blocTest<RewardsBloc, RewardsState>(
    'emits success revealing then ready with 5% outcome',
    build: buildBloc,
    seed: () => const RewardsReady(campaign: campaign, availableBalance: 25),
    act: (bloc) async {
      when(
        () => rewardsRepository.playScratch(
          campaignId: campaign.id,
          accessToken: 'access-token',
        ),
      ).thenAnswer((_) async => playResult5);

      bloc.add(const RewardsPlayRequested());
      await Future<void>.delayed(Duration.zero);
      bloc.add(const RewardsRevealFinished());
    },
    expect: () => [
      const RewardsReady(
        campaign: campaign,
        availableBalance: 25,
        isPlaying: true,
      ),
      RewardsRevealing(
        campaign: campaign,
        playResult: playResult5,
        availableBalance: 15,
      ),
      const RewardsReady(
        campaign: campaign,
        availableBalance: 15,
        lastResult: playResult5,
      ),
    ],
  );

  blocTest<RewardsBloc, RewardsState>(
    'emits revealing with 10% rare outcome from mocked API',
    build: buildBloc,
    seed: () => const RewardsReady(campaign: campaign, availableBalance: 30),
    act: (bloc) async {
      when(
        () => rewardsRepository.playScratch(
          campaignId: campaign.id,
          accessToken: 'access-token',
        ),
      ).thenAnswer((_) async => playResult10);

      bloc.add(const RewardsPlayRequested());
    },
    expect: () => [
      const RewardsReady(
        campaign: campaign,
        availableBalance: 30,
        isPlaying: true,
      ),
      RewardsRevealing(
        campaign: campaign,
        playResult: playResult10,
        availableBalance: 20,
      ),
    ],
  );

  blocTest<RewardsBloc, RewardsState>(
    'emits playError when API returns INSUFFICIENT_BALANCE',
    build: buildBloc,
    seed: () => const RewardsReady(campaign: campaign, availableBalance: 25),
    act: (bloc) {
      when(
        () => rewardsRepository.playScratch(
          campaignId: campaign.id,
          accessToken: 'access-token',
        ),
      ).thenThrow(
        const RewardsException(
          'Saldo insuficiente para raspar esta carta.',
          code: 'INSUFFICIENT_BALANCE',
        ),
      );

      bloc.add(const RewardsPlayRequested());
    },
    expect: () => [
      const RewardsReady(
        campaign: campaign,
        availableBalance: 25,
        isPlaying: true,
      ),
      const RewardsReady(
        campaign: campaign,
        availableBalance: 25,
        playError: 'Saldo insuficiente para raspar esta carta.',
      ),
    ],
  );

  blocTest<RewardsBloc, RewardsState>(
    'updates displayed balance after successful play',
    build: buildBloc,
    seed: () => const RewardsReady(campaign: campaign, availableBalance: 25),
    act: (bloc) async {
      when(
        () => rewardsRepository.playScratch(
          campaignId: campaign.id,
          accessToken: 'access-token',
        ),
      ).thenAnswer((_) async => playResult5);

      bloc.add(const RewardsPlayRequested());
      await Future<void>.delayed(Duration.zero);
      bloc.add(const RewardsRevealFinished());
    },
    verify: (bloc) {
      final state = bloc.state;
      expect(state, isA<RewardsReady>());
      expect((state as RewardsReady).availableBalance, 15);
      expect(state.lastResult?.discountPercent, 5);
    },
  );
}
