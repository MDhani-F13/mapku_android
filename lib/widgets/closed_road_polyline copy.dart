import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:flutter_polyline_points/flutter_polyline_points.dart';
import '../models/traffic_segment.dart';

class ClosedRoadPolyline {
  static Polyline draw(TrafficSegment segment) {
    final points = [
      LatLng(segment.fromLat!, segment.fromLng!),
      LatLng(segment.toLat!, segment.toLng!),
    ];

    return Polyline(
      polylineId: PolylineId('closed_road_${segment.id}'),
      points: points,
      color: const Color(0xFFE53935), // Merah
      width: 5,
    );
  }
}

