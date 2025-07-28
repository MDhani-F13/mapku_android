import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'directions_service.dart';
import 'overlap_checker.dart';

class DetourResult {
  final List<LatLng> detourPolyline;

  DetourResult({required this.detourPolyline});
}

class DetourService {
  static Future<DetourResult?> getDetour({
    required LatLng entryPoint,
    required LatLng exitPoint,
    required Set<Polyline> closedRoadPolylines,
  }) async {
    final detourRoutes = await DirectionsService.getRoutes(
      from: entryPoint,
      to: exitPoint,
    );

    for (final route in detourRoutes) {
      final overlapCheck = OverlapChecker.detectOverlap(
        routePolyline: route,
        closedRoadPolylines: closedRoadPolylines,
      );

      if (!overlapCheck.hasOverlap) {
        return DetourResult(detourPolyline: route);
      }
    }

    return null; // Semua alternatif overlap → fallback di _findRoute
  }
}
