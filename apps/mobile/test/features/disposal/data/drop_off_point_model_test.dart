import 'package:flutter_test/flutter_test.dart';

import 'package:eco_wallet/features/disposal/data/models/drop_off_point_model.dart';

void main() {
  test('maps active drop-off row to domain entity', () {
    final entity = DropOffPointModel.fromJson({
      'id': 'drop-1',
      'name': 'Cozinha Principal',
      'campus': 'UniFacens',
      'address': 'Campus',
      'latitude': '-23.476700',
      'longitude': '-47.428900',
    }).toEntity();

    expect(entity.id, 'drop-1');
    expect(entity.name, 'Cozinha Principal');
    expect(entity.latitude, closeTo(-23.4767, 0.0001));
    expect(entity.longitude, closeTo(-47.4289, 0.0001));
  });
}
