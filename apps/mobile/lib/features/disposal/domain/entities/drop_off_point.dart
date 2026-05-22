import 'package:equatable/equatable.dart';

class DropOffPoint extends Equatable {
  const DropOffPoint({
    required this.id,
    required this.name,
    required this.campus,
    required this.latitude,
    required this.longitude,
    this.address,
  });

  final String id;
  final String name;
  final String campus;
  final String? address;
  final double latitude;
  final double longitude;

  @override
  List<Object?> get props => [id, name, campus, address, latitude, longitude];
}
