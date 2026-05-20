import 'package:eco_wallet/features/disposal/domain/entities/drop_off_point.dart';

class DropOffPointModel {
  const DropOffPointModel({
    required this.id,
    required this.name,
    required this.campus,
    required this.latitude,
    required this.longitude,
    this.address,
  });

  factory DropOffPointModel.fromJson(Map<String, dynamic> json) {
    return DropOffPointModel(
      id: json['id'] as String,
      name: json['name'] as String,
      campus: json['campus'] as String,
      address: json['address'] as String?,
      latitude: _toDouble(json['latitude']),
      longitude: _toDouble(json['longitude']),
    );
  }

  final String id;
  final String name;
  final String campus;
  final String? address;
  final double latitude;
  final double longitude;

  DropOffPoint toEntity() {
    return DropOffPoint(
      id: id,
      name: name,
      campus: campus,
      address: address,
      latitude: latitude,
      longitude: longitude,
    );
  }

  static double _toDouble(Object? value) {
    if (value is num) {
      return value.toDouble();
    }
    return double.parse(value.toString());
  }
}
