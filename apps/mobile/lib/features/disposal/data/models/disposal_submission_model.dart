import 'package:eco_wallet/features/disposal/domain/entities/disposal_submission.dart';
import 'package:eco_wallet/features/disposal/domain/entities/rejection_reason.dart';
import 'package:eco_wallet/features/disposal/domain/utils/rejection_reason_labels.dart';

class DisposalSubmissionModel {
  const DisposalSubmissionModel({
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

  factory DisposalSubmissionModel.fromJson(Map<String, dynamic> json) {
    final dropOff = json['drop_off_points'];
    return DisposalSubmissionModel(
      id: json['id'] as String,
      dropOffId: json['drop_off_id'] as String,
      storagePath: json['storage_path'] as String,
      status: _parseStatus(json['status'] as String),
      submittedAt: DateTime.parse(json['submitted_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
      dropOffName:
          dropOff is Map<String, dynamic> ? dropOff['name'] as String? : null,
      estimatedLiters: _optionalDouble(json['estimated_liters']),
      captureLatitude: _optionalDouble(json['capture_latitude']),
      captureLongitude: _optionalDouble(json['capture_longitude']),
      rejectionReason: parseRejectionReasonCode(
        json['rejection_reason'] as String?,
      ),
    );
  }

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

  DisposalSubmission toEntity() {
    return DisposalSubmission(
      id: id,
      dropOffId: dropOffId,
      storagePath: storagePath,
      status: status,
      submittedAt: submittedAt,
      updatedAt: updatedAt,
      dropOffName: dropOffName,
      estimatedLiters: estimatedLiters,
      captureLatitude: captureLatitude,
      captureLongitude: captureLongitude,
      rejectionReason: rejectionReason,
    );
  }

  static DisposalStatus _parseStatus(String raw) {
    return switch (raw) {
      'submitted' => DisposalStatus.submitted,
      'under_review' => DisposalStatus.underReview,
      'approved' => DisposalStatus.approved,
      'awaiting_audit' => DisposalStatus.awaitingAudit,
      'rewarded' => DisposalStatus.rewarded,
      'rejected' => DisposalStatus.rejected,
      _ => DisposalStatus.submitted,
    };
  }

  static double? _optionalDouble(Object? value) {
    if (value == null) {
      return null;
    }
    if (value is num) {
      return value.toDouble();
    }
    return double.parse(value.toString());
  }
}
