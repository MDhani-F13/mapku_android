import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../config/api_config.dart';

class AuthService {
  final String baseUrl = ApiConfig.baseUrl;

  // Login User
  Future<bool> login(String username, String password) async {
    final response = await http.post(
      Uri.parse("$baseUrl/login/"),
      body: {"username": username, "password": password},
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('token', data['access']); // Simpan token
      return true;
    } else {
      return false;
    }
  }

  // Registrasi User
  Future<bool> register(String username, String email, String password) async {
    final response = await http.post(
      Uri.parse("$baseUrl/register/"),
      headers: {
        "Content-Type": "application/json",  // Pastikan request dikirim sebagai JSON
      },
      body: jsonEncode({
        "username": username,
        "email": email,
        "password": password,
        "level": "user",  // Tambahkan level default
      }),
    );

    if (response.statusCode == 201) {
      return true; // Registrasi berhasil
    } else {
      print("Gagal registrasi: ${response.body}"); // Debugging jika ada error
      return false;
    }
  }

  // Mendapatkan Data User yang Sedang Login
  Future<Map<String, dynamic>?> getUser() async {
    final prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString('token');

    if (token == null) return null;

    final response = await http.get(
      Uri.parse("$baseUrl/user/"),
      headers: {"Authorization": "Bearer $token"},
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      return null;
    }
  }

  Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('token');
  }

  Future<void> saveToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('token', token);
  }

  // Logout User
  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('token');
  }
}
