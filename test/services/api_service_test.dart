import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:mobile/services/api_service.dart';

// Indica a build_runner que genere MockClient
@GenerateMocks([http.Client])
import 'api_service_test.mocks.dart';

// ── Helper: crea un ApiService usando reflexión para acceder a métodos privados
// Usamos una subclase de prueba que expone los métodos internos sin tocar el original
class ApiServiceDePrueba extends ApiService {
  ApiServiceDePrueba({required http.Client clienteHttp})
    : super(clienteHttp: clienteHttp);

  // Expone _iniciarSesionInterno para las pruebas
  Future<Map<String, dynamic>> autenticarUsuario(
    String email,
    String password,
  ) => iniciarSesionInterno(email, password);

  // Expone _obtenerContenidoDeZonaInterno para las pruebas
  Future<RespuestaApi<List<dynamic>>> consultarContenidoDeZona(int zonaId) =>
      obtenerContenidoDeZonaInterno(zonaId);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  // ── Constantes reutilizables ───────────────────────────────────
  const String urlLogin = 'http://10.0.2.2:8000/auth/login';
  const String urlContenidoZona1 = 'http://10.0.2.2:8000/zonas/1/contenido';
  const String urlContenidoZona9 = 'http://10.0.2.2:8000/zonas/9/contenido';

  const String emailValido = 'axel@quiry';
  const String passwordValido = 'axel1';
  const String emailInvalido = 'intruso@test.com';
  const String passwordInvalida = 'claveErronea';
  const String tokenEsperado = 'jwt_token_quriy_test_2026';

  // ── Mock y servicio preparados antes de cada prueba ───────────
  late MockClient clienteHttpMock;
  late ApiServiceDePrueba servicio;

  setUp(() {
    // Sin esto, _headersConToken() (que usa SharedPreferences) lanza
    // MissingPluginException en el entorno de test; el catch(_) de
    // obtenerContenidoDeZonaInterno la traga y cae al fallback local,
    // haciendo que el mock de MockClient nunca se llegue a usar.
    SharedPreferences.setMockInitialValues({});
    clienteHttpMock = MockClient();
    servicio = ApiServiceDePrueba(clienteHttp: clienteHttpMock);
  });

  // ════════════════════════════════════════════════════════════════
  // GRUPO 1 — autenticarUsuario
  // ════════════════════════════════════════════════════════════════
  group('autenticarUsuario —', () {
    test(
      'retorna token JWT cuando las credenciales son válidas y el servidor responde 200',
      () async {
        // ARRANGE
        when(
          clienteHttpMock.post(
            Uri.parse(urlLogin),
            headers: anyNamed('headers'),
            body: anyNamed('body'),
          ),
        ).thenAnswer(
          (_) async => http.Response(
            jsonEncode({'access_token': tokenEsperado, 'token_type': 'bearer'}),
            200,
          ),
        );

        // ACT
        final resultado = await servicio.autenticarUsuario(
          emailValido,
          passwordValido,
        );

        // ASSERT
        expect(resultado['exito'], isTrue);
        expect(resultado['datos']['access_token'], equals(tokenEsperado));
      },
    );

    test(
      'el token retornado no está vacío cuando las credenciales son correctas',
      () async {
        // ARRANGE
        when(
          clienteHttpMock.post(
            Uri.parse(urlLogin),
            headers: anyNamed('headers'),
            body: anyNamed('body'),
          ),
        ).thenAnswer(
          (_) async => http.Response(
            jsonEncode({'access_token': tokenEsperado, 'token_type': 'bearer'}),
            200,
          ),
        );

        // ACT
        final resultado = await servicio.autenticarUsuario(
          emailValido,
          passwordValido,
        );

        // ASSERT
        expect(resultado['datos']['access_token'], isNotEmpty);
      },
    );

    test(
      'lanza ExcepcionCredencialesInvalidas cuando el servidor responde 401',
      () async {
        // ARRANGE
        when(
          clienteHttpMock.post(
            Uri.parse(urlLogin),
            headers: anyNamed('headers'),
            body: anyNamed('body'),
          ),
        ).thenAnswer(
          (_) async =>
              http.Response(jsonEncode({'detail': 'Unauthorized'}), 401),
        );

        // ACT + ASSERT
        expect(
          () => servicio.autenticarUsuario(emailInvalido, passwordInvalida),
          throwsA(isA<ExcepcionCredencialesInvalidas>()),
        );
      },
    );

    test(
      'el mensaje de ExcepcionCredencialesInvalidas contiene texto descriptivo',
      () async {
        // ARRANGE
        when(
          clienteHttpMock.post(
            Uri.parse(urlLogin),
            headers: anyNamed('headers'),
            body: anyNamed('body'),
          ),
        ).thenAnswer(
          (_) async =>
              http.Response(jsonEncode({'detail': 'Unauthorized'}), 401),
        );

        // ACT + ASSERT
        expect(
          () => servicio.autenticarUsuario(emailInvalido, passwordInvalida),
          throwsA(
            isA<ExcepcionCredencialesInvalidas>().having(
              (e) => e.mensaje,
              'mensaje',
              contains('Credenciales'),
            ),
          ),
        );
      },
    );
  });

  // ════════════════════════════════════════════════════════════════
  // GRUPO 2 — obtenerContenidoDeZona
  // ════════════════════════════════════════════════════════════════
  group('obtenerContenidoDeZona —', () {
    test(
      'retorna lista de contenidos cuando el servidor responde 200',
      () async {
        // ARRANGE
        when(
          clienteHttpMock.get(
            Uri.parse(urlContenidoZona1),
            headers: anyNamed('headers'),
          ),
        ).thenAnswer(
          (_) async => http.Response(
            jsonEncode([
              {
                'id': 1,
                'tipo': 'texto',
                'idioma': 'es',
                'titulo': 'Historia de la zona',
                'descripcion': 'Construida en el siglo XV.',
                'url_recurso': '',
              },
              {
                'id': 2,
                'tipo': 'audio',
                'idioma': 'es',
                'titulo': 'Audioguía en español',
                'descripcion': 'Narración completa.',
                'url_recurso': 'https://ejemplo.com/audio.mp3',
              },
            ]),
            200,
          ),
        );

        // ACT
        final respuesta = await servicio.consultarContenidoDeZona(1);

        // ASSERT
        expect(respuesta.esDatosLocales, isFalse);
        expect(respuesta.datos, isNotEmpty);
        expect(respuesta.datos.length, equals(2));
        expect(respuesta.datos.first['tipo'], equals('texto'));
      },
    );

    test('maneja respuesta vacía del servidor sin lanzar excepción', () async {
      // ARRANGE — zona sin contenido cargado aún
      when(
        clienteHttpMock.get(
          Uri.parse(urlContenidoZona9),
          headers: anyNamed('headers'),
        ),
      ).thenAnswer((_) async => http.Response('[]', 200));

      // ACT
      final respuesta = await servicio.consultarContenidoDeZona(9);

      // ASSERT — lista vacía real del servidor, no el fallback local
      expect(respuesta.esDatosLocales, isFalse);
      expect(respuesta.datos, isEmpty);
    });

    test(
      'no lanza excepción cuando el servidor retorna arreglo vacío',
      () async {
        // ARRANGE
        when(
          clienteHttpMock.get(
            Uri.parse(urlContenidoZona9),
            headers: anyNamed('headers'),
          ),
        ).thenAnswer((_) async => http.Response('[]', 200));

        // ASSERT — la llamada no explota
        expect(() => servicio.consultarContenidoDeZona(9), returnsNormally);
      },
    );

    test(
      'el contenido retornado incluye los campos tipo, idioma y titulo',
      () async {
        // ARRANGE
        when(
          clienteHttpMock.get(
            Uri.parse(urlContenidoZona1),
            headers: anyNamed('headers'),
          ),
        ).thenAnswer(
          (_) async => http.Response(
            jsonEncode([
              {
                'id': 10,
                'tipo': 'imagen',
                'idioma': 'en',
                'titulo': 'Panoramic view',
                'descripcion': 'Aerial photo.',
                'url_recurso': 'https://ejemplo.com/foto.jpg',
              },
            ]),
            200,
          ),
        );

        // ACT
        final respuesta = await servicio.consultarContenidoDeZona(1);
        final primerElemento = respuesta.datos.first as Map<String, dynamic>;

        // ASSERT
        expect(primerElemento.containsKey('tipo'), isTrue);
        expect(primerElemento.containsKey('idioma'), isTrue);
        expect(primerElemento.containsKey('titulo'), isTrue);
      },
    );

    test('filtra correctamente contenido por idioma español', () async {
      // ARRANGE — contenido mixto en dos idiomas
      when(
        clienteHttpMock.get(
          Uri.parse(urlContenidoZona1),
          headers: anyNamed('headers'),
        ),
      ).thenAnswer(
        (_) async => http.Response(
          jsonEncode([
            {
              'id': 1,
              'tipo': 'texto',
              'idioma': 'es',
              'titulo': 'Historia',
              'descripcion': '',
              'url_recurso': '',
            },
            {
              'id': 2,
              'tipo': 'texto',
              'idioma': 'en',
              'titulo': 'History',
              'descripcion': '',
              'url_recurso': '',
            },
            {
              'id': 3,
              'tipo': 'audio',
              'idioma': 'es',
              'titulo': 'Audioguía',
              'descripcion': '',
              'url_recurso': 'a.mp3',
            },
          ]),
          200,
        ),
      );

      // ACT
      final respuesta = await servicio.consultarContenidoDeZona(1);
      final soloEnEspanol = respuesta.datos
          .where((c) => (c as Map)['idioma'] == 'es')
          .toList();

      // ASSERT — el mock tiene 2 ítems 'es' (id 1 y 3) y 1 'en' (id 2)
      expect(soloEnEspanol.length, equals(2));
      expect(soloEnEspanol.every((c) => (c as Map)['idioma'] == 'es'), isTrue);
    });
  });

  // ════════════════════════════════════════════════════════════════
  // GRUPO 3 — registrarVisitaZona
  // ════════════════════════════════════════════════════════════════
  group('registrarVisitaZonaInterno —', () {
    const String urlVisitas = 'http://10.0.2.2:8000/visitas-zona';

    test(
      'retorna la visita registrada cuando el servidor responde 201',
      () async {
        // ARRANGE
        when(
          clienteHttpMock.post(
            Uri.parse(urlVisitas),
            headers: anyNamed('headers'),
            body: anyNamed('body'),
          ),
        ).thenAnswer(
          (_) async => http.Response(
            jsonEncode({
              'id': 42,
              'turista_id': 1,
              'zona_id': 5,
              'timestamp': '2026-08-09T20:00:00',
              'idioma': 'es',
              'metodo_acceso': 'app',
              'calificacion': 4.0,
              'comentario': null,
            }),
            201,
          ),
        );

        // ACT
        final resultado = await servicio.registrarVisitaZonaInterno(
          turistaId: 1,
          zonaId: 5,
          idioma: 'es',
          metodoAcceso: 'app',
          calificacion: 4.0,
        );

        // ASSERT
        expect(resultado['id'], equals(42));
        expect(resultado['zona_id'], equals(5));
      },
    );

    test(
      'envía turista_id, zona_id, idioma y calificación en el body',
      () async {
        // ARRANGE
        when(
          clienteHttpMock.post(
            Uri.parse(urlVisitas),
            headers: anyNamed('headers'),
            body: anyNamed('body'),
          ),
        ).thenAnswer(
          (_) async => http.Response(
            jsonEncode({
              'id': 1,
              'turista_id': 7,
              'zona_id': 9,
              'timestamp': '2026-08-09T20:00:00',
              'idioma': 'en',
            }),
            201,
          ),
        );

        // ACT
        await servicio.registrarVisitaZonaInterno(
          turistaId: 7,
          zonaId: 9,
          idioma: 'en',
          metodoAcceso: 'qr',
          calificacion: 5.0,
        );

        // ASSERT — inspecciona el body real enviado al backend
        final llamada = verify(
          clienteHttpMock.post(
            Uri.parse(urlVisitas),
            headers: anyNamed('headers'),
            body: captureAnyNamed('body'),
          ),
        )..called(1);
        final bodyEnviado = jsonDecode(llamada.captured.single as String);

        expect(bodyEnviado['turista_id'], equals(7));
        expect(bodyEnviado['zona_id'], equals(9));
        expect(bodyEnviado['idioma'], equals('en'));
        expect(bodyEnviado['metodo_acceso'], equals('qr'));
        expect(bodyEnviado['calificacion'], equals(5.0));
      },
    );

    test(
      'lanza ExcepcionSesionExpirada cuando el servidor responde 401',
      () async {
        // ARRANGE
        when(
          clienteHttpMock.post(
            Uri.parse(urlVisitas),
            headers: anyNamed('headers'),
            body: anyNamed('body'),
          ),
        ).thenAnswer(
          (_) async =>
              http.Response(jsonEncode({'detail': 'Unauthorized'}), 401),
        );

        // ACT + ASSERT
        expect(
          () => servicio.registrarVisitaZonaInterno(turistaId: 1, zonaId: 5),
          throwsA(isA<ExcepcionSesionExpirada>()),
        );
      },
    );

    test(
      'lanza ExcepcionRegistrarVisita cuando el servidor responde un error distinto de 401',
      () async {
        // ARRANGE
        when(
          clienteHttpMock.post(
            Uri.parse(urlVisitas),
            headers: anyNamed('headers'),
            body: anyNamed('body'),
          ),
        ).thenAnswer(
          (_) async =>
              http.Response(jsonEncode({'detail': 'Zona no encontrada'}), 404),
        );

        // ACT + ASSERT
        expect(
          () => servicio.registrarVisitaZonaInterno(turistaId: 1, zonaId: 999),
          throwsA(isA<ExcepcionRegistrarVisita>()),
        );
      },
    );

    test(
      'lanza ExcepcionRegistrarVisita cuando falla la conexión con el servidor',
      () async {
        // ARRANGE
        when(
          clienteHttpMock.post(
            Uri.parse(urlVisitas),
            headers: anyNamed('headers'),
            body: anyNamed('body'),
          ),
        ).thenThrow(Exception('Connection refused'));

        // ACT + ASSERT
        expect(
          () => servicio.registrarVisitaZonaInterno(turistaId: 1, zonaId: 5),
          throwsA(
            isA<ExcepcionRegistrarVisita>().having(
              (e) => e.mensaje,
              'mensaje',
              contains('conectar'),
            ),
          ),
        );
      },
    );
  });

  // ════════════════════════════════════════════════════════════════
  // GRUPO 4 — extraerIdDeZonaDesdeQR
  // ════════════════════════════════════════════════════════════════
  group('extraerIdDeZonaDesdeQR —', () {
    test('extrae el ID cuando el QR tiene formato "zona:N"', () {
      expect(servicio.extraerIdDeZonaDesdeQR('zona:3'), equals(3));
    });

    test('extrae el ID cuando el QR contiene solo el número', () {
      expect(servicio.extraerIdDeZonaDesdeQR('7'), equals(7));
    });

    test('ignora espacios alrededor del código QR', () {
      expect(servicio.extraerIdDeZonaDesdeQR('  zona:4  '), equals(4));
    });

    test(
      'extrae el ID desde la URL de destino real que genera el backend',
      () {
        expect(
          servicio.extraerIdDeZonaDesdeQR('https://quriy.app/zonas/5'),
          equals(5),
        );
      },
    );

    test('extrae el ID desde una URL de destino con otro dominio', () {
      expect(
        servicio.extraerIdDeZonaDesdeQR(
          'https://quriy.onrender.com/zonas/12',
        ),
        equals(12),
      );
    });

    test(
      'lanza ExcepcionCodigoQRInvalido cuando el QR tiene texto no numérico',
      () {
        expect(
          () => servicio.extraerIdDeZonaDesdeQR('https://sitio-externo.com'),
          throwsA(isA<ExcepcionCodigoQRInvalido>()),
        );
      },
    );

    test(
      'el mensaje de ExcepcionCodigoQRInvalido incluye el código recibido',
      () {
        const codigoDesconocido = 'QR_DESCONOCIDO_XYZ';

        expect(
          () => servicio.extraerIdDeZonaDesdeQR(codigoDesconocido),
          throwsA(
            isA<ExcepcionCodigoQRInvalido>().having(
              (e) => e.toString(),
              'toString',
              contains(codigoDesconocido),
            ),
          ),
        );
      },
    );

    test('lanza ExcepcionCodigoQRInvalido cuando el QR está vacío', () {
      expect(
        () => servicio.extraerIdDeZonaDesdeQR(''),
        throwsA(isA<ExcepcionCodigoQRInvalido>()),
      );
    });

    test(
      'lanza ExcepcionCodigoQRInvalido cuando zona: contiene texto en lugar de número',
      () {
        expect(
          () => servicio.extraerIdDeZonaDesdeQR('zona:abc'),
          throwsA(isA<ExcepcionCodigoQRInvalido>()),
        );
      },
    );

    test(
      'lanza ExcepcionCodigoQRInvalido cuando el ID es cero — no existe zona 0',
      () {
        expect(
          () => servicio.extraerIdDeZonaDesdeQR('zona:0'),
          throwsA(isA<ExcepcionCodigoQRInvalido>()),
        );
      },
    );

    test('lanza ExcepcionCodigoQRInvalido cuando el ID es negativo', () {
      expect(
        () => servicio.extraerIdDeZonaDesdeQR('-5'),
        throwsA(isA<ExcepcionCodigoQRInvalido>()),
      );
    });
  });

  // ════════════════════════════════════════════════════════════════
  // GRUPO 5 — cobertura de las clases de excepción
  // ════════════════════════════════════════════════════════════════
  group('ExcepcionCodigoQRInvalido —', () {
    test(
      'toString incluye el código recibido para facilitar el diagnóstico',
      () {
        const codigo = 'QR_ROTO_123';
        final excepcion = const ExcepcionCodigoQRInvalido(codigo);

        expect(excepcion.toString(), contains(codigo));
      },
    );

    test('es instancia de Exception', () {
      expect(const ExcepcionCodigoQRInvalido('test'), isA<Exception>());
    });
  });

  group('ExcepcionCredencialesInvalidas —', () {
    test('tiene mensaje por defecto cuando no se pasa ninguno', () {
      const excepcion = ExcepcionCredencialesInvalidas();
      expect(excepcion.mensaje, equals('Credenciales incorrectas'));
    });

    test('acepta mensaje personalizado', () {
      const excepcion = ExcepcionCredencialesInvalidas(
        'Email o contraseña incorrectos',
      );
      expect(excepcion.mensaje, contains('Email'));
    });

    test('toString incluye el nombre de la clase', () {
      const excepcion = ExcepcionCredencialesInvalidas();
      expect(excepcion.toString(), contains('ExcepcionCredencialesInvalidas'));
    });

    test('es instancia de Exception', () {
      expect(const ExcepcionCredencialesInvalidas(), isA<Exception>());
    });
  });
}
