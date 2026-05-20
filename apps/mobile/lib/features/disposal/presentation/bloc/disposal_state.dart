part of 'disposal_bloc.dart';

enum DisposalFormStep { location, photo, details }

sealed class DisposalState extends Equatable {
  const DisposalState();

  @override
  List<Object?> get props => [];
}

final class DisposalInitial extends DisposalState {
  const DisposalInitial();
}

final class DisposalLoading extends DisposalState {
  const DisposalLoading();
}

final class DisposalFormReady extends DisposalState {
  const DisposalFormReady({
    required this.userId,
    required this.dropOffPoints,
    required this.step,
    this.selectedDropOffId,
    this.photoBytes,
    this.estimatedLiters = 1,
    this.rewardRule,
    this.isSubmitting = false,
    this.infoMessage,
  });

  final String userId;
  final List<DropOffPoint> dropOffPoints;
  final DisposalFormStep step;
  final String? selectedDropOffId;
  final List<int>? photoBytes;
  final double estimatedLiters;
  final RewardRule? rewardRule;
  final bool isSubmitting;
  final String? infoMessage;

  bool get canSubmit =>
      selectedDropOffId != null &&
      photoBytes != null &&
      photoBytes!.isNotEmpty &&
      estimatedLiters > 0 &&
      !isSubmitting;

  int get estimatedCoins =>
      rewardRule?.estimateCoins(estimatedLiters) ?? 0;

  DropOffPoint? get selectedDropOff {
    final id = selectedDropOffId;
    if (id == null) {
      return null;
    }
    for (final point in dropOffPoints) {
      if (point.id == id) {
        return point;
      }
    }
    return null;
  }

  DisposalFormReady copyWith({
    List<DropOffPoint>? dropOffPoints,
    DisposalFormStep? step,
    String? selectedDropOffId,
    List<int>? photoBytes,
    double? estimatedLiters,
    RewardRule? rewardRule,
    bool? isSubmitting,
    String? infoMessage,
    bool clearInfoMessage = false,
  }) {
    return DisposalFormReady(
      userId: userId,
      dropOffPoints: dropOffPoints ?? this.dropOffPoints,
      step: step ?? this.step,
      selectedDropOffId: selectedDropOffId ?? this.selectedDropOffId,
      photoBytes: photoBytes ?? this.photoBytes,
      estimatedLiters: estimatedLiters ?? this.estimatedLiters,
      rewardRule: rewardRule ?? this.rewardRule,
      isSubmitting: isSubmitting ?? this.isSubmitting,
      infoMessage: clearInfoMessage ? null : infoMessage ?? this.infoMessage,
    );
  }

  @override
  List<Object?> get props => [
    userId,
    dropOffPoints,
    step,
    selectedDropOffId,
    photoBytes,
    estimatedLiters,
    rewardRule,
    isSubmitting,
    infoMessage,
  ];
}

final class DisposalSubmitSuccess extends DisposalState {
  const DisposalSubmitSuccess({
    required this.submission,
    this.scoringTriggered = true,
  });

  final DisposalSubmission submission;
  final bool scoringTriggered;

  @override
  List<Object?> get props => [submission, scoringTriggered];
}

final class DisposalFailure extends DisposalState {
  const DisposalFailure(this.message);

  final String message;

  @override
  List<Object?> get props => [message];
}
