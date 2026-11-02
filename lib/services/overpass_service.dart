import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config.dart';
import '../models/trip_point.dart';

class OverpassService {
  Timer? _debounce;

  /// Debounced nearby-places lookup, same behavior as the original
  /// setTimeout(..., 1000) debounce in loadNearbyPlaces().
  void fetchDebounced(
    double lat,
    double lng,
    void Function(List<NearbyPlace>) onResult,
  ) {
    _debounce?.cancel();
    _debounce = Timer(AppConfig.nearbyPlacesDebounce, () async {
      try {
        final places = await _fetch(lat, lng);
        onResult(places);
      } catch (e) {
        // ignore: avoid_print
        print('Nearby places error: $e');
      }
    });
  }

  Future<List<NearbyPlace>> _fetch(double lat, double lng) async {
    final radius = AppConfig.nearbyPlacesRadiusMeters;

    final query = '''
      [out:json][timeout:10];
      (
        node["name"](around:$radius,$lat,$lng);
        way["name"](around:$radius,$lat,$lng);
      );
      out center;
    ''';

    final response = await http
        .post(
          Uri.parse('https://overpass-api.de/api/interpreter'),
          body: query,
        )
        .timeout(const Duration(seconds: 15));

    if (response.statusCode != 200) {
      throw Exception('Overpass request failed (${response.statusCode})');
    }

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    final elements = data['elements'] as List<dynamic>? ?? [];

    final places = <NearbyPlace>[];

    for (final el in elements) {
      final tags = el['tags'] as Map<String, dynamic>? ?? {};
      final name = tags['name'] as String?;
      if (name == null) continue;

      double? elLat = (el['lat'] as num?)?.toDouble();
      double? elLng = (el['lon'] as num?)?.toDouble();

      if ((elLat == null || elLng == null) && el['center'] != null) {
        final center = el['center'] as Map<String, dynamic>;
        elLat = (center['lat'] as num?)?.toDouble();
        elLng = (center['lon'] as num?)?.toDouble();
      }

      if (elLat == null || elLng == null) continue;

      places.add(NearbyPlace(name: name, lat: elLat, lng: elLng));
    }

    return places;
  }

  void dispose() {
    _debounce?.cancel();
  }
}
