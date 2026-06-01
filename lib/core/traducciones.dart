/// Maneja todas las cadenas de texto de la app en español e inglés.
/// Patrón Strategy: intercambia el comportamiento de traducción en tiempo de ejecución.
abstract class Traducciones {
  // ── Navegación ────────────────────────────────────────────────
  String get tituloMapaZonas;
  String get tituloEscanerQR;
  String get tituloDetalleZona;
  String get tituloContenidoMultimedia;

  // ── Login ─────────────────────────────────────────────────────
  String get etiquetaCorreo;
  String get etiquetaContrasena;
  String get botonIngresar;
  String get mensajeCargando;
  String get errorCredenciales;
  String get errorConexion;

  // ── Mapa ──────────────────────────────────────────────────────
  String get botonEscanearQR;
  String get errorCargaZonas;
  String get botonReintentar;
  String get etiquetaZonaVisitada;
  String get etiquetaZonaActiva;

  // ── Escáner QR ────────────────────────────────────────────────
  String get instruccionEscanear;
  String get errorQRInvalido;
  String get errorZonaSinContenido;

  // ── Detalle de zona ───────────────────────────────────────────
  String get etiquetaSinContenido;
  String get botonReproducir;
  String get botonPausar;
  String get etiquetaAudioguia;
  String get etiquetaImagen;
  String get etiquetaTexto;

  // ── Tipos de contenido ────────────────────────────────────────
  String get tipoAudio;
  String get tipoImagen;
  String get tipoTexto;

  // ── Selector de idioma ────────────────────────────────────────
  String get codigoIdioma; // 'es' o 'en'
  String get nombreIdioma;
}

/// Implementación en español.
class TraduccionesEspanol implements Traducciones {
  const TraduccionesEspanol();

  @override String get codigoIdioma         => 'es';
  @override String get nombreIdioma         => '🇵🇪 Español';

  @override String get tituloMapaZonas      => 'Mapa de Zonas';
  @override String get tituloEscanerQR      => 'Escanear QR';
  @override String get tituloDetalleZona    => 'Detalle de Zona';
  @override String get tituloContenidoMultimedia => 'Contenido multimedia';

  @override String get etiquetaCorreo       => 'Correo electrónico';
  @override String get etiquetaContrasena   => 'Contraseña';
  @override String get botonIngresar        => 'Ingresar';
  @override String get mensajeCargando      => 'Cargando...';
  @override String get errorCredenciales    => 'Credenciales incorrectas';
  @override String get errorConexion        => 'No se pudo conectar al servidor';

  @override String get botonEscanearQR      => 'Escanear QR';
  @override String get errorCargaZonas      => 'No se pudieron cargar las zonas. Verifica tu conexión.';
  @override String get botonReintentar      => 'Reintentar';
  @override String get etiquetaZonaVisitada => 'Visitada';
  @override String get etiquetaZonaActiva   => 'Activa';

  @override String get instruccionEscanear  => 'Apunta al código QR de la zona';
  @override String get errorQRInvalido      => 'Código QR no válido para este sitio';
  @override String get errorZonaSinContenido => 'No se encontró contenido para esta zona';

  @override String get etiquetaSinContenido => 'No hay contenido en español';
  @override String get botonReproducir      => 'Reproducir audioguía';
  @override String get botonPausar          => 'Pausar';
  @override String get etiquetaAudioguia    => 'Audioguía';
  @override String get etiquetaImagen       => 'Imagen';
  @override String get etiquetaTexto        => 'Información';

  @override String get tipoAudio            => 'AUDIO';
  @override String get tipoImagen           => 'IMAGEN';
  @override String get tipoTexto            => 'TEXTO';
}

/// Implementación en inglés.
class TraduccionesIngles implements Traducciones {
  const TraduccionesIngles();

  @override String get codigoIdioma         => 'en';
  @override String get nombreIdioma         => '🇺🇸 English';

  @override String get tituloMapaZonas      => 'Zone Map';
  @override String get tituloEscanerQR      => 'Scan QR';
  @override String get tituloDetalleZona    => 'Zone Detail';
  @override String get tituloContenidoMultimedia => 'Multimedia content';

  @override String get etiquetaCorreo       => 'Email address';
  @override String get etiquetaContrasena   => 'Password';
  @override String get botonIngresar        => 'Sign in';
  @override String get mensajeCargando      => 'Loading...';
  @override String get errorCredenciales    => 'Incorrect credentials';
  @override String get errorConexion        => 'Could not connect to server';

  @override String get botonEscanearQR      => 'Scan QR';
  @override String get errorCargaZonas      => 'Could not load zones. Check your connection.';
  @override String get botonReintentar      => 'Retry';
  @override String get etiquetaZonaVisitada => 'Visited';
  @override String get etiquetaZonaActiva   => 'Active';

  @override String get instruccionEscanear  => 'Point at the zone QR code';
  @override String get errorQRInvalido      => 'QR code not valid for this site';
  @override String get errorZonaSinContenido => 'No content found for this zone';

  @override String get etiquetaSinContenido => 'No content available in English';
  @override String get botonReproducir      => 'Play audio guide';
  @override String get botonPausar          => 'Pause';
  @override String get etiquetaAudioguia    => 'Audio guide';
  @override String get etiquetaImagen       => 'Image';
  @override String get etiquetaTexto        => 'Information';

  @override String get tipoAudio            => 'AUDIO';
  @override String get tipoImagen           => 'IMAGE';
  @override String get tipoTexto            => 'TEXT';
}

/// Fábrica que retorna la instancia correcta según código de idioma.
class FabricaDeTraducciones {
  FabricaDeTraducciones._();

  static Traducciones obtenerPorCodigo(String codigoIdioma) {
    return switch (codigoIdioma) {
      'en' => const TraduccionesIngles(),
      _    => const TraduccionesEspanol(),
    };
  }
}