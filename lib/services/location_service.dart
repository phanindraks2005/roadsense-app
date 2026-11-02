import 'package:geolocator/geolocator.dart';

class LiveFix {
  final double lat;
  final double lng;
  final double speedKmh;
  final double accuracy;
  final double? headingDeg;

  LiveFix({
    required this.lat,
    required this.lng,
    required this.speedKmh,
    required this.accuracy,
    required this.headingDeg,
  });
}

class LocationService {
  /// Checks/requests permission and makes sure location services are on.
  /// Throws a String message if it can't proceed — show that to the user.
  Future<void> ensureReady() async {
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      throw 'Location services are turned off. Please enable GPS.';
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        throw 'Location permission was denied. Please allow location access.';
      }
    }

    if (permission == LocationPermission.deniedForever) {
      throw 'Location permission is permanently denied. '
          'Enable it from app settings.';
    }
  }

  Future<Position> getCurrentPosition() {
    return Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.best,
      ),
    );
  }

  /// Continuous position stream, mirroring watchPosition() in app.js.
  Stream<LiveFix> watch() {
    const settings = LocationSettings(
      accuracy: LocationAccuracy.best,
      distanceFilter: 0,
    );

    return Geolocator.getPositionStream(locationSettings: settings)
        .map((position) {
      // GPS speed is m/s -> convert to km/h, same as app.js.
      final speedKmh = (position.speed.isFinite && position.speed >= 0)
          ? position.speed * 3.6
          : 0.0;

      return LiveFix(
        lat: position.latitude,
        lng: position.longitude,
        speedKmh: speedKmh,
        accuracy: position.accuracy,
        headingDeg: position.heading.isFinite ? position.heading : null,
      );
    });
  }
}
