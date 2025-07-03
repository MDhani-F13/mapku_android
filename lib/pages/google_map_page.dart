import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:flutter_typeahead/flutter_typeahead.dart';
import 'package:geocoding/geocoding.dart';

import '../services/place_service.dart';
import '../services/traffic_service.dart';
import '../services/traffic_updater.dart'; 
import '../widgets/closed_road_polyline.dart';
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
  final TrafficUpdater _trafficUpdater = TrafficUpdater(); // 

  double _currentZoom = 15.0;
  Set<Polyline> _polylines = {};
  Set<Marker> _markers = {};

  @override
  void initState() {
    super.initState();
    _loadTrafficData();
    _trafficUpdater.startPeriodicUpdates(
      onUpdate: (segments) {
        _buildMapObjects(segments);
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
      _buildMapObjects(segments);
    } catch (e) {
      print("Failed to load traffic data: $e");
    }
  }

  void _buildMapObjects(List<TrafficSegment> segments) {
    final Set<Polyline> polylineSet = {};
    final Set<Marker> markerSet = {};

    for (final segment in segments) {
      if (segment.fromLat != null && segment.toLat != null) {
        polylineSet.add(ClosedRoadPolyline.draw(segment));
      }
      if (segment.singleLat != null && segment.singleLng != null) {
        markerSet.add(ClosedRoadMarker.build(segment));
      }
    }

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
