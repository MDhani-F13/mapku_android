import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:flutter_typeahead/flutter_typeahead.dart';
import 'package:geocoding/geocoding.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../services/place_service.dart';
import '../services/traffic_service.dart';
import '../services/traffic_updater.dart';
import '../services/overlap_checker.dart';
import '../services/detour_service.dart';
import '../services/directions_service.dart';

import '../utils/debug_logger.dart';
import '../utils/marker_icon_helper.dart';

import '../widgets/closed_road_polyline.dart';
import '../widgets/closed_road_marker.dart';
import '../widgets/closed_road_info_marker.dart';
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
  Set<Polyline> _polylines = {};
  Set<Marker> _markers = {};
  Set<Polyline> _routePolylines = {};

  bool _showFromTo = false;

  int _directionsRequestCount = 0;
  final int _maxRequestsPerMonth = 1000;

  @override
  void initState() {
    super.initState();
    MarkerIconHelper.instance.loadAll();
    _loadTrafficData();
    _loadRequestCount();
    _trafficUpdater.startPeriodicUpdates(
      onUpdate: (segments) async {
        await _buildMapObjects(segments);
      },
    );
  }

  Future<void> _loadRequestCount() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _directionsRequestCount = prefs.getInt('directionsRequestCount') ?? 0;
    });
  }

  Future<void> _incrementRequestCount() async {
    final prefs = await SharedPreferences.getInstance();
    _directionsRequestCount++;
    await prefs.setInt('directionsRequestCount', _directionsRequestCount);
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
      final segments = await _trafficUpdater.loadValidSegments();
      await _buildMapObjects(segments);
    } catch (e) {
      DebugLogger().log("Failed to load traffic data: $e");
    }
  }

  Future<void> _buildMapObjects(List<TrafficSegment> segments) async {
    final Set<Polyline> polylineSet = {};
    final Set<Marker> markerSet = {};

    await Future.wait(segments.map((segment) async {
      if (segment.fromLat != null && segment.fromLng != null &&
          segment.toLat != null && segment.toLng != null) {

        if (segment.routePolyline == null || segment.routePolyline!.isEmpty) {
          final fetched = await TrafficService.fetchPolyline(segment.id);
          if (fetched != null) {
            segment.routePolyline = fetched;
          }
        }

        polylineSet.add(ClosedRoadPolyline.draw(segment));
        markerSet.add(ClosedRoadInfoMarker.build(segment));
      }

      if (segment.singleLat != null && segment.singleLng != null) {
        markerSet.add(ClosedRoadMarker.build(segment));
      }
    }));

    setState(() {
      _polylines = polylineSet;
      _markers = markerSet;
    });
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

    try {
      final fromAddress = _fromController.text.trim();
      final toAddress = _toController.text.trim();

      await DebugLogger().log('📍 From: "$fromAddress"');
      await DebugLogger().log('📍 To: "$toAddress"');

      late List<Location> from;
      late List<Location> to;

      try {
        final sw1 = Stopwatch()..start();
        from = await locationFromAddress(fromAddress).timeout(const Duration(seconds: 10));
        await DebugLogger().log('✅ Geocoding FROM success in ${sw1.elapsedMilliseconds}ms');
      } catch (e) {
        await DebugLogger().log('❌ Geocoding FROM failed: $e');
        return;
      }

      try {
        final sw2 = Stopwatch()..start();
        to = await locationFromAddress(toAddress).timeout(const Duration(seconds: 10));
        await DebugLogger().log('✅ Geocoding TO success in ${sw2.elapsedMilliseconds}ms');
      } catch (e) {
        await DebugLogger().log('❌ Geocoding TO failed: $e');
        return;
      }

      if (from.isEmpty || to.isEmpty) {
        await DebugLogger().log('❌ Geocoding returned empty result');
        return;
      }

      final fromLatLng = LatLng(from.first.latitude, from.first.longitude);
      final toLatLng = LatLng(to.first.latitude, to.first.longitude);

      await DebugLogger().log(
        '📌 FROM (${fromLatLng.latitude}, ${fromLatLng.longitude}), '
        'TO (${toLatLng.latitude}, ${toLatLng.longitude})',
      );

      final routes = await DirectionsService.getRoutes(
        from: fromLatLng,
        to: toLatLng,
      );

      await DebugLogger().log('📌 Routes fetched: ${routes.length} alternatives');

      List<Map<String, dynamic>> routeResults = [];

      for (final route in routes) {
        final overlap = OverlapChecker.detectOverlap(
          routePolyline: route,
          closedRoadPolylines: _polylines,
        );
        routeResults.add({'route': route, 'overlap': overlap});

        await DebugLogger().log(
          '🔍 Alt route → hasOverlap: ${overlap.hasOverlap}, '
          'overlapLength: ${overlap.overlapLength}',
        );
      }

      // Urutkan berdasarkan overlap paling sedikit
      routeResults.sort((a, b) =>
          a['overlap'].overlapLength.compareTo(b['overlap'].overlapLength));

      final best = routeResults.first;
      final OverlapResult bestOverlap = best['overlap'];
      List<LatLng> selectedRoute = best['route'];
      bool usedFallback = false;

      await DebugLogger().log(
        '✅ Best candidate → hasOverlap: ${bestOverlap.hasOverlap}, '
        'overlapLength: ${bestOverlap.overlapLength}',
      );

      if (bestOverlap.hasOverlap) {
        await DebugLogger().log(
          '📍 Best entry idx: ${bestOverlap.entryIndex}, exit idx: ${bestOverlap.exitIndex}',
        );

        final detour = await DetourService.getDetour(
          entryPoint: bestOverlap.entryPoint!,
          exitPoint: bestOverlap.exitPoint!,
          closedRoadPolylines: _polylines,
        );

        if (detour != null) {
          selectedRoute = DirectionsService.mergePolylines(
            originalRoute: selectedRoute,
            entryIndex: bestOverlap.entryIndex!,
            exitIndex: bestOverlap.exitIndex!,
            detour: detour.detourPolyline,
          );
          await DebugLogger().log(
            '✅ Detour merged, total points: ${selectedRoute.length}',
          );
        } else {
          await DebugLogger().log(
            '🚧 Fallback → all detours overlap → use original best & mark warning',
          );
          usedFallback = true;
        }
      } else {
        await DebugLogger().log('✅ Best is clean → use as is');
      }

      // Tampilkan semua alternatif sebagai garis tipis
      final altPolylines = routes.asMap().entries.map((entry) {
        return Polyline(
          polylineId: PolylineId('alt_${entry.key}'),
          points: entry.value,
          color: const Color.fromARGB(255, 8, 222, 40),
          width: 3,
          zIndex: 0,
        );
      }).toSet();

      final startIcon = MarkerIconHelper.instance.start ??
          BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen);
      final endIcon = MarkerIconHelper.instance.end ??
          BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure);
      final warningIcon = MarkerIconHelper.instance.warning ??
          BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed);

      final Set<Marker> updatedMarkers = {
        Marker(
          markerId: const MarkerId('start'),
          position: fromLatLng,
          icon: startIcon,
          infoWindow: const InfoWindow(title: 'Titik Awal'),
        ),
        Marker(
          markerId: const MarkerId('end'),
          position: toLatLng,
          icon: endIcon,
          infoWindow: const InfoWindow(title: 'Tujuan'),
        ),
      };

      if (usedFallback) {
        updatedMarkers.add(
          Marker(
            markerId: const MarkerId('warning_overlap'),
            position: bestOverlap.entryPoint!,
            icon: warningIcon,
            infoWindow: const InfoWindow(title: '⚠️ Jalur Alternatif Melewati Jalan Ditutup'),
          ),
        );
      }

      setState(() {
        _routePolylines = {
          Polyline(
            polylineId: const PolylineId('route_final'),
            points: selectedRoute,
            color: const Color(0xFF2196F3),
            width: 4,
            zIndex: 1,
          ),
          ...altPolylines
        };

        _polylines = _polylines.map((p) {
          return p.copyWith(zIndexParam: 2);
        }).toSet();

        _markers.addAll(updatedMarkers);
      });

      await DebugLogger().log('🗺️ Polylines & markers updated');
      mapController.animateCamera(CameraUpdate.newLatLngZoom(fromLatLng, 14));
      await DebugLogger().log('✅ Camera moved to start point');
      await DebugLogger().log('🏁 [_findRoute] Finished in ${stopwatch.elapsedMilliseconds}ms');
    } catch (e, stack) {
      await DebugLogger().log('🔥 [_findRoute] Failed: $e');
      await DebugLogger().log('📄 Stacktrace: $stack');
    }
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
                icon: const Icon(Icons.directions, size: 20),
                onPressed: () {
                  setState(() {
                    _showFromTo = !_showFromTo;
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
