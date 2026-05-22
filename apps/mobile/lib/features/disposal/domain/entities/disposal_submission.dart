import 'package:equatable/equatable.dart';

import 'package:eco_wallet/features/disposal/domain/entities/rejection_reason.dart';

enum DisposalStatus {
  submitted,
  underReview,
  approved,
  awaitingAudit,
  rewarded,
  rejected,
}

class DisposalSubmission extends Equatable {
  const DisposalSubmission({
    required this.id,
    required this.dropOffId,
    required this.storagePath,
    required this.status,
    required this.submittedAt,
    required this.updatedAt,
    this.dropOffName,
    this.estimatedLiters,
    this.captureLatitude,
    this.captureLongitude,
    this.rejectionReason,
  });

  final String id;
  final String dropOffId;
  final String storagePath;
  final DisposalStatus status;
  final DateTime submittedAt;
  final DateTime updatedAt;
  final String? dropOffName;
  final double? estimatedLiters;
  final double? captureLatitude;
  final double? captureLongitude;
  final RejectionReasonCode? rejectionReason;

  String get trackingCode => id.split('-').first.toUpperCase();

  @override
  List<Object?> get props => [
    id,
    dropOffId,
    storagePath,
    status,
    submittedAt,
    updatedAt,
    dropOffName,
    estimatedLiters,
    captureLatitude,
    captureLongitude,
    rejectionReason,
  ];
}
