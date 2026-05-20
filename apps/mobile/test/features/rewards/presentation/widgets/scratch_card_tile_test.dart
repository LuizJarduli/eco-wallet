import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:eco_wallet/features/rewards/domain/entities/scratch_card_campaign.dart';
import 'package:eco_wallet/features/rewards/domain/entities/scratch_play_result.dart';
import 'package:eco_wallet/features/rewards/presentation/widgets/scratch_card_tile.dart';

void main() {
  const campaign = ScratchCardCampaign(
    id: 'campaign-1',
    name: 'Desconto mensal',
    costCoins: 10,
    active: true,
  );

  testWidgets('disables play button when balance is below cost', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: ScratchCardTile(
              campaign: campaign,
              canPlay: false,
              isPlaying: false,
            ),
          ),
        ),
      ),
    );

    final button = tester.widget<ElevatedButton>(find.byType(ElevatedButton));
    expect(button.onPressed, isNull);
    expect(
      find.text('Saldo insuficiente para raspar esta carta.'),
      findsOneWidget,
    );
  });

  testWidgets('shows 10% de desconto label when outcome is rare tier', (
    tester,
  ) async {
    const result = ScratchPlayResult(
      playId: 'play-1',
      campaignId: 'campaign-1',
      outcomeKey: 'rare_discount_10',
      discountPercent: 10,
      rarity: 'rare',
      costCoins: 10,
      availableBalance: 20,
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: ScratchCardTile(
              campaign: campaign,
              canPlay: false,
              isPlaying: false,
              onPlay: () {},
              revealResult: result,
              isRevealing: true,
              onRevealFinished: () {},
            ),
          ),
        ),
      ),
    );

    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.text('10% de desconto'), findsWidgets);
    expect(find.text('Premium'), findsOneWidget);
  });
}
