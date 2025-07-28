import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:flutter_typeahead/flutter_typeahead.dart';
import 'package:geocoding/geocoding.dart';

import '../services/place_service.dart';
import '../services/traffic_updater.dart';
import '../services/directions_service.dart';
import '../services/map_object_builder.dart';
import '../services/overlap_checker.dart';

import '../utils/debug_logger.dart';
import '../utils/marker_icon_helper.dart';

import '../widgets/closed_road_polyline.dart';

import '../models/traffic_segment.dart';

import 'profile_page.dart';

class MapPage extends StatefulWidget {
  @override
  _MapPageState createState() => _MapPageState();
}

class _MapPageState extends State<MapPage> {
  late GoogleMapController mapController;
  final LatLng _initialPosition = LatLng(-7.2809, 112.7932);
  final _placeService = PlaceService();
  final TrafficUpdater _trafficUpdater = TrafficUpdater();
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _fromController = TextEditingController();
  final TextEditingController _toController = TextEditingController();

  double _currentZoom = 15.0;
  bool _isDirectionMode = false;
  Set<Polyline> _polylines = {};
  Set<Marker> _markers = {};
  Set<Polyline> _routePolylines = {};
  List<TrafficSegment> _segments = [];

  bool _showFromTo = false;

  @override
  void initState() {
    super.initState();
    MarkerIconHelper.instance.loadAll();
    _loadTrafficData();
    _trafficUpdater.startPeriodicUpdates(
      onUpdate: (segments) async {
        final (poly, mark) = await MapObjectBuilder.buildMapObjects(segments);
        setState(() {
          _polylines = poly;
          _markers = mark;
        });
      },
    );
  }

  void _onMapCreated(GoogleMapController controller) {
    mapController = controller;
  }

  void _zoomIn() {
    _currentZoom += 1;
    mapController.moveCamera(CameraUpdate.zoomTo(_currentZoom));
  }

  void _zoomOut() {
    _currentZoom -= 1;
    mapController.moveCamera(CameraUpdate.zoomTo(_currentZoom));
  }

  Future<void> _loadTrafficData() async {
    try {
      _segments = await _trafficUpdater.loadValidSegments();
      final (poly, mark) = await MapObjectBuilder.buildMapObjects(_segments);
      setState(() {
        _polylines = poly;
        _markers = mark;
      });
    } catch (e) {
      DebugLogger().log("Failed to load traffic data: $e");
    }
  }

  Future<void> _searchPlace(String query) async {
    try {
      List<Location> locations = await locationFromAddress(query);
      if (locations.isNotEmpty) {
        final loc = locations.first;
        mapController.animateCamera(
          CameraUpdate.newLatLngZoom(
            LatLng(loc.latitude, loc.longitude),
            16,
          ),
        );
      }
    } catch (e) {
      DebugLogger().log("Search error: $e");
    }
  }

  Future<void> _findRoute() async {
    final stopwatch = Stopwatch()..start();
    await DebugLogger().log('🔵 [_findRoute] Started');

    final fromAddress = _fromController.text.trim();
    final toAddress = _toController.text.trim();

    await DebugLogger().log('📍 From: "$fromAddress"');
    await DebugLogger().log('📍 To: "$toAddress"');

    final placeService = PlaceService();

    final sw1 = Stopwatch()..start();
    final fromLatLng = await placeService.searchPlace(fromAddress);
    await DebugLogger().log(
      fromLatLng != null
        ? '✅ Geocoding FROM success in ${sw1.elapsedMilliseconds}ms'
        : '❌ Geocoding FROM failed',
    );

    final sw2 = Stopwatch()..start();
    final toLatLng = await placeService.searchPlace(toAddress);
    await DebugLogger().log(
      toLatLng != null
        ? '✅ Geocoding TO success in ${sw2.elapsedMilliseconds}ms'
        : '❌ Geocoding TO failed',
    );

    if (fromLatLng == null || toLatLng == null) {
      await DebugLogger().log('❌ Geocoding returned null coordinates → Aborted');
      return;
    }

    try {
      final result = await DirectionsService.findRoute(
        from: fromLatLng,
        to: toLatLng,
        closedPolylines: _polylines,
      );
      // Tandai segmen overlap jika fallback digunakan
      if (result.usedFallback) {
        for (var segment in _segments) {
          final overlap = OverlapChecker.detectOverlap(
            routePolyline: result.polyline,
            closedRoadPolylines: {
              Polyline(
                points: segment.routePolyline != null
                    ? DirectionsService.decodePolyline(segment.routePolyline!)
                    : [],
                polylineId: PolylineId('seg_${segment.id}'),
              ),
            },
          );
          if (overlap.hasOverlap) {
            segment.usedFallback = true;
          }
        }

        final (updatedPolylines, updatedMarkers) = await MapObjectBuilder.buildMapObjects(_segments);
        setState(() {
          _polylines = updatedPolylines;
          _markers = updatedMarkers;
        });
      }
      final startIcon = MarkerIconHelper.instance.start ??
          BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen);
      final endIcon = MarkerIconHelper.instance.end ??
          BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure);
      final routeMarkers = {
        Marker(
          markerId: const MarkerId('start'),
          position: result.polyline.first,
          icon: startIcon,
          infoWindow: const InfoWindow(title: 'Titik Awal'),
        ),
        Marker(
          markerId: const MarkerId('end'),
          position: result.polyline.last,
          icon: endIcon,
          infoWindow: const InfoWindow(title: 'Tujuan'),
        ),
      };
      setState(() {
        _routePolylines = {
          Polyline(
            polylineId: const PolylineId('route_final'),
            points: result.polyline,
            color: const Color(0xFF2196F3),
            width: 5,
            zIndex: 1,
          ),
          ...result.alternatives.map((alt) => Polyline(
                polylineId: PolylineId('alt_${alt.hashCode}'),
                points: alt,
                color: const Color.fromARGB(255, 8, 222, 40),
                width: 3,
                zIndex: 0,
              )),
        };

        _markers.addAll(routeMarkers);
      });

      mapController.animateCamera(CameraUpdate.newLatLngBounds(result.bounds, 50));
      await DebugLogger().log('✅ [_findRoute] Completed in ${stopwatch.elapsedMilliseconds}ms');
    } catch (e, stack) {
      await DebugLogger().log('🔥 [_findRoute] Failed: $e');
      await DebugLogger().log('📄 Stacktrace: $stack');
    }
  }

  void _exitDirectionMode() {
  setState(() {
    _isDirectionMode = false;
    _showFromTo = false;
    _routePolylines.clear();
    _markers.removeWhere((m) => m.markerId.value == 'start' || m.markerId.value == 'end');
    _fromController.clear();
    _toController.clear();
  });
}
  void _logout() {
    Navigator.pushReplacementNamed(context, '/login');
  }

  @override
  void dispose() {
    _trafficUpdater.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Peta Surabaya"),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: "Logout",
            onPressed: _logout,
          )
        ],
      ),
      body: Stack(
        children: [
          GoogleMap(
            onMapCreated: _onMapCreated,
            initialCameraPosition: CameraPosition(
              target: _initialPosition,
              zoom: _currentZoom,
            ),
            polylines: _polylines.union(_routePolylines),
            markers: _markers,
            myLocationEnabled: true,
            zoomControlsEnabled: false,
          ),
          Positioned(
            top: 10,
            left: 10,
            right: 60,
            child: _showFromTo
                ? Row(
                    children: [
                      Expanded(
                        child: Column(
                          children: [
                            TextField(
                              controller: _fromController,
                              decoration: const InputDecoration(
                                hintText: 'Dari...',
                                fillColor: Colors.white,
                                filled: true,
                              ),
                            ),
                            const SizedBox(height: 5),
                            TextField(
                              controller: _toController,
                              decoration: const InputDecoration(
                                hintText: 'Ke...',
                                fillColor: Colors.white,
                                filled: true,
                              ),
                            ),
                            const SizedBox(height: 5),
                            ElevatedButton(
                              onPressed: _findRoute,
                              child: const Text("Cari Rute"),
                            ),
                          ],
                        ),
                      ),
                    ],
                  )
                : TypeAheadField(
                    textFieldConfiguration: TextFieldConfiguration(
                      controller: _searchController,
                      decoration: const InputDecoration(
                        filled: true,
                        fillColor: Colors.white,
                        hintText: 'Cari jalan/tempat...',
                      ),
                    ),
                    suggestionsCallback: (pattern) async =>
                        await _placeService.fetchSuggestions(pattern),
                    itemBuilder: (context, suggestion) =>
                        ListTile(title: Text(suggestion)),
                    onSuggestionSelected: _searchPlace,
                  ),
          ),
          Positioned(
            top: 10,
            right: 10,
            child: CircleAvatar(
              radius: 20,
              backgroundColor: Colors.white,
              child: IconButton(
                icon: Icon(
                  Icons.directions,
                  size: 20,
                  color: _isDirectionMode ? Colors.blueGrey : Colors.black,
                ),
                onPressed: () {
                  setState(() {
                    if (_isDirectionMode) {
                      _exitDirectionMode();
                    } else {
                      _isDirectionMode = true;
                      _showFromTo = true;
                    }
                  });
                },
              ),
            ),
          ),
          Positioned(
            bottom: 20,
            right: 20,
            child: Column(
              children: [
                FloatingActionButton(
                  heroTag: "zoomIn",
                  mini: true,
                  onPressed: _zoomIn,
                  child: const Icon(Icons.add),
                ),
                const SizedBox(height: 10),
                FloatingActionButton(
                  heroTag: "zoomOut",
                  mini: true,
                  onPressed: _zoomOut,
                  child: const Icon(Icons.remove),
                ),
              ],
            ),
          ),
          Positioned(
            bottom: 20,
            left: 20,
            child: FloatingActionButton(
              heroTag: "profileBtn",
              mini: true,
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => ProfilePage()),
                );
              },
              child: const Icon(Icons.person),
            ),
          ),
        ],
      ),
    );
  }
}
