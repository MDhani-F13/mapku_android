import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../../widgets/from_to_search_bar.dart';
import '../../widgets/single_search_bar.dart';
import 'map_view.dart';
import '../../widgets/zoom_buttons.dart';
import '../../widgets/direction_controls.dart';
import '../../widgets/profile_button.dart';

import '../profile_page.dart';

import '../../controllers/map_controller.dart';
import '../../controllers/route_manager.dart';
import '../../controllers/traffic_controller.dart';

import '../../models/traffic_segment.dart';
import '../../models/search_history_entry.dart';
import '../../utils/marker_icon_helper.dart';

import '../../services/search_history_service.dart';
import '../../services/place_service.dart';

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

  final _placeService = PlaceService();
  late final TrafficController trafficController;

  bool isDirectionMode = false;
  List<TrafficSegment> segments = [];

  final _historyService = SearchHistoryService();

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

      await _historyService.addEntry(
        SearchHistoryEntry(
          type: 'from_to',
          query: '${fromController.text} → ${toController.text}',
          timestamp: DateTime.now(),
        ),
      );
    }
  }

  void _onSingleSearchSelected(String place) async {
    LatLng? result = await _placeService.searchPlaceFromText(place);
    result ??= await _placeService.searchPlaceFallback(place);

    if (result != null) {
      mapController.moveTo(result);

      await _historyService.addEntry(
        SearchHistoryEntry(
          type: 'single',
          query: place,
          timestamp: DateTime.now(),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Lokasi tidak ditemukan")),
      );
    }
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
    final topInset = MediaQuery.of(context).padding.top;

    return Scaffold(
      extendBodyBehindAppBar: true,
      body: LayoutBuilder(
        builder: (context, constraints) {
          return Stack(
            children: [
              /// 🌍 Map View
              AnimatedBuilder(
                animation: mapController,
                builder: (context, _) => MapView(
                  initialPosition: const LatLng(-7.2575, 112.7521),
                  zoom: 12.0,
                  onMapCreated: (controller) {
                    if (!mapController.hasController) {
                      mapController.setController(controller);
                      mapController.moveToUserLocation();
                    }
                  },
                  markers: mapController.markers,
                  polylines: mapController.polylines,
                ),
              ),

              /// 🔍 Search + Direction Toggle
              Positioned(
                top: topInset + 60,
                left: 12,
                right: 12,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      flex: 3,
                      child: AnimatedSwitcher(
                        duration: const Duration(milliseconds: 300),
                        switchInCurve: Curves.easeOut,
                        switchOutCurve: Curves.easeIn,
                        transitionBuilder: (child, animation) {
                          return FadeTransition(
                            opacity: animation,
                            child: SizeTransition(
                              sizeFactor: animation,
                              axisAlignment: -1.0,
                              child: child,
                            ),
                          );
                        },
                        child: isDirectionMode
                            ? FromToSearchBar(
                                key: const ValueKey('fromTo'),
                                fromController: fromController,
                                toController: toController,
                                onFindRoute: _findRoute,
                              )
                            : SingleSearchBar(
                                key: const ValueKey('single'),
                                controller: singleSearchController,
                                onSuggestionSelected: _onSingleSearchSelected,
                              ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    DirectionControls(
                      isDirectionMode: isDirectionMode,
                      onToggle: _toggleDirectionMode,
                    ),
                  ],
                ),
              ),

              /// 👤 Profile Button (Bottom Left)
              Positioned(
                bottom: 100,
                left: 16,
                child: ProfileButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const ProfilePage()),
                    );
                  },
                ),
              ),

              /// 🔍 Zoom Buttons (Bottom Right)
              Positioned(
                bottom: 100,
                right: 16,
                child: ZoomButtons(
                  onZoomIn: mapController.zoomIn,
                  onZoomOut: mapController.zoomOut,
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
