import 'package:flutter_test/flutter_test.dart';

import 'package:eco_wallet/features/disposal/data/models/disposal_submission_model.dart';
import 'package:eco_wallet/features/disposal/domain/entities/disposal_submission.dart';

void main() {
  test('maps Supabase row to domain submission with submitted status', () {
    final entity = DisposalSubmissionModel.fromJson({
      'id': 'submission-1',
      'drop_off_id': 'drop-1',
      'storage_path': 'user-1/submission-1.jpg',
      'status': 'submitted',
      'submitted_at': '2026-05-18T12:00:00.000Z',
      'updated_at': '2026-05-18T12:00:00.000Z',
      'estimated_liters': '1.50',
      'capture_latitude': '-23.476700',
      'capture_longitude': '-47.428900',
    }).toEntity();

    expect(entity.id, 'submission-1');
    expect(entity.dropOffId, 'drop-1');
    expect(entity.storagePath, 'user-1/submission-1.jpg');
    expect(entity.status, DisposalStatus.submitted);
    expect(entity.estimatedLiters, 1.5);
    expect(entity.captureLatitude, closeTo(-23.4767, 0.0001));
    expect(entity.captureLongitude, closeTo(-47.4289, 0.0001));
  });
}
