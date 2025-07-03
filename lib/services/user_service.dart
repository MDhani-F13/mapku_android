import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';

class UserService {
  String get baseUrl => dotenv.env['BASE_URL'] ?? "";

  Future<Map<String, dynamic>?> getProfile(String token) async {
    final response = await http.get(
      Uri.parse('$baseUrl/profile/'),
      headers: {'Authorization': 'Bearer $token'},
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      return null;
    }
  }
}
