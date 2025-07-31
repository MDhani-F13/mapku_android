import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../../widgets/from_to_search_bar.dart';
import '../../widgets/map_controls.dart';
import '../../widgets/single_search_bar.dart';

import 'map_view.dart';
import '../login_page.dart';
import '../profile_page.dart';

import '../../controllers/map_controller.dart';
import '../../controllers/route_manager.dart';
import '../../controllers/traffic_controller.dart';

import '../../models/traffic_segment.dart';

import '../../utils/marker_icon_helper.dart';

class MapPage extends StatefulWidget {
  const MapPage({super.key});

  @override
  State<MapPage> createState() => _MapPageState();
}

class _MapPageState extends State<MapPage> {
  final mapController = MapController();
  final fromController = TextEditingController();
  final toController = TextEditingController();
  final singleSearchController = TextEditingController();

  late final TrafficController trafficController;
  late final RouteManager routeManager;

  bool isDirectionMode = false;
  List<TrafficSegment> segments = [];

  @override
  void initState() {
    super.initState();
    _initTraffic();
  }

  void _initTraffic() async {
    await MarkerIconHelper.instance.loadAll();

    trafficController = TrafficController();
    trafficController.start(
      onUpdate: (polylines, markers) {
        mapController.setTrafficPolylines(polylines);
        mapController.setTrafficMarkers(markers);
      },
    );
  }

  void _toggleDirectionMode() {
    setState(() => isDirectionMode = !isDirectionMode);
    if (!isDirectionMode) {
      mapController.clearDirectionPolylines();
      mapController.clearDirectionMarkers();
      _initTraffic(); 
    }
  }

  void _findRoute() async {
    final routeMgr = RouteManager(
      segments: segments,
      closedPolylines: mapController.polylines,
    );
    final result = await routeMgr.findRouteFromAddress(
      fromController.text,
      toController.text,
    );
    if (result != null) {
      final polylines = routeMgr.buildRoutePolylines(result);
      final markers = routeMgr.buildRouteMarkers(result.polyline);
      mapController.setDirectionPolylines(polylines);
      mapController.setDirectionMarkers(markers);
      mapController.moveTo(result.polyline.first);
    }
  }

  void _onSingleSearchSelected(String place) {
    mapController.moveToAddress(place);
  }

  @override
  void dispose() {
    mapController.disposeController();
    trafficController.stop();
    fromController.dispose();
    toController.dispose();
    singleSearchController.dispose();
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
            onPressed: () {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => LoginPage()),
              );
            },
          ),
        ],
      ),
      body: Stack(
        children: [
          AnimatedBuilder(
            animation: mapController,
            builder: (context, _) => MapView(
              initialPosition: const LatLng(-7.2575, 112.7521), // Surabaya
              zoom: 12.0,
              onMapCreated: (controller) {
                if (!mapController.hasController) {
                  mapController.setController(controller);
                  mapController.moveToUserLocation(); // Pindah ke lokasi user
                }
              },
              markers: mapController.markers,
              polylines: mapController.polylines,
            ),
          ),
          if (isDirectionMode)
            Positioned(
              top: 40,
              left: 0,
              right: 0,
              child: FromToSearchBar(
                fromController: fromController,
                toController: toController,
                onFindRoute: _findRoute,
              ),
            )
          else
            Positioned(
              top: 40,
              left: 0,
              right: 0,
              child: SingleSearchBar(
                controller: singleSearchController,
                onSuggestionSelected: _onSingleSearchSelected,
              ),
            ),
          MapControls(
            onZoomIn: mapController.zoomIn,
            onZoomOut: mapController.zoomOut,
            onToggleDirectionMode: _toggleDirectionMode,
            onOpenProfile: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => ProfilePage()),
              );
            },
            isDirectionMode: isDirectionMode,
          ),
        ],
      ),
    );
  }
}
