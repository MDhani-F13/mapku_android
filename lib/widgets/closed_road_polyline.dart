import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:flutter_polyline_points/flutter_polyline_points.dart';
import '../models/traffic_segment.dart';

class ClosedRoadPolyline {
  static List<Polyline> draw(TrafficSegment segment) {
    List<LatLng> points = [];

    if (segment.routePolyline?.isNotEmpty == true) {
      final polylinePoints = PolylinePoints();
      final result =
          polylinePoints.decodePolyline(segment.routePolyline!);
      points = result
          .map((e) => LatLng(e.latitude, e.longitude))
          .toList();
    } else if (segment.fromLat != null &&
        segment.fromLng != null &&
        segment.toLat != null &&
        segment.toLng != null) {
      points = [
        LatLng(segment.fromLat!, segment.fromLng!),
        LatLng(segment.toLat!, segment.toLng!),
      ];
    }

    if (points.isEmpty) return [];

    return [
      // 🖤 Shadow / outline
      Polyline(
        polylineId: PolylineId('closed_road_shadow_${segment.id}'),
        points: points,
        color: Colors.black.withOpacity(0.35),
        width: 8,
        startCap: Cap.roundCap,
        endCap: Cap.roundCap,
        jointType: JointType.round,
        zIndex: 1,
      ),

      // 🔴 Main closed road line
      Polyline(
        polylineId: PolylineId('closed_road_${segment.id}'),
        points: points,
        color: const Color(0xFFD32F2F),
        width: 4,
        startCap: Cap.roundCap,
        endCap: Cap.roundCap,
        jointType: JointType.round,
        zIndex: 2,
      ),
    ];
  }
}

