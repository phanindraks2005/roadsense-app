import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart' as ll;
import 'package:geolocator/geolocator.dart';

import '../config.dart';
import '../theme.dart';
import '../models/bump.dart';
import '../models/trip_point.dart';
import '../services/api_service.dart';
import '../services/location_service.dart';
import '../services/overpass_service.dart';
import '../services/csv_export_service.dart';
import '../services/voice_alert_service.dart';
import '../widgets/speed_card.dart';
import '../widgets/location_card.dart';
import '../widgets/bump_warning_banner.dart';
import '../widgets/navigation_arrow_marker.dart';
import '../widgets/bump_marker_icon.dart';
import '../widgets/control_panel.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final MapController _mapController = MapController();
  final ApiService _api = ApiService();
  final LocationService _locationService = LocationService();
  final OverpassService _overpass = OverpassService();
  final CsvExportService _csvExport = CsvExportService();
  final VoiceAlertService _voice = VoiceAlertService();

  final _startController = TextEditingController();
  final _destinationController = TextEditingController();

  StreamSubscription<LiveFix>? _positionSub;
  Timer? _dataCollectionTimer;
  Timer? _tripTimerTicker;

  bool _tracking = false;
  bool _detecting = false;
  DateTime? _startTime;
  Duration _tripDuration = Duration.zero;

  List<TripPoint> _tripData = [];
  List<Bump> _bumps = [];
  List<NearbyPlace> _nearbyPlaces = [];

  double? _lat;
  double? _lng;
  double _speedKmh = 0;
  double? _heading;

  double? _nearestBumpDistance;
  bool _voiceEnabled = true;

  // Tracks which bumps we've already spoken a warning for, so we don't
  // repeat it every GPS tick — cleared once you move out of range again.
  final Set<int> _warnedFar = {};
  final Set<int> _warnedClose = {};

  String _trackingStatusTitle = 'Tracker Ready';
  String _trackingStatusMessage = 'Start tracking to collect GPS data.';
  String _connectionText = 'Ready';

  static const ll.LatLng _defaultCenter = ll.LatLng(12.9716, 77.5946); // Bengaluru

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    await _voice.init();
    await _loadBumps();
    try {
      await _locationService.ensureReady();
      final pos = await _locationService.getCurrentPosition();
      setState(() {
        _lat = pos.latitude;
        _lng = pos.longitude;
      });
      _mapController.move(ll.LatLng(pos.latitude, pos.longitude), 16);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(e.toString())));
      }
    }
  }

  Future<void> _loadBumps() async {
    try {
      final bumps = await _api.getBumps();
      if (!mounted) return;
      setState(() => _bumps = bumps);

      if (bumps.isNotEmpty) {
        final bounds = LatLngBounds.fromPoints(
          bumps.map((b) => ll.LatLng(b.lat, b.lng)).toList(),
        );
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _mapController.fitCamera(
            CameraFit.bounds(bounds: bounds, padding: const EdgeInsets.all(80)),
          );
        });
      }
    } catch (e) {
      debugPrint('Could not load bump markers: $e');
    }
  }

  Future<void> _startTracking() async {
    if (_tracking || _detecting) return;

    try {
      await _locationService.ensureReady();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(e.toString())));
      }
      return;
    }

    setState(() {
      _tracking = true;
      _tripData = [];
      _startTime = DateTime.now();
      _tripDuration = Duration.zero;
      _trackingStatusTitle = 'Tracking Active';
      _trackingStatusMessage = 'Collecting GPS data every second...';
      _connectionText = 'GPS Active';
    });

    _tripTimerTicker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (_startTime == null) return;
      setState(() {
        _tripDuration = DateTime.now().difference(_startTime!);
      });
    });

    _positionSub = _locationService.watch().listen(
      _onPositionUpdate,
      onError: (e) {
        setState(() {
          _connectionText = 'GPS Error';
          _trackingStatusMessage = 'Unable to get GPS location.';
        });
      },
    );

    // Save + upload one reading per second, same cadence as app.js.
    _dataCollectionTimer = Timer.periodic(AppConfig.readingInterval, (_) {
      if (!_tracking || _lat == null || _lng == null) return;

      final reading = TripPoint(
        timestamp: DateTime.now().toUtc().toIso8601String(),
        lat: _lat!,
        lng: _lng!,
        speedKmh: _speedKmh,
      );

      setState(() => _tripData = [..._tripData, reading]);
      _api.sendTripData(reading);
    });
  }

  void _onPositionUpdate(LiveFix fix) {
    setState(() {
      _lat = fix.lat;
      _lng = fix.lng;
      _speedKmh = fix.speedKmh;
      if (fix.headingDeg != null) _heading = fix.headingDeg;
      _connectionText = 'GPS Active';
    });

    _mapController.move(ll.LatLng(fix.lat, fix.lng), 17);
    _overpass.fetchDebounced(fix.lat, fix.lng, (places) {
      if (mounted) setState(() => _nearbyPlaces = places);
    });
    _checkNearbyBumps(fix.lat, fix.lng);
  }

  void _checkNearbyBumps(double lat, double lng) {
    if (_bumps.isEmpty) {
      setState(() => _nearestBumpDistance = null);
      return;
    }

    Bump? nearestBump;
    double nearest = double.infinity;
    for (final b in _bumps) {
      final d = Geolocator.distanceBetween(lat, lng, b.lat, b.lng);
      if (d < nearest) {
        nearest = d;
        nearestBump = b;
      }
    }

    setState(() {
      _nearestBumpDistance =
          nearest <= AppConfig.bumpWarningRadiusMeters ? nearest : null;
    });

    if (nearestBump != null) {
      _handleVoiceAlert(nearestBump, nearest);
    }
  }

  void _handleVoiceAlert(Bump bump, double distance) {
    if (distance <= AppConfig.voiceAlertCloseMeters) {
      if (!_warnedClose.contains(bump.id)) {
        _warnedClose.add(bump.id);
        _voice.speak('Speed bump now');
      }
    } else if (distance <= AppConfig.voiceAlertRadiusMeters) {
      if (!_warnedFar.contains(bump.id)) {
        _warnedFar.add(bump.id);
        _voice.speak('Speed bump ahead in ${distance.round()} meters');
      }
    } else {
      // Out of range again — allow this bump to trigger a fresh
      // warning next time you approach it (e.g. a loop or return trip).
      _warnedFar.remove(bump.id);
      _warnedClose.remove(bump.id);
    }
  }

  void _stopTracking() {
    if (!_tracking) return;

    _positionSub?.cancel();
    _dataCollectionTimer?.cancel();
    _tripTimerTicker?.cancel();

    setState(() {
      _tracking = false;
      _trackingStatusTitle = 'Tracking Stopped';
      _trackingStatusMessage = '${_tripData.length} GPS readings collected.';
      _connectionText = 'Ready';
      _speedKmh = 0;
    });

    _runDetection();
  }

  Future<void> _runDetection() async {
    if (_tripData.isEmpty) return;

    final readings = _tripData.length;
    setState(() {
      _detecting = true;
      _trackingStatusTitle = 'Analyzing Trip';
      _trackingStatusMessage =
          'Running bump detection. This can take a minute or two if the server is waking up.';
    });

    try {
      final detected = await _api.runDetection();
      await _loadBumps();
      if (!mounted) return;
      setState(() {
        _trackingStatusTitle = 'Trip Analyzed';
        _trackingStatusMessage =
            '$readings GPS readings collected, $detected bump${detected == 1 ? '' : 's'} detected.';
      });
    } catch (e) {
      debugPrint('Bump detection failed: $e');
      if (!mounted) return;
      setState(() {
        _trackingStatusTitle = 'Detection Failed';
        _trackingStatusMessage =
            'Could not reach the server. $readings GPS readings collected.';
      });
    } finally {
      if (mounted) setState(() => _detecting = false);
    }
  }

  Future<void> _downloadCsv() async {
    try {
      await _csvExport.exportAndShare(_tripData);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(e.toString())));
      }
    }
  }

  String get _tripTimeText {
    final minutes = _tripDuration.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = _tripDuration.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  String get _locationText {
    if (_lat == null || _lng == null) return 'Waiting for GPS...';
    return '${_lat!.toStringAsFixed(6)}, ${_lng!.toStringAsFixed(6)}';
  }

  @override
  void dispose() {
    _positionSub?.cancel();
    _dataCollectionTimer?.cancel();
    _tripTimerTicker?.cancel();
    _overpass.dispose();
    _voice.dispose();
    _startController.dispose();
    _destinationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final userLatLng = (_lat != null && _lng != null)
        ? ll.LatLng(_lat!, _lng!)
        : _defaultCenter;

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            _buildNavbar(),
            Expanded(
              child: Stack(
                children: [
                  // Map fills the whole remaining area; the control
                  // panel floats on top as a draggable bottom sheet
                  // (matches the split layout collapsing into a
                  // stacked mobile view).
                  Positioned.fill(
                    child: _buildMap(userLatLng),
                  ),
                  Positioned(
                    left: 16,
                    top: 12,
                    right: 90,
                    child: LocationCard(text: _locationText),
                  ),
                  Positioned(
                    right: 16,
                    top: 12,
                    child: SpeedCard(speedKmh: _speedKmh),
                  ),
                  if (_nearestBumpDistance != null)
                    Positioned(
                      top: 70,
                      left: 0,
                      right: 0,
                      child: Center(
                        child: BumpWarningBanner(
                          distanceMeters: _nearestBumpDistance!,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
      bottomSheet: DraggableScrollableSheet(
        initialChildSize: 0.42,
        minChildSize: 0.18,
        maxChildSize: 0.85,
        builder: (context, scrollController) {
          return SingleChildScrollView(
            controller: scrollController,
            child: ControlPanel(
              startController: _startController,
              destinationController: _destinationController,
              readingCount: _tripData.length,
              tripTime: _tripTimeText,
              isTracking: _tracking,
              isDetecting: _detecting,
              hasTripData: _tripData.isNotEmpty,
              trackingStatusTitle: _trackingStatusTitle,
              trackingStatusMessage: _trackingStatusMessage,
              onStart: _startTracking,
              onStop: _stopTracking,
              onDownload: _downloadCsv,
            ),
          );
        },
      ),
    );
  }

  Widget _buildNavbar() {
    return Container(
      height: 64,
      padding: const EdgeInsets.symmetric(horizontal: 18),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(bottom: BorderSide(color: AppColors.border)),
      ),
      child: Row(
        children: [
          const Icon(Icons.map, color: AppColors.primary, size: 32),
          const SizedBox(width: 10),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text('RoadSense',
                    style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
                Text('Road Safety Detection',
                    style: TextStyle(fontSize: 10, color: AppColors.textSecondary)),
              ],
            ),
          ),
          IconButton(
            onPressed: () {
              setState(() => _voiceEnabled = !_voiceEnabled);
              _voice.setEnabled(_voiceEnabled);
            },
            tooltip: _voiceEnabled ? 'Mute voice warnings' : 'Unmute voice warnings',
            icon: Icon(
              _voiceEnabled ? Icons.volume_up : Icons.volume_off,
              color: _voiceEnabled ? AppColors.primary : AppColors.textSecondary,
              size: 20,
            ),
          ),
          Row(
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: _tracking ? AppColors.dotActive : AppColors.dotIdle,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 6),
              Text(_connectionText,
                  style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMap(ll.LatLng userLatLng) {
    return FlutterMap(
      mapController: _mapController,
      options: MapOptions(
        initialCenter: userLatLng,
        initialZoom: 16,
        maxZoom: 19,
      ),
      children: [
        TileLayer(
          urlTemplate: 'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png',
          subdomains: const ['a', 'b', 'c'],
          userAgentPackageName: 'com.roadsense.app',
        ),
        MarkerLayer(
          markers: [
            // Nearby named places.
            for (final place in _nearbyPlaces)
              Marker(
                point: ll.LatLng(place.lat, place.lng),
                width: 26,
                height: 26,
                child: GestureDetector(
                  onTap: () => _showPlaceSheet(place),
                  child: const Icon(Icons.place, color: AppColors.textSecondary, size: 22),
                ),
              ),

            // Detected speed bumps.
            for (final bump in _bumps)
              Marker(
                point: ll.LatLng(bump.lat, bump.lng),
                width: 32,
                height: 32,
                child: GestureDetector(
                  onTap: () => _showBumpSheet(bump),
                  child: const BumpMarkerIcon(),
                ),
              ),

            // Live user position with rotating heading arrow.
            if (_lat != null && _lng != null)
              Marker(
                point: ll.LatLng(_lat!, _lng!),
                width: 44,
                height: 44,
                child: NavigationArrowMarker(headingDeg: _heading),
              ),
          ],
        ),
      ],
    );
  }

  void _showPlaceSheet(NearbyPlace place) {
    showModalBottomSheet(
      context: context,
      builder: (_) => Padding(
        padding: const EdgeInsets.all(20),
        child: Text(place.name, style: const TextStyle(fontWeight: FontWeight.w600)),
      ),
    );
  }

  void _showBumpSheet(Bump bump) {
    showModalBottomSheet(
      context: context,
      builder: (_) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('⚠ Speed Bump Detected',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 12),
            Text('Confidence: ${(bump.confidence * 100).toStringAsFixed(0)}%'),
            Text('Speed before: ${bump.speedBefore.toStringAsFixed(1)} km/h'),
            Text('Minimum speed: ${bump.minimumSpeed.toStringAsFixed(1)} km/h'),
            Text('Speed drop: ${bump.speedDropPct.toStringAsFixed(1)}%'),
            Text('Confirmed: ${bump.confirmed ? "Yes" : "No"} (${bump.detectionCount} detections)'),
          ],
        ),
      ),
    );
  }
}
