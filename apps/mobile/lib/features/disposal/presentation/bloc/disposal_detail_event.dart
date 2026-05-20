part of 'disposal_detail_bloc.dart';

sealed class DisposalDetailEvent extends Equatable {
  const DisposalDetailEvent();

  @override
  List<Object?> get props => [];
}

final class DisposalDetailStarted extends DisposalDetailEvent {
  const DisposalDetailStarted({
    required this.userId,
    required this.submissionId,
    this.initialSubmission,
  });

  final String userId;
  final String submissionId;
  final DisposalSubmission? initialSubmission;

  @override
  List<Object?> get props => [userId, submissionId, initialSubmission];
}

final class DisposalDetailRefreshRequested extends DisposalDetailEvent {
  const DisposalDetailRefreshRequested();
}

final class DisposalDetailRealtimeUpdated extends DisposalDetailEvent {
  const DisposalDetailRealtimeUpdated(this.submission);

  final DisposalSubmission submission;

  @override
  List<Object?> get props => [submission];
}

final class DisposalDetailStopped extends DisposalDetailEvent {
  const DisposalDetailStopped();
}
