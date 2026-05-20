import 'package:eco_wallet/features/disposal/domain/entities/disposal_submission.dart';

enum TimelineStepState { completed, current, upcoming }

class DisposalTimelineStep {
  const DisposalTimelineStep({
    required this.status,
    required this.title,
    required this.description,
    required this.state,
    this.timestamp,
  });

  final DisposalStatus status;
  final String title;
  final String description;
  final TimelineStepState state;
  final DateTime? timestamp;
}

const _forwardStatuses = [
  DisposalStatus.submitted,
  DisposalStatus.underReview,
  DisposalStatus.approved,
  DisposalStatus.awaitingAudit,
  DisposalStatus.rewarded,
];

List<DisposalTimelineStep> buildDisposalTimeline(DisposalSubmission submission) {
  if (submission.status == DisposalStatus.rejected) {
    return [
      DisposalTimelineStep(
        status: DisposalStatus.submitted,
        title: 'Enviado',
        description: 'Registro recebido no ponto selecionado',
        state: TimelineStepState.completed,
        timestamp: submission.submittedAt,
      ),
      DisposalTimelineStep(
        status: DisposalStatus.rejected,
        title: 'Recusado',
        description: 'O descarte não foi aprovado',
        state: TimelineStepState.current,
        timestamp: submission.updatedAt,
      ),
    ];
  }

  final currentIndex = _forwardStatuses.indexOf(submission.status);
  final safeIndex = currentIndex < 0 ? 0 : currentIndex;

  return [
    for (var i = 0; i < _forwardStatuses.length; i++)
      _stepForStatus(
        status: _forwardStatuses[i],
        submission: submission,
        index: i,
        currentIndex: safeIndex,
      ),
  ];
}

DisposalTimelineStep _stepForStatus({
  required DisposalStatus status,
  required DisposalSubmission submission,
  required int index,
  required int currentIndex,
}) {
  final copy = _copyForStatus(status);
  final state =
      index < currentIndex
          ? TimelineStepState.completed
          : index == currentIndex
          ? TimelineStepState.current
          : TimelineStepState.upcoming;

  final timestamp =
      state == TimelineStepState.upcoming
          ? null
          : status == DisposalStatus.submitted
          ? submission.submittedAt
          : submission.updatedAt;

  return DisposalTimelineStep(
    status: status,
    title: copy.$1,
    description: copy.$2,
    state: state,
    timestamp: timestamp,
  );
}

(String, String) _copyForStatus(DisposalStatus status) {
  return switch (status) {
    DisposalStatus.submitted => (
      'Enviado',
      'Registro recebido no ponto selecionado',
    ),
    DisposalStatus.underReview => (
      'Em verificação',
      'Equipe analisa foto e localização',
    ),
    DisposalStatus.approved => (
      'Aprovado',
      'Descarte validado; moedas ficam pendentes até a auditoria',
    ),
    DisposalStatus.awaitingAudit => (
      'Aguardando auditoria',
      'Coleta no campus será confirmada pela equipe',
    ),
    DisposalStatus.rewarded => (
      'Recompensado',
      'Moedas liberadas na carteira',
    ),
    DisposalStatus.rejected => ('Recusado', 'Descarte não aprovado'),
  };
}
