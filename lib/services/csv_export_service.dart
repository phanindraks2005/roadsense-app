import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../models/trip_point.dart';

class CsvExportService {
  /// Builds the same "timestamp,lat,lng,speed" CSV as downloadCSV() in
  /// app.js, writes it to the app's documents folder, then opens the
  /// share sheet so the user can save it to Files/Drive/WhatsApp/etc.
  /// (Android 10+ scoped storage means there's no direct "Downloads"
  /// write without extra permissions — sharing is the reliable path.)
  Future<void> exportAndShare(List<TripPoint> tripData) async {
    if (tripData.isEmpty) {
      throw 'No trip data available.';
    }

    final buffer = StringBuffer('timestamp,lat,lng,speed\n');
    for (final p in tripData) {
      buffer.writeln(
        '${p.timestamp},${p.lat},${p.lng},${p.speedKmh.toStringAsFixed(2)}',
      );
    }

    final dir = await getApplicationDocumentsDirectory();
    final stamp = DateTime.now()
        .toIso8601String()
        .substring(0, 19)
        .replaceAll(':', '-');
    final file = File('${dir.path}/roadsense_trip_$stamp.csv');
    await file.writeAsString(buffer.toString());

    await Share.shareXFiles(
      [XFile(file.path)],
      subject: 'RoadSense trip data',
    );
  }
}
