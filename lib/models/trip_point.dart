class TripPoint {
  final String timestamp;
  final double lat;
  final double lng;
  final double speedKmh;
  final String tripId;

  TripPoint({
    required this.timestamp,
    required this.lat,
    required this.lng,
    required this.speedKmh,
    this.tripId = 'default',
  });

  Map<String, dynamic> toJson() => {
        'timestamp': timestamp,
        'lat': lat,
        'lng': lng,
        'speed': speedKmh,
        'trip_id': tripId,
      };
}

class NearbyPlace {
  final String name;
  final double lat;
  final double lng;

  NearbyPlace({required this.name, required this.lat, required this.lng});
}
