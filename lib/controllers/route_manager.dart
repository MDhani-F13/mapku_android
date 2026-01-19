import 'dart:ui';

import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../models/traffic_segment.dart';
import '../models/route_result.dart';
import '../services/directions_service.dart';
import '../services/overlap_checker.dart';
import '../services/map_object_builder.dart';
import '../services/place_service.dart';
import '../utils/debug_logger.dart';
import '../utils/marker_icon_helper.dart';


class RouteManager {
  final List<TrafficSegment> _segments;
  final Set<Polyline> closedPolylines;

  RouteManager({
    required List<TrafficSegment> segments,
    required this.closedPolylines,
  }) : _segments = segments;

  Future<RouteResult?> findRouteFromAddress(String from, String to) async {
    final placeService = PlaceService();

    final fromLatLng = await placeService.searchPlaceFromText(from);
    if (fromLatLng == null) {
      await DebugLogger().log('❌ Geocoding FROM failed');
      return null;
    }

    final toLatLng = await placeService.searchPlaceFromText(to);
    if (toLatLng == null) {
      await DebugLogger().log('❌ Geocoding TO failed');
      return null;
    }

    return await findRoute(fromLatLng, toLatLng);
  }

  Future<RouteResult?> findRoute(LatLng from, LatLng to) async {
    try {
      final result = await DirectionsService.findRoute(
        from: from,
        to: to,
        closedPolylines: closedPolylines,
      );

      if (result.usedFallback) {
        for (var segment in _segments) {
          final overlap = OverlapChecker.detectOverlap(
            routePolyline: result.polyline,
            closedRoadPolylines: {
              if (segment.routePolyline != null)
                Polyline(
                  polylineId: PolylineId('seg_${segment.id}'),
                  points: DirectionsService.decodePolyline(segment.routePolyline!),
                ),
            },
          );
          if (overlap.hasOverlap) {
            segment.usedFallback = true;
          }
        }
      }

      return result;
    } catch (e, stack) {
      await DebugLogger().log('🔥 [RouteManager] Failed to find route: $e');
      await DebugLogger().log('📄 Stacktrace: $stack');
      return null;
    }
  }

  Future<(Set<Polyline>, Set<Marker>)> rebuildMapObjects() async {
    return await MapObjectBuilder.buildMapObjects(_segments);
  }

  Set<Marker> buildRouteMarkers(List<LatLng> polyline) {
    final startIcon = MarkerIconHelper.instance.start ??
        BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen);
    final endIcon = MarkerIconHelper.instance.end ??
        BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure);

    return {
      Marker(
        markerId: const MarkerId('start'),
        position: polyline.first,
        icon: startIcon,
        infoWindow: const InfoWindow(title: 'Titik Awal'),
      ),
      Marker(
        markerId: const MarkerId('end'),
        position: polyline.last,
        icon: endIcon,
        infoWindow: const InfoWindow(title: 'Tujuan'),
      ),
    };
  }

  Set<Polyline> buildRoutePolylines(RouteResult result) {
    return {
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
          ))
    };
  }
}
