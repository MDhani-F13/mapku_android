import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../config/api_config.dart';
import '../utils/debug_logger.dart';

import '../services/overlap_checker.dart';
import '../services/detour_service.dart';

import '../models/route_result.dart';

class DirectionsService {
  static Future<List<List<LatLng>>> getRoutes({
    required LatLng from,
    required LatLng to,
  }) async {
    const baseUrl = 'https://maps.googleapis.com/maps/api/directions/json';
    final url = '$baseUrl?origin=${from.latitude},${from.longitude}'
        '&destination=${to.latitude},${to.longitude}'
        '&alternatives=true'
        '&key=${ApiConfig.googleMapsApiKey}';

    await DebugLogger().log('🌐 [DirectionsService] Requesting: $url');

    try {
      final response = await http
          .get(Uri.parse(url))
          .timeout(const Duration(seconds: 10));

      await DebugLogger().log('📦 [DirectionsService] HTTP ${response.statusCode}');

      if (response.statusCode != 200) {
        await DebugLogger().log('❌ [DirectionsService] Bad status code: ${response.statusCode}');
        throw Exception('Failed to fetch directions');
      }

      final data = jsonDecode(response.body);
      final status = data['status'];

      await DebugLogger().log('🔍 [DirectionsService] Response status: $status');

      if (status != 'OK') {
        await DebugLogger().log('⚠️ [DirectionsService] Directions API error: $status');
        throw Exception('Directions API error: $status');
      }

      final routes = data['routes'] as List;
      await DebugLogger().log('✅ [DirectionsService] Routes found: ${routes.length}');

      List<List<LatLng>> polylines = [];

      for (var route in routes) {
        final encoded = route['overview_polyline']['points'];
        polylines.add(decodePolyline(encoded));
      }

      return polylines;
    } catch (e, stack) {
      await DebugLogger().log('🔥 [DirectionsService] Exception: $e\n$stack');
      rethrow;
    }
  }

  static Future<RouteResult> findRoute({
    required LatLng from,
    required LatLng to,
    required Set<Polyline> closedPolylines,
  }) async {
    await DebugLogger().log("📍 [findRoute] Mulai mencari rute dari $from ke $to");

    final routes = await getRoutes(from: from, to: to);
    if (routes.isEmpty) {
      await DebugLogger().log("🚫 [findRoute] Tidak ada rute ditemukan");
      return RouteResult(
        polyline: [],
        bounds: LatLngBounds(northeast: from, southwest: to),
        alternatives: [],
      );
    }

    List<LatLng>? bestRoute;
    int minOverlapCount = 999999;

    for (final route in routes) {
      final overlap = OverlapChecker.detectOverlap(
        routePolyline: route,
        closedRoadPolylines: closedPolylines,
      );

      final count = overlap.overlapLength;

      if (count == 0) {
        await DebugLogger().log("✅ [findRoute] Rute tanpa overlap ditemukan");
        return RouteResult(
          polyline: route,
          bounds: _getBounds(route),
          usedFallback: false,
          alternatives: routes.where((r) => r != route).toList(),
        );
      }

      if (count < minOverlapCount) {
        bestRoute = route;
        minOverlapCount = count;
      }
    }

    if (bestRoute == null) {
      await DebugLogger().log("❌ [findRoute] Tidak ada rute terbaik, gunakan rute pertama sebagai fallback");
      return RouteResult(
        polyline: routes[0],
        bounds: _getBounds(routes[0]),
        usedFallback: true,
        alternatives: routes.sublist(1),
      );
    }

    final selected = bestRoute;

    final overlap = OverlapChecker.detectOverlap(
      routePolyline: selected,
      closedRoadPolylines: closedPolylines,
    );

    final entryIndex = (overlap.entryIndex! - 3).clamp(0, selected.length - 1);
    final exitIndex = (overlap.exitIndex! + 3).clamp(0, selected.length - 1);
    final subStart = selected[entryIndex];
    final subEnd = selected[exitIndex];

    await DebugLogger().log("🔁 [findRoute] Mencoba detour dari $subStart ke $subEnd");

    final detourResult = await DetourService.getDetour(
      entryPoint: subStart,
      exitPoint: subEnd,
      closedRoadPolylines: closedPolylines,
    );

    if (detourResult == null) {
      await DebugLogger().log("⚠️ [findRoute] Detour gagal, gunakan rute asli dengan fallback");
      return RouteResult(
        polyline: selected,
        bounds: _getBounds(selected),
        usedFallback: true,
        alternatives: routes.where((r) => r != selected).toList(),
      );
    }

    final finalRoute = mergePolylines(
      originalRoute: selected,
      entryIndex: entryIndex,
      exitIndex: exitIndex,
      detour: detourResult.detourPolyline,
    );

    await DebugLogger().log("✅ [findRoute] Detour berhasil digunakan");

    return RouteResult(
      polyline: finalRoute,
      bounds: _getBounds(finalRoute),
      usedFallback: true,
      alternatives: routes.where((r) => r != selected).toList(),
    );
  }

  static List<LatLng> mergePolylines({
    required List<LatLng> originalRoute,
    required int entryIndex,
    required int exitIndex,
    required List<LatLng> detour,
  }) {
    DebugLogger().log("🧩 [mergePolylines] Menggabungkan rute asli dengan detour");

    final before = originalRoute.sublist(0, entryIndex);
    final after = originalRoute.sublist(exitIndex);
    final merged = [...before, ...detour, ...after];

    DebugLogger().log("✅ [mergePolylines] Merge selesai. Total titik: ${merged.length}");
    return merged;
  }

  static List<LatLng> decodePolyline(String encoded) {
    List<LatLng> points = [];
    int index = 0, len = encoded.length;
    int lat = 0, lng = 0;

    while (index < len) {
      int b, shift = 0, result = 0;
      do {
        b = encoded.codeUnitAt(index++) - 63;
        result |= (b & 0x1f) << shift;
        shift += 5;
      } while (b >= 0x20);
      int dlat = ((result & 1) != 0 ? ~(result >> 1) : (result >> 1));
      lat += dlat;

      shift = 0;
      result = 0;
      do {
        b = encoded.codeUnitAt(index++) - 63;
        result |= (b & 0x1f) << shift;
        shift += 5;
      } while (b >= 0x20);
      int dlng = ((result & 1) != 0 ? ~(result >> 1) : (result >> 1));
      lng += dlng;

      points.add(LatLng(lat / 1E5, lng / 1E5));
    }

    return points;
  }

  static LatLngBounds _getBounds(List<LatLng> polyline) {
    double minLat = polyline.first.latitude;
    double maxLat = polyline.first.latitude;
    double minLng = polyline.first.longitude;
    double maxLng = polyline.first.longitude;

    for (final point in polyline) {
      if (point.latitude < minLat) minLat = point.latitude;
      if (point.latitude > maxLat) maxLat = point.latitude;
      if (point.longitude < minLng) minLng = point.longitude;
      if (point.longitude > maxLng) maxLng = point.longitude;
    }

    return LatLngBounds(
      southwest: LatLng(minLat, minLng),
      northeast: LatLng(maxLat, maxLng),
    );
  }
}
