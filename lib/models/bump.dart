class Bump {
  final int id;
  final String timestamp;
  final double lat;
  final double lng;
  final double speedBefore;
  final double minimumSpeed;
  final double speedDropPct;
  final double confidence;
  final bool confirmed;
  final int detectionCount;

  Bump({
    required this.id,
    required this.timestamp,
    required this.lat,
    required this.lng,
    required this.speedBefore,
    required this.minimumSpeed,
    required this.speedDropPct,
    required this.confidence,
    required this.confirmed,
    required this.detectionCount,
  });

  factory Bump.fromJson(Map<String, dynamic> json) {
    double asDouble(dynamic v) =>
        v == null ? 0.0 : (v as num).toDouble();

    return Bump(
      id: json['id'] as int,
      timestamp: json['timestamp']?.toString() ?? '',
      lat: asDouble(json['lat']),
      lng: asDouble(json['lng']),
      speedBefore: asDouble(json['speed_before']),
      minimumSpeed: asDouble(json['minimum_speed']),
      speedDropPct: asDouble(json['speed_drop_pct']),
      confidence: asDouble(json['confidence']),
      confirmed: json['confirmed'] == true,
      detectionCount: (json['detection_count'] as num?)?.toInt() ?? 1,
    );
  }
}
