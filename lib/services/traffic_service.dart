import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';
import '../models/traffic_segment.dart';

class TrafficService {
  Future<List<TrafficSegment>> fetchSegments() async {
    final url = "${ApiConfig.baseUrl}/traffic/traffic-reports/";
    final response = await http.get(Uri.parse(url));
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body) as List;
      return data.expand((report) {
        return (report['segments'] as List)
            .map((seg) => TrafficSegment.fromJson(seg));
      }).toList();
    } else {
      throw Exception("Failed to fetch segments");
    }
  }

  static Future<String?> fetchPolyline(int id) async {
    final url = "${ApiConfig.baseUrl}/traffic/segment/$id/get_polyline/";
    final response = await http.get(Uri.parse(url));
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['route_polyline'];
    }
    return null;
  }
}
