import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../config.dart';
import '../models/bump.dart';
import '../models/trip_point.dart';

class ApiService {
  final String baseUrl;

  ApiService({this.baseUrl = AppConfig.apiBaseUrl});

  /// POST /trip-data — send one GPS reading. Fire-and-forget style,
  /// same as the original app.js (errors are logged, not fatal).
  Future<void> sendTripData(TripPoint point) async {
    try {
      final response = await http
          .post(
            Uri.parse('$baseUrl/trip-data'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode(point.toJson()),
          )
          .timeout(const Duration(seconds: 8));

      if (response.statusCode != 200) {
        debugPrint('Backend returned HTTP ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('Backend connection error: $e');
    }
  }

  /// GET /bumps — all detected bumps (matches loadBumpMarkers()).
  Future<List<Bump>> getBumps() async {
    final response = await http
        .get(Uri.parse('$baseUrl/bumps'))
        .timeout(const Duration(seconds: 10));

    if (response.statusCode != 200) {
      throw Exception('Failed to fetch bumps (${response.statusCode})');
    }

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    final list = (data['bumps'] as List<dynamic>? ?? []);
    return list
        .map((e) => Bump.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// POST /detect-bumps — trigger the ML detection pass on whatever
  /// trip data has been uploaded so far. Not called automatically by
  /// the original prototype's frontend, but exposed here in case you
  /// want a "Run Detection" button.
  Future<int> runDetection() async {
    final response = await http
        .post(Uri.parse('$baseUrl/detect-bumps'))
        .timeout(const Duration(seconds: 30));

    if (response.statusCode != 200) {
      throw Exception('Detection failed (${response.statusCode})');
    }

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    return (data['bumps_detected'] as num?)?.toInt() ?? 0;
  }
}
