import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';

class PlaceService {
  final String baseUrl = "https://maps.googleapis.com/maps/api/place/autocomplete/json";

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
}
