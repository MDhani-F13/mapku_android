import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../config/api_config.dart';
import '../utils/debug_logger.dart'; 

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
        polylines.add(_decodePolyline(encoded));
      }

      return polylines;
    } catch (e, stack) {
      await DebugLogger().log('🔥 [DirectionsService] Exception: $e\n$stack');
      rethrow;
    }
  }

  static List<LatLng> _decodePolyline(String encoded) {
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

      points.add(LatLng(lat / 1e5, lng / 1e5));
    }

    return points;
  }

  static List<LatLng> mergePolylines({
    required List<LatLng> originalRoute,
    required int entryIndex,
    required int exitIndex,
    required List<LatLng> detour,
  }) {
    final List<LatLng> merged = [];
    merged.addAll(originalRoute.sublist(0, entryIndex + 1));
    merged.addAll(detour);
    merged.addAll(originalRoute.sublist(exitIndex));
    return merged;
  }
}
