/// Configuración de entorno de la app.
///
/// La URL base del backend se inyecta en tiempo de compilación con
/// `--dart-define=API_BASE_URL=http://...` (ver README.md, sección
/// "Configuración de entorno"). Si no se define, cae al valor por defecto
/// del emulador Android (`10.0.2.2` apunta al `localhost` del host).
class AppConfig {
  AppConfig._();

  static const String apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'https://quriy.onrender.com',
  );

  /// Client ID *web* de OAuth de Google Cloud, usado como `serverClientId`
  /// al iniciar Google Sign-In. Debe ser el mismo client ID que el backend
  /// tiene configurado en `GOOGLE_CLIENT_ID` (ver `backend/app/auth.py`),
  /// ya que el backend valida el `audience` del id_token contra ese valor.
  /// Se inyecta con `--dart-define=GOOGLE_SERVER_CLIENT_ID=...`.
  static const String googleServerClientId = String.fromEnvironment(
    'GOOGLE_SERVER_CLIENT_ID',
    defaultValue: '',
  );

  /// Falla rápido y con un mensaje claro si alguien define
  /// `API_BASE_URL` vacío por error. Solo corre en debug.
  static void validar() {
    assert(() {
      if (apiBaseUrl.trim().isEmpty) {
        throw StateError(
          'AppConfig.apiBaseUrl está vacío. Ejecuta la app con '
          '--dart-define=API_BASE_URL=http://<host>:<puerto> '
          '(ver README.md → Configuración de entorno).',
        );
      }
      return true;
    }());
  }
}
