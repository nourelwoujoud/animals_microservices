import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart';
import '../models/animal.dart';

class ApiService {

  static const String baseUrl =
      kIsWeb ? 'http://127.0.0.1:8000' : 'http://10.0.2.2:8000';

  static const String _tokenKey = 'jwt_token';

  // ─── TOKEN ────────────────────────────────────────────────

  static Future<void> saveToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tokenKey, token);
  }

  static Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_tokenKey);
  }

  static Future<void> clearToken() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
  }

  static Future<Map<String, String>> _authHeaders() async {
    final token = await getToken();
    return {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  // ─── REGISTER ─────────────────────────────────────────────

  static Future<Map<String, dynamic>> register({
    required String name,
    required String email,
    required String password,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/register'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'name': name, 'email': email, 'password': password}),
    );
    final data = jsonDecode(response.body);
    if (response.statusCode == 200) {
      return {'success': true, 'message': data['message']};
    }
    return {'success': false, 'message': data['detail'] ?? 'Erreur register'};
  }

  // ─── LOGIN ────────────────────────────────────────────────

  static Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/login'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'email': email, 'password': password}),
    );
    final data = jsonDecode(response.body);
    if (response.statusCode == 200) {
      final token = data['access_token'];
      if (token != null) {
        await saveToken(token);
        return {'success': true, 'token': token, 'email': data['email']};
      }
      return {'success': false, 'message': 'Token manquant'};
    }
    return {'success': false, 'message': data['detail'] ?? 'Login failed'};
  }

  // ─── ANIMALS ──────────────────────────────────────────────

  static Future<List<Animal>> getAnimals() async {
    final headers = await _authHeaders();
    final response = await http.get(Uri.parse('$baseUrl/animals'), headers: headers);
    if (response.statusCode == 200) {
      final List jsonList = jsonDecode(response.body);
      return jsonList.map((e) => Animal.fromJson(e)).toList();
    }
    // ✅ FIX : 401 → signal spécial pour forcer le logout
    if (response.statusCode == 401) throw Exception('TOKEN_EXPIRED');
    throw Exception('Erreur chargement animaux');
  }

  // ─── ADOPT ────────────────────────────────────────────────

  static Future<Map<String, dynamic>> adoptAnimal(int animalId) async {
    final headers = await _authHeaders();
    final response = await http.post(
      Uri.parse('$baseUrl/adopt'),
      headers: headers,
      body: jsonEncode({'animal_id': animalId}),
    );
    final data = jsonDecode(response.body);
    if (response.statusCode == 200 || response.statusCode == 201) {
      return {'success': true, 'message': data['message'] ?? 'Adoption réussie'};
    }
    if (response.statusCode == 401) return {'success': false, 'message': 'TOKEN_EXPIRED'};
    return {'success': false, 'message': data['detail'] ?? 'Erreur adoption'};
  }

  // ─── ANNULER ADOPTION ─────────────────────────────────────

  static Future<Map<String, dynamic>> cancelAdoption(int animalId) async {
    final headers = await _authHeaders();
    final response = await http.delete(
      Uri.parse('$baseUrl/adopt/$animalId'),
      headers: headers,
      // ✅ Flutter http.delete supporte body= directement
    );
    final data = jsonDecode(response.body);
    if (response.statusCode == 200) {
      return {'success': true, 'message': data['message'] ?? 'Adoption annulée'};
    }
    if (response.statusCode == 401) return {'success': false, 'message': 'TOKEN_EXPIRED'};
    return {'success': false, 'message': data['detail'] ?? "Erreur annulation"};
  }

  // ─── MES ADOPTIONS ────────────────────────────────────────

  static Future<List<Map<String, dynamic>>> getMyAdoptions() async {
    final headers = await _authHeaders();
    final response = await http.get(Uri.parse('$baseUrl/my_adoptions'), headers: headers);
    if (response.statusCode == 200) {
      final List jsonList = jsonDecode(response.body);
      return jsonList.cast<Map<String, dynamic>>();
    }
    if (response.statusCode == 401) throw Exception('TOKEN_EXPIRED');
    throw Exception('Erreur chargement adoptions (${response.statusCode})');
  }
}