import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as sb;

import 'package:eco_wallet/core/errors/disposal_exception.dart';
import 'package:eco_wallet/features/disposal/domain/entities/disposal_submission.dart';
import 'package:eco_wallet/features/disposal/domain/entities/drop_off_point.dart';
import 'package:eco_wallet/features/disposal/domain/entities/reward_rule.dart';
import 'package:eco_wallet/features/disposal/domain/repositories/disposal_repository.dart';
import 'package:eco_wallet/features/disposal/domain/services/disposal_location_provider.dart';
import 'package:eco_wallet/features/disposal/presentation/bloc/disposal_bloc.dart';

import '../../__mocks__/mock_disposal_repository.dart';

class MockGoTrueClient extends Mock implements sb.GoTrueClient {}

class MockSession extends Mock implements sb.Session {}

void main() {
  late MockDisposalRepository disposalRepository;
  late MockDisposalLocationProvider locationProvider;
  late MockGoTrueClient auth;

  const dropOff = DropOffPoint(
    id: 'drop-1',
    name: 'Cozinha Principal',
    campus: 'UniFacens',
    latitude: -23.47,
    longitude: -47.42,
  );

  const rewardRule = RewardRule(coinsPerLiter: 10, minLiters: 1);

  final submittedAt = DateTime.utc(2026, 5, 18, 12);

  final submission = DisposalSubmission(
    id: 'submission-1',
    dropOffId: 'drop-1',
    storagePath: 'user-1/submission-1.jpg',
    status: DisposalStatus.submitted,
    submittedAt: submittedAt,
    updatedAt: submittedAt,
    estimatedLiters: 1.5,
    captureLatitude: -23.47,
    captureLongitude: -47.42,
  );

  const photoBytes = [1, 2, 3];

  setUpAll(() {
    registerFallbackValue(
      const CreateDisposalInput(
        userId: 'user-1',
        dropOffId: 'drop-1',
        photoBytes: photoBytes,
        estimatedLiters: 1,
        captureLatitude: -23.47,
        captureLongitude: -47.42,
      ),
    );
  });

  setUp(() {
    disposalRepository = MockDisposalRepository();
    locationProvider = MockDisposalLocationProvider();
    auth = MockGoTrueClient();

    when(() => disposalRepository.fetchActiveDropOffPoints()).thenAnswer(
      (_) async => [dropOff],
    );
    when(() => disposalRepository.fetchActiveRewardRule()).thenAnswer(
      (_) async => rewardRule,
    );
    when(
      () => locationProvider.getCurrentPosition(),
    ).thenAnswer(
      (_) async => const CaptureCoordinates(
        latitude: -23.47,
        longitude: -47.42,
      ),
    );

    final session = MockSession();
    when(() => session.accessToken).thenReturn('access-token');
    when(() => auth.currentSession).thenReturn(session);
  });

  DisposalBloc buildBloc() {
    return DisposalBloc(
      disposalRepository: disposalRepository,
      locationProvider: locationProvider,
      auth: auth,
    );
  }

  DisposalFormReady seedForm({List<int>? photo}) {
    return DisposalFormReady(
      userId: 'user-1',
      dropOffPoints: const [dropOff],
      step: DisposalFormStep.details,
      selectedDropOffId: 'drop-1',
      photoBytes: photo ?? photoBytes,
      estimatedLiters: 1.5,
      rewardRule: rewardRule,
    );
  }

  group('DisposalBloc', () {
    blocTest<DisposalBloc, DisposalState>(
      'emits form ready after loading drop-offs',
      build: buildBloc,
      act: (bloc) => bloc.add(const DisposalStarted(userId: 'user-1')),
      expect:
          () => [
            const DisposalLoading(),
            DisposalFormReady(
              userId: 'user-1',
              dropOffPoints: const [dropOff],
              step: DisposalFormStep.location,
              rewardRule: rewardRule,
            ),
          ],
    );

    blocTest<DisposalBloc, DisposalState>(
      'emits failure when no active drop-offs are available',
      build: buildBloc,
      act: (bloc) => bloc.add(const DisposalStarted(userId: 'user-1')),
      setUp: () {
        when(() => disposalRepository.fetchActiveDropOffPoints()).thenAnswer(
          (_) async => [],
        );
      },
      expect:
          () => [
            const DisposalLoading(),
            const DisposalFailure(
              'Nenhum ponto de descarte ativo está disponível no momento.',
            ),
          ],
    );

    blocTest<DisposalBloc, DisposalState>(
      'updates selected drop-off and advances steps',
      build: buildBloc,
      seed:
          () => DisposalFormReady(
            userId: 'user-1',
            dropOffPoints: const [dropOff],
            step: DisposalFormStep.location,
            rewardRule: rewardRule,
          ),
      act:
          (bloc) => bloc
            ..add(const DisposalDropOffSelected('drop-1'))
            ..add(const DisposalPhotoSelected(photoBytes))
            ..add(const DisposalStepChanged(1))
            ..add(const DisposalStepChanged(2)),
      expect:
          () => [
            DisposalFormReady(
              userId: 'user-1',
              dropOffPoints: const [dropOff],
              step: DisposalFormStep.location,
              selectedDropOffId: 'drop-1',
              rewardRule: rewardRule,
            ),
            DisposalFormReady(
              userId: 'user-1',
              dropOffPoints: const [dropOff],
              step: DisposalFormStep.location,
              selectedDropOffId: 'drop-1',
              photoBytes: photoBytes,
              rewardRule: rewardRule,
            ),
            DisposalFormReady(
              userId: 'user-1',
              dropOffPoints: const [dropOff],
              step: DisposalFormStep.photo,
              selectedDropOffId: 'drop-1',
              photoBytes: photoBytes,
              rewardRule: rewardRule,
            ),
            DisposalFormReady(
              userId: 'user-1',
              dropOffPoints: const [dropOff],
              step: DisposalFormStep.details,
              selectedDropOffId: 'drop-1',
              photoBytes: photoBytes,
              rewardRule: rewardRule,
            ),
          ],
    );

    blocTest<DisposalBloc, DisposalState>(
      'emits failure when location provider fails',
      build: buildBloc,
      seed: seedForm,
      act: (bloc) => bloc.add(const DisposalSubmitRequested()),
      setUp: () {
        when(() => locationProvider.getCurrentPosition()).thenThrow(
          const DisposalException('Permita o acesso à localização para registrar o descarte.'),
        );
      },
      expect:
          () => [
            seedForm().copyWith(isSubmitting: true),
            const DisposalFailure(
              'Permita o acesso à localização para registrar o descarte.',
            ),
          ],
    );

    blocTest<DisposalBloc, DisposalState>(
      'shows QR placeholder message when scan action is tapped',
      build: buildBloc,
      seed:
          () => DisposalFormReady(
            userId: 'user-1',
            dropOffPoints: const [dropOff],
            step: DisposalFormStep.location,
            rewardRule: rewardRule,
          ),
      act: (bloc) => bloc.add(const DisposalQrScanTapped()),
      expect:
          () => [
            DisposalFormReady(
              userId: 'user-1',
              dropOffPoints: const [dropOff],
              step: DisposalFormStep.location,
              rewardRule: rewardRule,
              infoMessage:
                  'Leitura de QR em breve. Selecione o ponto manualmente.',
            ),
          ],
    );

    blocTest<DisposalBloc, DisposalState>(
      'emits success when upload, insert, and score call succeed',
      build: buildBloc,
      seed: seedForm,
      act: (bloc) => bloc.add(const DisposalSubmitRequested()),
      setUp: () {
        when(
          () => disposalRepository.createSubmission(any()),
        ).thenAnswer((_) async => submission);
        when(
          () => disposalRepository.requestConfidenceScore(
            submissionId: any(named: 'submissionId'),
            accessToken: any(named: 'accessToken'),
          ),
        ).thenAnswer((_) async {});
      },
      expect:
          () => [
            seedForm().copyWith(isSubmitting: true),
            DisposalSubmitSuccess(
              submission: submission,
              scoringTriggered: true,
            ),
          ],
      verify: (_) {
        verify(() => disposalRepository.createSubmission(any())).called(1);
        verify(
          () => disposalRepository.requestConfidenceScore(
            submissionId: 'submission-1',
            accessToken: 'access-token',
          ),
        ).called(1);
      },
    );

    blocTest<DisposalBloc, DisposalState>(
      'emits failure when storage upload returns error',
      build: buildBloc,
      seed: seedForm,
      act: (bloc) => bloc.add(const DisposalSubmitRequested()),
      setUp: () {
        when(() => disposalRepository.createSubmission(any())).thenThrow(
          const DisposalException('Não foi possível enviar a foto. Tente novamente.'),
        );
      },
      expect:
          () => [
            seedForm().copyWith(isSubmitting: true),
            const DisposalFailure(
              'Não foi possível enviar a foto. Tente novamente.',
            ),
          ],
      verify: (_) {
        verifyNever(
          () => disposalRepository.requestConfidenceScore(
            submissionId: any(named: 'submissionId'),
            accessToken: any(named: 'accessToken'),
          ),
        );
      },
    );

    blocTest<DisposalBloc, DisposalState>(
      'does not call score endpoint if insert fails',
      build: buildBloc,
      seed: seedForm,
      act: (bloc) => bloc.add(const DisposalSubmitRequested()),
      setUp: () {
        when(() => disposalRepository.createSubmission(any())).thenThrow(
          const DisposalException('Não foi possível registrar o descarte. Tente novamente.'),
        );
      },
      expect:
          () => [
            seedForm().copyWith(isSubmitting: true),
            const DisposalFailure(
              'Não foi possível registrar o descarte. Tente novamente.',
            ),
          ],
      verify: (_) {
        verifyNever(
          () => disposalRepository.requestConfidenceScore(
            submissionId: any(named: 'submissionId'),
            accessToken: any(named: 'accessToken'),
          ),
        );
      },
    );

    blocTest<DisposalBloc, DisposalState>(
      'emits success with scoringTriggered false when score API fails',
      build: buildBloc,
      seed: seedForm,
      act: (bloc) => bloc.add(const DisposalSubmitRequested()),
      setUp: () {
        when(
          () => disposalRepository.createSubmission(any()),
        ).thenAnswer((_) async => submission);
        when(
          () => disposalRepository.requestConfidenceScore(
            submissionId: any(named: 'submissionId'),
            accessToken: any(named: 'accessToken'),
          ),
        ).thenThrow(
          const DisposalException(
            'Não foi possível iniciar a análise do descarte. Tente novamente.',
          ),
        );
      },
      expect:
          () => [
            seedForm().copyWith(isSubmitting: true),
            DisposalSubmitSuccess(
              submission: submission,
              scoringTriggered: false,
            ),
          ],
    );

    blocTest<DisposalBloc, DisposalState>(
      'emits success with scoringTriggered false when score API throws',
      build: buildBloc,
      seed: seedForm,
      act: (bloc) => bloc.add(const DisposalSubmitRequested()),
      setUp: () {
        when(
          () => disposalRepository.createSubmission(any()),
        ).thenAnswer((_) async => submission);
        when(
          () => disposalRepository.requestConfidenceScore(
            submissionId: any(named: 'submissionId'),
            accessToken: any(named: 'accessToken'),
          ),
        ).thenThrow(Exception('Connection refused'));
      },
      expect:
          () => [
            seedForm().copyWith(isSubmitting: true),
            DisposalSubmitSuccess(
              submission: submission,
              scoringTriggered: false,
            ),
          ],
    );
  });
}
