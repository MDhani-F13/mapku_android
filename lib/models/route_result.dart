import 'package:google_maps_flutter/google_maps_flutter.dart';

class RouteResult {
  final List<LatLng> polyline;
  final LatLngBounds bounds;
  final bool usedFallback;
  final LatLng? warningPosition;
  final List<List<LatLng>> alternatives;
  final List<LatLng>? overlappingSegment;

  RouteResult({
    required this.polyline,
    required this.bounds,
    this.usedFallback = false,
    this.warningPosition,
    this.alternatives = const [],
    this.overlappingSegment,
  });
}
