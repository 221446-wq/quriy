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
