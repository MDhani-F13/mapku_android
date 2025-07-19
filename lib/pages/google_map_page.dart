import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:flutter_typeahead/flutter_typeahead.dart';
import 'package:geocoding/geocoding.dart';
import '../widgets/from_to_search_bar.dart';
import '../services/directions_service.dart';
import '../services/place_service.dart';
import '../services/traffic_service.dart';
import '../services/traffic_updater.dart';
import '../widgets/closed_road_polyline.dart';
import '../widgets/closed_road_info_marker.dart';
import '../widgets/closed_road_marker.dart';
import '../models/traffic_segment.dart';
import 'profile_page.dart';

class MapPage extends StatefulWidget {
  @override
  _MapPageState createState() => _MapPageState();
}

class _MapPageState extends State<MapPage> {
  late GoogleMapController mapController;
  final TextEditingController _searchController = TextEditingController();
  final LatLng _initialPosition = LatLng(-7.2809, 112.7932);
  final _placeService = PlaceService();
  final _trafficService = TrafficService();
  final TrafficUpdater _trafficUpdater = TrafficUpdater();
  final TextEditingController _fromController = TextEditingController();
  final TextEditingController _toController = TextEditingController();

  double _currentZoom = 15.0;
  Set<Polyline> _polylines = {};
  Set<Marker> _markers = {};
  Set<Polyline> _routePolylines = {};

  @override
  void initState() {
    super.initState();
    _loadTrafficData();
    _trafficUpdater.startPeriodicUpdates(
      onUpdate: (segments) async {
        await _buildMapObjects(segments);
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
      final segments = await _trafficUpdater.loadValidSegments();
      await _buildMapObjects(segments);
    } catch (e) {
      print("Failed to load traffic data: $e");
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

        // ➜ Tambah marker info di tengah polyline
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
      print("Search error: $e");
    }
  }
  Future<void> _findRoute() async {
    try {
      // Gunakan geocoding basic:
      final from = await locationFromAddress(_fromController.text);
      final to = await locationFromAddress(_toController.text);

      if (from.isEmpty || to.isEmpty) {
        print('Alamat tidak valid');
        return;
      }

      final routes = await DirectionsService.getRoutes(
        from: LatLng(from.first.latitude, from.first.longitude),
        to: LatLng(to.first.latitude, to.first.longitude),
      );

      final polylineList = routes.map((r) {
        return Polyline(
          polylineId: PolylineId('route_${routes.indexOf(r)}'),
          points: r,
          color: const Color(0xFF2196F3), // Biru
          width: 4,
        );
      }).toList();

      setState(() {
        _routePolylines = polylineList.toSet();
      });

      // Zoom ke FROM
      mapController.animateCamera(CameraUpdate.newLatLngZoom(
        LatLng(from.first.latitude, from.first.longitude),
        14,
      ));

    } catch (e) {
      print('Failed to find route: $e');
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
            polylines: _polylines,
            markers: _markers,
            myLocationEnabled: true,
            zoomControlsEnabled: false,
          ),
          Positioned(
            top: 10,
            left: 10,
            right: 10,
            child: Row(
              children: [
                Expanded(
                  child: TypeAheadField(
                    textFieldConfiguration: TextFieldConfiguration(
                      controller: _searchController,
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: Colors.white,
                        hintText: 'Cari jalan/tempat...',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8.0),
                        ),
                        contentPadding: const EdgeInsets.all(10),
                      ),
                    ),
                    suggestionsCallback: (pattern) async =>
                        await _placeService.fetchSuggestions(pattern),
                    itemBuilder: (context, suggestion) =>
                        ListTile(title: Text(suggestion)),
                    onSuggestionSelected: _searchPlace,
                  ),
                ),
                const SizedBox(width: 10),
                CircleAvatar(
                  radius: 20,
                  backgroundColor: Colors.white,
                  child: IconButton(
                    icon: const Icon(Icons.person, size: 20),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => ProfilePage()),
                      );
                    },
                  ),
                ),
              ],
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
        ],
      ),
    );
  }
}
