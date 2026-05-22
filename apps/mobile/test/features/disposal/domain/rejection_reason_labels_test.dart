import 'package:flutter_test/flutter_test.dart';

import 'package:eco_wallet/features/disposal/data/models/disposal_submission_model.dart';
import 'package:eco_wallet/features/disposal/domain/entities/rejection_reason.dart';
import 'package:eco_wallet/features/disposal/domain/utils/rejection_reason_labels.dart';

void main() {
  test('parseRejectionReasonCode maps snake_case codes', () {
    expect(
      parseRejectionReasonCode('unclear_photo'),
      RejectionReasonCode.unclearPhoto,
    );
    expect(parseRejectionReasonCode('unknown'), isNull);
  });

  test('rejectionReasonLabel returns localized pt-BR copy', () {
    expect(
      rejectionReasonLabel(RejectionReasonCode.notOil),
      'A foto não parece ser de óleo de cozinha usado.',
    );
  });

  test('DisposalSubmissionModel maps rejection_reason to localized label', () {
    final entity = DisposalSubmissionModel.fromJson({
      'id': 'submission-1',
      'drop_off_id': 'drop-1',
      'storage_path': 'user-1/submission-1.jpg',
      'status': 'rejected',
      'submitted_at': '2026-05-18T12:00:00.000Z',
      'updated_at': '2026-05-19T12:00:00.000Z',
      'rejection_reason': 'below_min_volume',
    }).toEntity();

    expect(entity.rejectionReason, RejectionReasonCode.belowMinVolume);
    expect(
      rejectionReasonLabel(entity.rejectionReason!),
      'O volume informado está abaixo do mínimo.',
    );
  });
}
