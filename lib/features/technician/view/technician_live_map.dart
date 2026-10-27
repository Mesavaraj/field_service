import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';

class TechnicianLiveMapScreen extends StatefulWidget {
  const TechnicianLiveMapScreen({
    super.key,
    required this.customerLatitude,
    required this.customerLongitude,
    required this.taskTitle,
    required this.taskStatus,
    this.customerAddress = 'Customer location',
    this.fullScreen = false,
    this.onOpenFullScreen,
  });

  final double customerLatitude;
  final double customerLongitude;
  final String taskTitle;
  final String taskStatus;
  final String customerAddress;

  /// Set true when this widget is displayed as the body of a full-screen page.
  final bool fullScreen;

  /// Supply this callback from the embedded map to open a full-screen route.
  final VoidCallback? onOpenFullScreen;

  @override
  State<TechnicianLiveMapScreen> createState() =>
      _TechnicianLiveMapScreenState();
}

class _TechnicianLiveMapScreenState extends State<TechnicianLiveMapScreen> {
  final MapController _mapController = MapController();

  StreamSubscription<Position>? _positionSubscription;

  Position? _technicianPosition;
  List<LatLng> _routePoints = [];

  String _distance = 'Calculating...';
  String _eta = 'Calculating...';
  String? _error;

  bool _loadingLocation = true;
  bool _loadingRoute = false;
  bool _mapReady = false;

  LatLng? _lastRouteOrigin;
  DateTime? _lastRouteAt;

  LatLng get _customerLocation =>
      LatLng(widget.customerLatitude, widget.customerLongitude);

  @override
  void initState() {
    super.initState();
    _startTracking();
  }

  Future<void> _startTracking() async {
    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        throw Exception('Enable GPS/location services on your device.');
      }

      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        throw Exception('Location permission is required.');
      }

      final initialPosition = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
      );

      if (!mounted) return;

      setState(() {
        _technicianPosition = initialPosition;
        _loadingLocation = false;
      });

      _moveToTechnician(initialPosition);
      unawaited(_fetchRoute(initialPosition));

      _positionSubscription =
          Geolocator.getPositionStream(
            locationSettings: const LocationSettings(
              accuracy: LocationAccuracy.high,
              distanceFilter: 10,
            ),
          ).listen(
            (position) {
              if (!mounted) return;

              setState(() => _technicianPosition = position);
              _moveToTechnician(position);

              final lastOrigin = _lastRouteOrigin;
              final lastAt = _lastRouteAt;
              final enoughTimePassed =
                  lastAt == null ||
                  DateTime.now().difference(lastAt).inSeconds >= 30;
              final movedEnough =
                  lastOrigin == null ||
                  Geolocator.distanceBetween(
                        lastOrigin.latitude,
                        lastOrigin.longitude,
                        position.latitude,
                        position.longitude,
                      ) >=
                      500;

              if (enoughTimePassed && movedEnough) {
                unawaited(_fetchRoute(position));
              }
            },
            onError: (Object error) {
              if (!mounted) return;
              setState(() => _error = 'Unable to read GPS updates.');
            },
          );
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _loadingLocation = false;
        _error = error.toString().replaceFirst('Exception: ', '');
      });
    }
  }

  void _moveToTechnician(Position position) {
    if (!_mapReady) return;

    _mapController.move(LatLng(position.latitude, position.longitude), 15);
  }

  Future<void> _fetchRoute(Position position) async {
    if (_loadingRoute || !mounted) return;

    final origin = LatLng(position.latitude, position.longitude);

    // Record the attempt immediately to avoid repeatedly hitting the demo API
    // when the route service is unavailable.
    _lastRouteOrigin = origin;
    _lastRouteAt = DateTime.now();

    setState(() {
      _loadingRoute = true;
      _error = null;
    });

    try {
      final uri = Uri.https(
        'router.project-osrm.org',
        '/route/v1/driving/'
            '${origin.longitude},${origin.latitude};'
            '${widget.customerLongitude},${widget.customerLatitude}',
        const {'overview': 'full', 'geometries': 'geojson'},
      );

      final response = await http.get(uri).timeout(const Duration(seconds: 15));

      if (response.statusCode != 200) {
        throw Exception('Routing service returned ${response.statusCode}.');
      }

      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final routes = data['routes'] as List<dynamic>? ?? [];

      if (routes.isEmpty) {
        throw Exception('No driving route was found.');
      }

      final route = routes.first as Map<String, dynamic>;
      final geometry = route['geometry'] as Map<String, dynamic>;
      final coordinates = geometry['coordinates'] as List<dynamic>;

      final points = coordinates.map((coordinate) {
        final pair = coordinate as List<dynamic>;
        return LatLng((pair[1] as num).toDouble(), (pair[0] as num).toDouble());
      }).toList();

      final distanceMeters = (route['distance'] as num).toDouble();
      final durationSeconds = (route['duration'] as num).round();

      if (!mounted) return;

      setState(() {
        _routePoints = points;
        _distance = distanceMeters >= 1000
            ? '${(distanceMeters / 1000).toStringAsFixed(1)} km'
            : '${distanceMeters.round()} m';
        _eta = _formatDuration(durationSeconds);
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _error = 'Route unavailable. Check your internet connection.';
        if (_routePoints.isEmpty) {
          _distance = 'Unavailable';
          _eta = 'Unavailable';
        }
      });
    } finally {
      if (mounted) {
        setState(() => _loadingRoute = false);
      }
    }
  }

  String _formatDuration(int seconds) {
    final minutes = (seconds / 60).ceil();
    if (minutes < 60) return '$minutes min';

    final hours = minutes ~/ 60;
    final remainingMinutes = minutes % 60;
    return remainingMinutes == 0
        ? '$hours hr'
        : '$hours hr $remainingMinutes min';
  }

  List<Marker> get _markers {
    final markers = <Marker>[
      Marker(
        point: _customerLocation,
        width: 48,
        height: 48,
        child: const Icon(Icons.location_on, color: Colors.red, size: 42),
      ),
    ];

    final position = _technicianPosition;
    if (position != null) {
      markers.add(
        Marker(
          point: LatLng(position.latitude, position.longitude),
          width: 48,
          height: 48,
          child: const Icon(Icons.navigation, color: Colors.blue, size: 36),
        ),
      );
    }

    return markers;
  }

  Widget _buildMap() {
    return Stack(
      children: [
        FlutterMap(
          mapController: _mapController,
          options: MapOptions(
            initialCenter: _customerLocation,
            initialZoom: 14,
            onMapReady: () {
              _mapReady = true;
              final position = _technicianPosition;
              if (position != null) _moveToTechnician(position);
            },
          ),
          children: [
            TileLayer(
              urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
              // Replace with your Android applicationId.
              userAgentPackageName: 'com.example.fsm',
            ),
            if (_routePoints.isNotEmpty)
              PolylineLayer(
                polylines: [
                  Polyline(
                    points: _routePoints,
                    color: Colors.blue,
                    strokeWidth: 5,
                  ),
                ],
              ),
            MarkerLayer(markers: _markers),
            RichAttributionWidget(
              attributions: [
                TextSourceAttribution('OpenStreetMap contributors'),
              ],
            ),
          ],
        ),
        if (!widget.fullScreen && widget.onOpenFullScreen != null)
          Positioned(
            top: 8,
            right: 8,
            child: Material(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
              elevation: 3,
              child: IconButton(
                tooltip: 'Open full-screen map',
                onPressed: widget.onOpenFullScreen,
                icon: const Icon(Icons.fullscreen),
              ),
            ),
          ),
        Positioned(
          left: 8,
          top: 8,
          child: Material(
            color: Colors.white,
            borderRadius: BorderRadius.circular(10),
            elevation: 2,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 9,
                    height: 9,
                    decoration: const BoxDecoration(
                      color: Colors.blue,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 5),
                  const Text('Technician'),
                  const SizedBox(width: 10),
                  const Icon(Icons.location_on, color: Colors.red, size: 16),
                  const SizedBox(width: 3),
                  const Text('Customer'),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  @override
  void dispose() {
    _positionSubscription?.cancel();
    _mapController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.fullScreen) {
      return Column(
        children: [
          Expanded(child: _buildMap()),
          ConstrainedBox(
            constraints: const BoxConstraints(maxHeight: 300),
            child: SingleChildScrollView(
              child: _buildTaskSummary(compact: false),
            ),
          ),
        ],
      );
    }

    // Compact mode is intended to be placed inside a task-details card.
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(height: 220, child: _buildMap()),
        _buildTaskSummary(compact: true),
      ],
    );
  }

  Widget _buildTaskSummary({required bool compact}) {
    final position = _technicianPosition;
    final from = position == null
        ? (_loadingLocation ? 'Getting GPS location...' : 'GPS unavailable')
        : '${position.latitude.toStringAsFixed(5)}, '
              '${position.longitude.toStringAsFixed(5)}';

    if (compact) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              widget.taskTitle,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 6),
            Row(
              children: [
                const Icon(Icons.circle, color: Colors.green, size: 12),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    'From: $from',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                const Icon(Icons.location_on, color: Colors.red, size: 16),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    'To: ${widget.customerAddress}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(child: _info(Icons.route, 'Distance', _distance)),
                Expanded(
                  child: _info(
                    Icons.access_time,
                    'Driving ETA',
                    _loadingRoute ? 'Updating...' : _eta,
                  ),
                ),
                Flexible(
                  child: Chip(
                    visualDensity: VisualDensity.compact,
                    label: Text(
                      widget.taskStatus,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
              ],
            ),
            if (_loadingLocation) const LinearProgressIndicator(),
            if (_error != null)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  _error!,
                  style: const TextStyle(color: Colors.red, fontSize: 12),
                ),
              ),
          ],
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(widget.taskTitle, style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 8),
          ListTile(
            contentPadding: EdgeInsets.zero,
            dense: true,
            leading: const Icon(Icons.circle, color: Colors.green),
            title: const Text('FROM · Technician'),
            subtitle: Text(from),
          ),
          ListTile(
            contentPadding: EdgeInsets.zero,
            dense: true,
            leading: const Icon(Icons.location_on, color: Colors.red),
            title: const Text('TO · Customer'),
            subtitle: Text(widget.customerAddress),
          ),
          const Divider(),
          Row(
            children: [
              Expanded(child: _info(Icons.route, 'Distance', _distance)),
              Expanded(
                child: _info(
                  Icons.access_time,
                  'Driving ETA',
                  _loadingRoute ? 'Updating...' : _eta,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Chip(label: Text('Task: ${widget.taskStatus}')),
          if (_loadingLocation) const LinearProgressIndicator(),
          if (_error != null)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(_error!, style: const TextStyle(color: Colors.red)),
            ),
        ],
      ),
    );
  }

  Widget _info(IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: Colors.blue, size: 20),
        const SizedBox(width: 6),
        Flexible(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(color: Colors.grey, fontSize: 12),
              ),
              Text(
                value,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
