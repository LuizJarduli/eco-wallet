import 'package:eco_wallet/features/disposal/domain/entities/disposal_submission.dart';
import 'package:eco_wallet/features/disposal/domain/entities/drop_off_point.dart';
import 'package:eco_wallet/features/disposal/domain/entities/reward_rule.dart';

class CreateDisposalInput {
  const CreateDisposalInput({
    required this.userId,
    required this.dropOffId,
    required this.photoBytes,
    required this.estimatedLiters,
    required this.captureLatitude,
    required this.captureLongitude,
  });

  final String userId;
  final String dropOffId;
  final List<int> photoBytes;
  final double estimatedLiters;
  final double captureLatitude;
  final double captureLongitude;
}

typedef DisposalSubmissionChanged = void Function(DisposalSubmission submission);

abstract class DisposalRepository {
  Future<List<DropOffPoint>> fetchActiveDropOffPoints();

  Future<RewardRule?> fetchActiveRewardRule();

  Future<DisposalSubmission> createSubmission(CreateDisposalInput input);

  Future<void> requestConfidenceScore({
    required String submissionId,
    required String accessToken,
  });

  Future<List<DisposalSubmission>> fetchMySubmissions({required String userId});

  Future<DisposalSubmission?> fetchSubmissionById({
    required String userId,
    required String submissionId,
  });

  void subscribeToMySubmissions({
    required String userId,
    required DisposalSubmissionChanged onChanged,
  });

  void unsubscribeFromMySubmissions();
}
