import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../config/api_config.dart';

class DirectionsService {
  static Future<List<List<LatLng>>> getRoutes({
    required LatLng from,
    required LatLng to,
  }) async {
    final baseUrl = 'https://maps.googleapis.com/maps/api/directions/json';
    final url = '$baseUrl?origin=${from.latitude},${from.longitude}'
        '&destination=${to.latitude},${to.longitude}'
        '&alternatives=true'
        '&key=${ApiConfig.googleMapsApiKey}';

    final response = await http.get(Uri.parse(url));
    if (response.statusCode != 200) {
      throw Exception('Failed to fetch directions');
    }

    final data = jsonDecode(response.body);
    final routes = data['routes'] as List;

    List<List<LatLng>> polylines = [];

    for (var route in routes) {
      final encoded = route['overview_polyline']['points'];
      polylines.add(_decodePolyline(encoded));
    }

    return polylines;
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

      points.add(
        LatLng(lat / 1e5, lng / 1e5),
      );
    }
    return points;
  }
}
