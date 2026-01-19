import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:geocoding/geocoding.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../config/api_config.dart';

class PlaceService {
  final String baseUrl = "https://maps.googleapis.com/maps/api/place/autocomplete/json";
  final String textSearchUrl = "https://maps.googleapis.com/maps/api/place/textsearch/json";

  Future<List<String>> fetchSuggestions(String input) async {
    final response = await http.get(Uri.parse(
      "$baseUrl?input=$input&key=${ApiConfig.googleMapsApiKey}&language=id&components=country:id",
    ));

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return (data['predictions'] as List)
          .map((item) => item['description'] as String)
          .toList();
    } else {
      return [];
    }
  }
Future<LatLng?> searchPlaceFromText(String query) async {
    final url =
      "$textSearchUrl?query=${Uri.encodeComponent(query)}&language=id&region=id&key=${ApiConfig.googleMapsApiKey}";

    final response = await http.get(Uri.parse(url));
    if (response.statusCode != 200) return null;

    final data = jsonDecode(response.body);
    if (data["results"] == null || data["results"].isEmpty) return null;

    final loc = data["results"][0]["geometry"]["location"];
    return LatLng(loc["lat"], loc["lng"]);
  }

  Future<LatLng?> searchPlaceFallback(String query) async {
    try {
      final locations = await locationFromAddress(query);
      if (locations.isNotEmpty) {
        final loc = locations.first;
        return LatLng(loc.latitude, loc.longitude);
      }
    } catch (_) {}
    return null;
  }
}
