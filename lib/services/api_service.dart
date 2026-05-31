import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class ApiService {
  // ambia esta URL según donde estés trabajando:
  // Emulador Android:    'http://10.0.2.2:8000'
  // Dispositivo físico:  'http://192.168.X.X:8000'  (IP de tu PC)
  // Producción Render:   'https://quriy-api.onrender.com'
  static const String baseUrl = 'http://10.0.2.2:8000';

  // ── Token ──────────────────────────────────────────────────────
  static Future<void> guardarToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('jwt_token', token);
  }

  static Future<String?> obtenerToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('jwt_token');
  }

  static Future<void> eliminarToken() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('jwt_token');
  }

  static Future<Map<String, String>> _headersConToken() async {
    final token = await obtenerToken();
    return {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  // ── Auth ───────────────────────────────────────────────────────
  static Future<Map<String, dynamic>> iniciarSesion(
      String email, String password) async {
    try {
      final respuesta = await http.post(
        Uri.parse('$baseUrl/auth/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email, 'password': password}),
      );
      if (respuesta.statusCode == 200) {
        return {'exito': true, 'datos': jsonDecode(respuesta.body)};
      } else if (respuesta.statusCode == 401) {
        return {'exito': false, 'mensaje': 'Credenciales incorrectas'};
      } else {
        return {'exito': false, 'mensaje': 'Error del servidor'};
      }
    } catch (e) {
      return {'exito': false, 'mensaje': 'No se pudo conectar al servidor'};
    }
  }

  // ── Zonas y Contenido ──────────────────────────────────────────
  static Future<List<dynamic>> obtenerZonasDeSitio(int sitioId) async {
    try {
      final headers = await _headersConToken();
      final respuesta = await http.get(
        Uri.parse('$baseUrl/sitios/$sitioId/zonas'),
        headers: headers,
      );
      if (respuesta.statusCode == 200) return jsonDecode(respuesta.body);
      return [];
    } catch (e) {
      return [];
    }
  }

  static Future<List<dynamic>> obtenerContenidoDeZona(int zonaId) async {
    try {
      final headers = await _headersConToken();
      final respuesta = await http.get(
        Uri.parse('$baseUrl/zonas/$zonaId/contenido'),
        headers: headers,
      );
      if (respuesta.statusCode == 200) return jsonDecode(respuesta.body);
      return [];
    } catch (e) {
      return [];
    }
  }
}