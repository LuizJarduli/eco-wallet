import 'package:geolocator/geolocator.dart';

import 'package:eco_wallet/core/errors/disposal_exception.dart';

class CaptureCoordinates {
  const CaptureCoordinates({
    required this.latitude,
    required this.longitude,
  });

  final double latitude;
  final double longitude;
}

abstract class DisposalLocationProvider {
  Future<CaptureCoordinates> getCurrentPosition();
}

class GeolocatorDisposalLocationProvider implements DisposalLocationProvider {
  @override
  Future<CaptureCoordinates> getCurrentPosition() async {
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      throw const DisposalException(
        'Ative a localização do dispositivo para registrar o descarte.',
      );
    }

    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      throw const DisposalException(
        'Permita o acesso à localização para registrar o descarte.',
      );
    }

    final position = await Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        timeLimit: Duration(seconds: 12),
      ),
    );

    return CaptureCoordinates(
      latitude: position.latitude,
      longitude: position.longitude,
    );
  }
}
