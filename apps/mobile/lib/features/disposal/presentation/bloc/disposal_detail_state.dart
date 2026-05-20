part of 'disposal_detail_bloc.dart';

sealed class DisposalDetailState extends Equatable {
  const DisposalDetailState();

  @override
  List<Object?> get props => [];
}

final class DisposalDetailInitial extends DisposalDetailState {
  const DisposalDetailInitial();
}

final class DisposalDetailLoading extends DisposalDetailState {
  const DisposalDetailLoading();
}

final class DisposalDetailReady extends DisposalDetailState {
  const DisposalDetailReady(this.submission);

  final DisposalSubmission submission;

  @override
  List<Object?> get props => [submission];
}

final class DisposalDetailFailure extends DisposalDetailState {
  const DisposalDetailFailure(this.message);

  final String message;

  @override
  List<Object?> get props => [message];
}
