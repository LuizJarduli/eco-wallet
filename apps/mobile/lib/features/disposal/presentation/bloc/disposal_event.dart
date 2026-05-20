part of 'disposal_bloc.dart';

sealed class DisposalEvent extends Equatable {
  const DisposalEvent();

  @override
  List<Object?> get props => [];
}

final class DisposalStarted extends DisposalEvent {
  const DisposalStarted({required this.userId});

  final String userId;

  @override
  List<Object?> get props => [userId];
}

final class DisposalDropOffSelected extends DisposalEvent {
  const DisposalDropOffSelected(this.dropOffId);

  final String dropOffId;

  @override
  List<Object?> get props => [dropOffId];
}

final class DisposalPhotoSelected extends DisposalEvent {
  const DisposalPhotoSelected(this.photoBytes);

  final List<int> photoBytes;

  @override
  List<Object?> get props => [photoBytes];
}

final class DisposalVolumeChanged extends DisposalEvent {
  const DisposalVolumeChanged(this.liters);

  final double liters;

  @override
  List<Object?> get props => [liters];
}

final class DisposalStepChanged extends DisposalEvent {
  const DisposalStepChanged(this.step);

  final int step;

  @override
  List<Object?> get props => [step];
}

final class DisposalSubmitRequested extends DisposalEvent {
  const DisposalSubmitRequested();
}

final class DisposalQrScanTapped extends DisposalEvent {
  const DisposalQrScanTapped();
}
