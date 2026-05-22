import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:eco_wallet/features/disposal/domain/entities/disposal_submission.dart';
import 'package:eco_wallet/features/disposal/domain/entities/rejection_reason.dart';
import 'package:eco_wallet/features/disposal/presentation/bloc/disposal_detail_bloc.dart';
import 'package:eco_wallet/features/disposal/presentation/pages/disposal_detail_page.dart';

import '../__mocks__/mock_disposal_repository.dart';

void main() {
  late MockDisposalRepository disposalRepository;

  final submittedAt = DateTime.utc(2026, 5, 18, 10);
  final updatedAt = DateTime.utc(2026, 5, 19, 12);

  DisposalSubmission buildSubmission({
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
      dropOffName: 'Cozinha Principal',
      rejectionReason: rejectionReason,
    );
  }

  setUp(() {
    disposalRepository = MockDisposalRepository();
    when(() => disposalRepository.unsubscribeFromMySubmissions()).thenReturn(null);
    when(
      () => disposalRepository.subscribeToMySubmissions(
        userId: any(named: 'userId'),
        onChanged: any(named: 'onChanged'),
      ),
    ).thenReturn(null);
  });

  Future<void> pumpDetail(
    WidgetTester tester, {
    required DisposalSubmission submission,
  }) async {
    when(
      () => disposalRepository.fetchSubmissionById(
        userId: 'user-1',
        submissionId: 'submission-1',
      ),
    ).thenAnswer((_) async => submission);

    await tester.pumpWidget(
      MaterialApp(
        home: BlocProvider(
          create:
              (_) => DisposalDetailBloc(disposalRepository: disposalRepository)
                ..add(
                  DisposalDetailStarted(
                    userId: 'user-1',
                    submissionId: 'submission-1',
                    initialSubmission: submission,
                  ),
                ),
          child: const DisposalDetailPage(scoringTriggered: true),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('shows submitted timeline and delayed reward copy', (tester) async {
    await pumpDetail(
      tester,
      submission: buildSubmission(status: DisposalStatus.submitted),
    );

    expect(find.text('Enviado'), findsOneWidget);
    expect(
      find.textContaining('moedas permanecem pendentes'),
      findsOneWidget,
    );
  });

  testWidgets('rejected status shows mapped rejection reason label', (
    tester,
  ) async {
    await pumpDetail(
      tester,
      submission: buildSubmission(
        status: DisposalStatus.rejected,
        rejectionReason: RejectionReasonCode.belowMinVolume,
      ),
    );

    expect(find.text('Recusado'), findsOneWidget);
    expect(
      find.text('O volume informado está abaixo do mínimo.'),
      findsOneWidget,
    );
  });
}
