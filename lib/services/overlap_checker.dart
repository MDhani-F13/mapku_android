import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'dart:math';

class OverlapResult {
  final bool hasOverlap;
  final int? entryIndex;
  final int? exitIndex;
  final LatLng? entryPoint;
  final LatLng? exitPoint;

  OverlapResult({
    required this.hasOverlap,
    this.entryIndex,
    this.exitIndex,
    this.entryPoint,
    this.exitPoint,
  });

  // 🔍 Tambahan → panjang overlap
  int get overlapLength {
    if (hasOverlap && entryIndex != null && exitIndex != null) {
      return (exitIndex! - entryIndex!).abs() + 1;
    }
    return 0;
  }
}

class OverlapChecker {
  static const double thresholdMeters = 15;

  static double _calculateDistance(LatLng p1, LatLng p2) {
    const earthRadius = 6371000; // meters
    final dLat = _deg2rad(p2.latitude - p1.latitude);
    final dLon = _deg2rad(p2.longitude - p1.longitude);
    final a = sin(dLat / 2) * sin(dLat / 2) +
        cos(_deg2rad(p1.latitude)) *
            cos(_deg2rad(p2.latitude)) *
            sin(dLon / 2) *
            sin(dLon / 2);
    final c = 2 * atan2(sqrt(a), sqrt(1 - a));
    return earthRadius * c;
  }

  static double _deg2rad(double deg) => deg * (pi / 180);

  static double _distancePointToSegment(LatLng p, LatLng segA, LatLng segB) {
    final x0 = p.latitude;
    final y0 = p.longitude;
    final x1 = segA.latitude;
    final y1 = segA.longitude;
    final x2 = segB.latitude;
    final y2 = segB.longitude;

    final dx = x2 - x1;
    final dy = y2 - y1;

    if (dx == 0 && dy == 0) {
      return _calculateDistance(p, segA);
    }

    final t = ((x0 - x1) * dx + (y0 - y1) * dy) / (dx * dx + dy * dy);

    if (t < 0) {
      return _calculateDistance(p, segA);
    } else if (t > 1) {
      return _calculateDistance(p, segB);
    } else {
      final proj = LatLng(x1 + t * dx, y1 + t * dy);
      return _calculateDistance(p, proj);
    }
  }

  static OverlapResult detectOverlap({
    required List<LatLng> routePolyline,
    required Set<Polyline> closedRoadPolylines,
  }) {
    bool inOverlap = false;
    int? entryIdx;
    int? exitIdx;

    for (int i = 0; i < routePolyline.length; i++) {
      final routePoint = routePolyline[i];

      for (final closed in closedRoadPolylines) {
        final closedPoints = closed.points;
        for (int j = 0; j < closedPoints.length - 1; j++) {
          final segA = closedPoints[j];
          final segB = closedPoints[j + 1];

          final dist = _distancePointToSegment(routePoint, segA, segB);

          if (dist < thresholdMeters) {
            if (!inOverlap) {
              entryIdx = i;
              inOverlap = true;
            }
            exitIdx = i;
          }
        }
      }
    }

    if (entryIdx != null && exitIdx != null) {
      return OverlapResult(
        hasOverlap: true,
        entryIndex: entryIdx,
        exitIndex: exitIdx,
        entryPoint: routePolyline[entryIdx],
        exitPoint: routePolyline[exitIdx],
      );
    }

    return OverlapResult(hasOverlap: false);
  }
}
