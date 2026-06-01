import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class ApiService {
  static const String baseUrl = 'http://10.0.2.2:8000';

  // ── Credenciales locales para pruebas ─────────────────────────
  // Cuando conectes el backend real, estas líneas ya no se usan
  static const String _emailPrueba = 'axel@quiry';
  static const String _passwordPrueba = 'axel1';

  // ── Datos de prueba locales ────────────────────────────────────
  static List<Map<String, dynamic>> get _zonasPrueba => [
    {
      'id': 1,
      'nombre': 'Plaza Sagrada',
      'descripcion':
      'Centro ceremonial principal del sitio arqueológico. Aquí se realizaban los rituales más importantes del Imperio Inca.',
      'latitud': -13.5170,
      'longitud': -71.9785,
      'activa': true,
    },
    {
      'id': 2,
      'nombre': 'Templo del Sol',
      'descripcion':
      'Dedicado al dios Inti, el Sol. Sus paredes estaban cubiertas de oro y plata.',
      'latitud': -13.5175,
      'longitud': -71.9790,
      'activa': true,
    },
    {
      'id': 3,
      'nombre': 'Sector de Ofrendas',
      'descripcion':
      'Zona donde se depositaban ofrendas y objetos rituales de gran valor simbólico.',
      'latitud': -13.5165,
      'longitud': -71.9780,
      'activa': true,
    },
  ];

  static List<Map<String, dynamic>> _contenidoPrueba(int zonaId) => [
    {
      'id': 1,
      'tipo': 'texto',
      'idioma': 'es',
      'titulo': 'Historia de la zona',
      'descripcion':
      'Esta zona fue construida aproximadamente en el siglo XV durante el apogeo del Imperio Inca. Los arqueólogos han encontrado evidencia de actividad ritual continua durante más de 200 años.',
      'url_recurso': '',
    },
    {
      'id': 2,
      'tipo': 'imagen',
      'idioma': 'es',
      'titulo': 'Vista panorámica',
      'descripcion': 'Vista aérea del sector excavado en 2019.',
      'url_recurso':
      'https://upload.wikimedia.org/wikipedia/commons/thumb/4/4b/Machu_Picchu_%2812%29.jpg/1280px-Machu_Picchu_%2812%29.jpg',
    },
    {
      'id': 3,
      'tipo': 'audio',
      'idioma': 'es',
      'titulo': 'Audioguía en español',
      'descripcion': 'Narración completa del recorrido por esta zona.',
      'url_recurso': 'https://www.soundhelix.com/examples/mp3/SoundHelix-Song-1.mp3',
    },
    {
      'id': 4,
      'tipo': 'texto',
      'idioma': 'en',
      'titulo': 'Zone History',
      'descripcion':
      'This zone was built approximately in the 15th century during the height of the Inca Empire. Archaeologists have found evidence of continuous ritual activity for over 200 years.',
      'url_recurso': '',
    },
    {
      'id': 5,
      'tipo': 'imagen',
      'idioma': 'en',
      'titulo': 'Panoramic view',
      'descripcion': 'Aerial view of the sector excavated in 2019.',
      'url_recurso':
      'https://upload.wikimedia.org/wikipedia/commons/thumb/4/4b/Machu_Picchu_%2812%29.jpg/1280px-Machu_Picchu_%2812%29.jpg',
    },
    {
      'id': 6,
      'tipo': 'audio',
      'idioma': 'en',
      'titulo': 'Audio guide in English',
      'descripcion': 'Full narration of the tour through this zone.',
      'url_recurso': 'https://www.soundhelix.com/examples/mp3/SoundHelix-Song-2.mp3',
    },
  ];

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
    // Primero intenta con el backend real
    try {
      final respuesta = await http
          .post(
        Uri.parse('$baseUrl/auth/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email, 'password': password}),
      )
          .timeout(const Duration(seconds: 4));

      if (respuesta.statusCode == 200) {
        return {'exito': true, 'datos': jsonDecode(respuesta.body)};
      } else if (respuesta.statusCode == 401) {
        return {'exito': false, 'mensaje': 'Credenciales incorrectas'};
      }
    } catch (_) {
      // Backend no disponible → usar credenciales locales
    }

    // Modo local: validar con credenciales de prueba
    await Future.delayed(const Duration(milliseconds: 800)); // simula red
    if (email == _emailPrueba && password == _passwordPrueba) {
      return {
        'exito': true,
        'datos': {'access_token': 'token_local_prueba', 'token_type': 'bearer'},
      };
    }
    return {'exito': false, 'mensaje': 'Credenciales incorrectas'};
  }

  // ── Zonas ──────────────────────────────────────────────────────
  static Future<List<dynamic>> obtenerZonasDeSitio(int sitioId) async {
    try {
      final headers = await _headersConToken();
      final respuesta = await http
          .get(Uri.parse('$baseUrl/sitios/$sitioId/zonas'), headers: headers)
          .timeout(const Duration(seconds: 4));
      if (respuesta.statusCode == 200) return jsonDecode(respuesta.body);
    } catch (_) {
      // Backend no disponible → datos locales
    }
    await Future.delayed(const Duration(milliseconds: 500));
    return _zonasPrueba;
  }

  // ── Contenido ──────────────────────────────────────────────────
  static Future<List<dynamic>> obtenerContenidoDeZona(int zonaId) async {
    try {
      final headers = await _headersConToken();
      final respuesta = await http
          .get(Uri.parse('$baseUrl/zonas/$zonaId/contenido'), headers: headers)
          .timeout(const Duration(seconds: 4));
      if (respuesta.statusCode == 200) return jsonDecode(respuesta.body);
    } catch (_) {
      // Backend no disponible → datos locales
    }
    await Future.delayed(const Duration(milliseconds: 500));
    return _contenidoPrueba(zonaId);
  }
}