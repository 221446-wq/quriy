import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../core/config/app_config.dart';
import '../core/jwt_utils.dart';

// ── Excepciones tipadas por dominio ───────────────────────────────────────────

/// Lanzada cuando las credenciales no coinciden (HTTP 401).
class ExcepcionCredencialesInvalidas implements Exception {
  final String mensaje;
  const ExcepcionCredencialesInvalidas([
    this.mensaje = 'Credenciales incorrectas',
  ]);

  @override
  String toString() => 'ExcepcionCredencialesInvalidas: $mensaje';
}

/// Lanzada cuando el código QR no corresponde a ninguna zona registrada.
class ExcepcionCodigoQRInvalido implements Exception {
  final String codigoRecibido;
  const ExcepcionCodigoQRInvalido(this.codigoRecibido);

  @override
  String toString() =>
      'ExcepcionCodigoQRInvalido: "$codigoRecibido" '
      'no corresponde a ninguna zona registrada';
}

/// Lanzada cuando falla el registro de una visita (red caída o backend
/// respondió con error). A diferencia de las lecturas, esto SÍ se propaga
/// a la UI en vez de caer a datos locales: fingir éxito en una escritura
/// engañaría al turista haciéndole creer que su visita quedó registrada.
class ExcepcionRegistrarVisita implements Exception {
  final String mensaje;
  const ExcepcionRegistrarVisita([
    this.mensaje = 'No se pudo registrar la visita',
  ]);

  @override
  String toString() => 'ExcepcionRegistrarVisita: $mensaje';
}

/// Lanzada cuando el backend responde 401 en un endpoint autenticado: el
/// token guardado ya no es válido (expiró o fue revocado). A diferencia
/// de un backend caído, esto NO debe caer a datos locales — hay que
/// reautenticar, porque seguir mostrando datos (reales o mock) sin avisar
/// dejaría al usuario creyendo que sigue con sesión activa.
class ExcepcionSesionExpirada implements Exception {
  const ExcepcionSesionExpirada();

  @override
  String toString() => 'ExcepcionSesionExpirada: el token ya no es válido';
}

/// Envuelve el resultado de una lectura para que la UI sepa si son datos
/// reales del backend o el fallback local de demo (cuando no hay
/// conexión). No es un error — es información para poder avisarle al
/// usuario que lo que ve no viene del servidor.
class RespuestaApi<T> {
  final T datos;
  final bool esDatosLocales;
  const RespuestaApi(this.datos, {required this.esDatosLocales});
}

// ── Servicio principal ────────────────────────────────────────────────────────

class ApiService {
  // ── Instancia interna para inyección de dependencias en pruebas ───
  // Las pantallas usan los métodos estáticos igual que antes.
  // Las pruebas crean ApiService(clienteHttp: mock) y llaman métodos de instancia.
  final http.Client clienteHttp;

  ApiService({http.Client? clienteHttp})
    : clienteHttp = clienteHttp ?? http.Client();

  // Instancia interna usada por los métodos estáticos (producción)
  static final ApiService _instanciaProduccion = ApiService();

  // ── Configuración ──────────────────────────────────────────────
  // URL base inyectada en tiempo de compilación (ver AppConfig).
  static const String baseUrl = AppConfig.apiBaseUrl;

  static const String _emailPrueba = 'axel@quiry';
  static const String _passwordPrueba = 'axel1';

  // ── Datos locales de prueba ────────────────────────────────────
  static List<Map<String, dynamic>> get _sitiosPrueba => [
    {
      'id': 1,
      'nombre': 'Machu Picchu (modo local)',
      'descripcion': 'Ciudadela inca del siglo XV.',
      'ubicacion': 'Cusco, Perú',
      'horario': '6:00 AM - 5:30 PM',
    },
  ];

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
          'Esta zona fue construida aproximadamente en el siglo XV durante el apogeo del Imperio Inca.',
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
      'url_recurso':
          'https://www.soundhelix.com/examples/mp3/SoundHelix-Song-1.mp3',
    },
    {
      'id': 4,
      'tipo': 'texto',
      'idioma': 'en',
      'titulo': 'Zone History',
      'descripcion':
          'This zone was built approximately in the 15th century during the height of the Inca Empire.',
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
      'url_recurso':
          'https://www.soundhelix.com/examples/mp3/SoundHelix-Song-2.mp3',
    },
  ];

  // ── Token (estático — las pantallas lo llaman igual que antes) ─
  static Future<void> guardarToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('jwt_token', token);

    // Decodifica el "sub" del JWT (id de Usuario) para no tener que
    // pedirlo de nuevo al backend. El token local de demo no es un JWT
    // real, así que acá queda null y se usa el fallback de más abajo.
    final usuarioId = extraerUsuarioIdDesdeToken(token);
    if (usuarioId != null) {
      await prefs.setInt('usuario_id', usuarioId);
    } else {
      await prefs.remove('usuario_id');
    }
  }

  static Future<String?> obtenerToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('jwt_token');
  }

  /// Id de `Usuario` (NO de `Turista`) leído del JWT guardado en login.
  ///
  /// El backend distingue `Turista.id` de `Usuario.id` y no expone ningún
  /// endpoint para resolver el primero a partir del token — ver
  /// [registrarVisitaZonaInterno]. Retorna `null` en modo demo local.
  static Future<int?> obtenerUsuarioId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt('usuario_id');
  }

  static Future<void> eliminarToken() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('jwt_token');
    await prefs.remove('usuario_id');
  }

  Future<Map<String, String>> _headersConToken() async {
    final token = await ApiService.obtenerToken();
    return {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  // ══════════════════════════════════════════════════════════════
  // MÉTODOS ESTÁTICOS — las pantallas los llaman igual que antes
  // Internamente delegan a la instancia de producción
  // ══════════════════════════════════════════════════════════════

  /// Las pantallas llaman esto: ApiService.iniciarSesion(email, pass)
  /// No cambia nada en login_screen.dart
  static Future<Map<String, dynamic>> iniciarSesion(
    String email,
    String password,
  ) {
    return _instanciaProduccion.iniciarSesionInterno(email, password);
  }

  /// Las pantallas llaman esto: ApiService.obtenerSitios()
  ///
  /// Puede lanzar [ExcepcionSesionExpirada] (no aplica en este endpoint
  /// público, pero se mantiene el mismo contrato que los demás).
  static Future<RespuestaApi<List<dynamic>>> obtenerSitios() {
    return _instanciaProduccion.obtenerSitiosInterno();
  }

  /// Las pantallas llaman esto: ApiService.obtenerZonasDeSitio(id)
  /// Puede lanzar [ExcepcionSesionExpirada] si el token ya no es válido.
  static Future<RespuestaApi<List<dynamic>>> obtenerZonasDeSitio(int sitioId) {
    return _instanciaProduccion.obtenerZonasDeSitioInterno(sitioId);
  }

  /// Las pantallas llaman esto: ApiService.obtenerContenidoDeZona(id)
  /// Puede lanzar [ExcepcionSesionExpirada] si el token ya no es válido.
  static Future<RespuestaApi<List<dynamic>>> obtenerContenidoDeZona(
    int zonaId,
  ) {
    return _instanciaProduccion.obtenerContenidoDeZonaInterno(zonaId);
  }

  /// Las pantallas llaman esto: ApiService.registrarVisitaZona(...)
  static Future<Map<String, dynamic>> registrarVisitaZona({
    required int turistaId,
    required int zonaId,
    String idioma = 'es',
    String? metodoAcceso,
    double? calificacion,
    String? comentario,
  }) {
    return _instanciaProduccion.registrarVisitaZonaInterno(
      turistaId: turistaId,
      zonaId: zonaId,
      idioma: idioma,
      metodoAcceso: metodoAcceso,
      calificacion: calificacion,
      comentario: comentario,
    );
  }

  // ══════════════════════════════════════════════════════════════
  // MÉTODOS DE INSTANCIA — estos sí se pueden mockear en pruebas
  // ══════════════════════════════════════════════════════════════

  /// Autentica al usuario contra la API.
  ///
  /// Retorna Map con {'exito': true, 'datos': {'access_token': ...}}
  /// Lanza [ExcepcionCredencialesInvalidas] si el servidor responde 401.
  Future<Map<String, dynamic>> iniciarSesionInterno(
    String email,
    String password,
  ) async {
    try {
      final respuesta = await clienteHttp
          .post(
            Uri.parse('$baseUrl/auth/login'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({'email': email, 'password': password}),
          )
          .timeout(const Duration(seconds: 4));

      if (respuesta.statusCode == 200) {
        return {'exito': true, 'datos': jsonDecode(respuesta.body)};
      }

      if (respuesta.statusCode == 401) {
        throw const ExcepcionCredencialesInvalidas();
      }
    } catch (excepcion) {
      // Re-lanzar excepciones de dominio — no tragarlas
      if (excepcion is ExcepcionCredencialesInvalidas) rethrow;
      // Backend no disponible → caer a credenciales locales
    }

    // Modo local sin backend
    await Future.delayed(const Duration(milliseconds: 800));
    if (email == _emailPrueba && password == _passwordPrueba) {
      return {
        'exito': true,
        'datos': {'access_token': 'token_local_prueba', 'token_type': 'bearer'},
      };
    }
    return {'exito': false, 'mensaje': 'Credenciales incorrectas'};
  }

  /// Obtiene los sitios arqueológicos disponibles (GET /sitios, público).
  Future<RespuestaApi<List<dynamic>>> obtenerSitiosInterno() async {
    try {
      final respuesta = await clienteHttp
          .get(Uri.parse('$baseUrl/sitios'))
          .timeout(const Duration(seconds: 4));

      if (respuesta.statusCode == 200) {
        return RespuestaApi(jsonDecode(respuesta.body), esDatosLocales: false);
      }
    } catch (_) {
      // Backend no disponible → datos locales
    }
    await Future.delayed(const Duration(milliseconds: 500));
    return RespuestaApi(_sitiosPrueba, esDatosLocales: true);
  }

  /// Obtiene las zonas de un sitio arqueológico.
  ///
  /// Lanza [ExcepcionSesionExpirada] si el backend responde 401 — a
  /// diferencia de un backend caído, ahí NO cae a datos locales.
  Future<RespuestaApi<List<dynamic>>> obtenerZonasDeSitioInterno(
    int sitioId,
  ) async {
    try {
      final headers = await _headersConToken();
      final respuesta = await clienteHttp
          .get(Uri.parse('$baseUrl/sitios/$sitioId/zonas'), headers: headers)
          .timeout(const Duration(seconds: 4));

      if (respuesta.statusCode == 200) {
        return RespuestaApi(jsonDecode(respuesta.body), esDatosLocales: false);
      }
      if (respuesta.statusCode == 401) throw const ExcepcionSesionExpirada();
    } catch (excepcion) {
      if (excepcion is ExcepcionSesionExpirada) rethrow;
      // Backend no disponible → datos locales
    }
    await Future.delayed(const Duration(milliseconds: 500));
    return RespuestaApi(_zonasPrueba, esDatosLocales: true);
  }

  /// Obtiene el contenido multimedia de una zona.
  ///
  /// Lanza [ExcepcionSesionExpirada] si el backend responde 401. Para
  /// cualquier otro error (backend caído, timeout) cae a datos locales
  /// en vez de interrumpir la experiencia del turista.
  Future<RespuestaApi<List<dynamic>>> obtenerContenidoDeZonaInterno(
    int zonaId,
  ) async {
    try {
      final headers = await _headersConToken();
      final respuesta = await clienteHttp
          .get(Uri.parse('$baseUrl/zonas/$zonaId/contenido'), headers: headers)
          .timeout(const Duration(seconds: 4));

      if (respuesta.statusCode == 200) {
        return RespuestaApi(jsonDecode(respuesta.body), esDatosLocales: false);
      }
      if (respuesta.statusCode == 401) throw const ExcepcionSesionExpirada();
    } catch (excepcion) {
      if (excepcion is ExcepcionSesionExpirada) rethrow;
      // Backend no disponible → datos locales
    }
    await Future.delayed(const Duration(milliseconds: 500));
    return RespuestaApi(_contenidoPrueba(zonaId), esDatosLocales: true);
  }

  /// Registra la visita de un turista a una zona (POST /visitas-zona).
  ///
  /// Lanza [ExcepcionRegistrarVisita] si el backend no responde 201 o si
  /// hay un error de red — a diferencia de las lecturas, acá no hay
  /// fallback local: la pantalla debe enterarse y avisar al usuario.
  Future<Map<String, dynamic>> registrarVisitaZonaInterno({
    required int turistaId,
    required int zonaId,
    String idioma = 'es',
    String? metodoAcceso,
    double? calificacion,
    String? comentario,
  }) async {
    try {
      final headers = await _headersConToken();
      final respuesta = await clienteHttp
          .post(
            Uri.parse('$baseUrl/visitas-zona'),
            headers: headers,
            body: jsonEncode({
              'turista_id': turistaId,
              'zona_id': zonaId,
              'idioma': idioma,
              'metodo_acceso': ?metodoAcceso,
              'calificacion': ?calificacion,
              'comentario': ?comentario,
            }),
          )
          .timeout(const Duration(seconds: 4));

      if (respuesta.statusCode == 201) {
        return jsonDecode(respuesta.body);
      }
      if (respuesta.statusCode == 401) throw const ExcepcionSesionExpirada();
      throw const ExcepcionRegistrarVisita();
    } catch (excepcion) {
      if (excepcion is ExcepcionSesionExpirada) rethrow;
      if (excepcion is ExcepcionRegistrarVisita) rethrow;
      throw const ExcepcionRegistrarVisita(
        'No se pudo conectar con el servidor',
      );
    }
  }

  // ── QR — método de instancia directamente (sin estático) ──────

  /// Extrae el ID de zona desde un código QR escaneado.
  ///
  /// Formatos válidos: "zona:5" o simplemente "5".
  /// Lanza [ExcepcionCodigoQRInvalido] si el formato no es reconocido.
  int extraerIdDeZonaDesdeQR(String codigoQR) {
    final codigoLimpio = codigoQR.trim();

    if (codigoLimpio.startsWith('zona:')) {
      final partes = codigoLimpio.split(':');
      final idTexto = partes.length > 1 ? partes[1] : '';
      final idParsed = int.tryParse(idTexto);
      if (idParsed != null && idParsed > 0) return idParsed;
    }

    final idDirecto = int.tryParse(codigoLimpio);
    if (idDirecto != null && idDirecto > 0) return idDirecto;

    throw ExcepcionCodigoQRInvalido(codigoQR);
  }
}
