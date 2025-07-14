import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:flutter_polyline_points/flutter_polyline_points.dart';
import '../models/traffic_segment.dart';

class ClosedRoadPolyline {
  static Polyline draw(TrafficSegment segment) {
    List<LatLng> points = [];

    if (segment.routePolyline != null && segment.routePolyline!.isNotEmpty) {
      PolylinePoints polylinePoints = PolylinePoints();
      List<PointLatLng> result = polylinePoints.decodePolyline(segment.routePolyline!);
      points = result.map((e) => LatLng(e.latitude, e.longitude)).toList();
    } else if (segment.fromLat != null && segment.fromLng != null &&
        segment.toLat != null && segment.toLng != null) {
      points = [
        LatLng(segment.fromLat!, segment.fromLng!),
        LatLng(segment.toLat!, segment.toLng!)
      ];
    }

    return Polyline(
      polylineId: PolylineId('closed_road_${segment.id}'),
      points: points,
      color: const Color(0xFFE53935),
      width: 5,
    );
  }
}
