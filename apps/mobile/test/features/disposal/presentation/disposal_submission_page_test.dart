import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:eco_wallet/features/disposal/domain/entities/drop_off_point.dart';
import 'package:eco_wallet/features/disposal/domain/entities/reward_rule.dart';
import 'package:eco_wallet/features/disposal/presentation/bloc/disposal_bloc.dart';
import 'package:eco_wallet/features/disposal/presentation/pages/disposal_submission_page.dart';

class MockDisposalBloc extends MockBloc<DisposalEvent, DisposalState>
    implements DisposalBloc {}

void main() {
  late MockDisposalBloc disposalBloc;

  setUpAll(() {
    registerFallbackValue(const DisposalStarted(userId: 'user-1'));
  });

  const dropOff = DropOffPoint(
    id: 'drop-1',
    name: 'Cozinha Principal',
    campus: 'UniFacens',
    latitude: -23.47,
    longitude: -47.42,
  );

  setUp(() {
    disposalBloc = MockDisposalBloc();
    when(() => disposalBloc.add(any())).thenReturn(null);
    when(() => disposalBloc.state).thenReturn(
      DisposalFormReady(
        userId: 'user-1',
        dropOffPoints: const [dropOff],
        step: DisposalFormStep.details,
        rewardRule: const RewardRule(coinsPerLiter: 10, minLiters: 1),
      ),
    );
    when(() => disposalBloc.stream).thenAnswer((_) => const Stream.empty());
    whenListen(
      disposalBloc,
      Stream<DisposalState>.fromIterable(const []),
      initialState: disposalBloc.state,
    );
  });

  testWidgets('submit disabled until photo and drop-off selected', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: BlocProvider<DisposalBloc>.value(
          value: disposalBloc,
          child: const DisposalSubmissionPage(userId: 'user-1'),
        ),
      ),
    );
    await tester.pump();

    final submitButton = find.widgetWithText(ElevatedButton, 'Enviar descarte');
    final button = tester.widget<ElevatedButton>(submitButton);
    expect(button.onPressed, isNull);
  });

  testWidgets('submit enabled when photo and drop-off are selected', (
    tester,
  ) async {
    when(() => disposalBloc.state).thenReturn(
      const DisposalFormReady(
        userId: 'user-1',
        dropOffPoints: [dropOff],
        step: DisposalFormStep.details,
        selectedDropOffId: 'drop-1',
        photoBytes: [1, 2, 3],
        estimatedLiters: 1.5,
        rewardRule: RewardRule(coinsPerLiter: 10, minLiters: 1),
      ),
    );

    await tester.pumpWidget(
      MaterialApp(
        home: BlocProvider<DisposalBloc>.value(
          value: disposalBloc,
          child: const DisposalSubmissionPage(userId: 'user-1'),
        ),
      ),
    );
    await tester.pump();

    final submitButton = find.widgetWithText(ElevatedButton, 'Enviar descarte');
    final button = tester.widget<ElevatedButton>(submitButton);
    expect(button.onPressed, isNotNull);
  });
}
