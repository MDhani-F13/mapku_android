import 'package:flutter_dotenv/flutter_dotenv.dart';

class ApiConfig {
  static String get googleMapsApiKey => dotenv.env['GOOGLE_MAPS_API_KEY'] ?? '';
  static String get baseUrl => dotenv.env['BASE_URL'] ?? 'http://10.0.2.2:8000/api';
}