import 'package:flutter_test/flutter_test.dart';

import 'package:eco_wallet/features/disposal/domain/entities/disposal_submission.dart';
import 'package:eco_wallet/features/disposal/domain/utils/disposal_timeline.dart';

void main() {
  final submittedAt = DateTime.utc(2026, 5, 18, 10);
  final updatedAt = DateTime.utc(2026, 5, 19, 14);

  test('orders forward statuses chronologically with labels', () {
    final steps = buildDisposalTimeline(
      DisposalSubmission(
        id: 'sub-1',
        dropOffId: 'drop-1',
        storagePath: 'u/sub.jpg',
        status: DisposalStatus.awaitingAudit,
        submittedAt: submittedAt,
        updatedAt: updatedAt,
      ),
    );

    expect(steps, hasLength(5));
    expect(steps.map((s) => s.title).toList(), [
      'Enviado',
      'Em verificação',
      'Aprovado',
      'Aguardando auditoria',
      'Recompensado',
    ]);
    expect(steps[3].state, TimelineStepState.current);
    expect(steps[2].state, TimelineStepState.completed);
    expect(steps[4].state, TimelineStepState.upcoming);
  });

  test('rejected flow shows submitted then rejected steps', () {
    final steps = buildDisposalTimeline(
      DisposalSubmission(
        id: 'sub-2',
        dropOffId: 'drop-1',
        storagePath: 'u/sub.jpg',
        status: DisposalStatus.rejected,
        submittedAt: submittedAt,
        updatedAt: updatedAt,
      ),
    );

    expect(steps, hasLength(2));
    expect(steps.last.title, 'Recusado');
    expect(steps.last.state, TimelineStepState.current);
  });
}
