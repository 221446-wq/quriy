import '../core/config/app_config.dart';

class Contenido {
  final int id;
  final int zonaId;
  final String tipo;
  final String idioma;
  final String titulo;
  final String descripcion;
  final String urlRecurso;

  Contenido({
    required this.id,
    required this.zonaId,
    required this.tipo,
    required this.idioma,
    required this.titulo,
    required this.descripcion,
    required this.urlRecurso,
  });

  factory Contenido.desdeJson(Map<String, dynamic> json) {
    return Contenido(
      id: _parsearEntero(json['id']),
      zonaId: _parsearEntero(json['zona_id']),
      tipo: _parsearTexto(json['tipo'], porDefecto: 'texto'),
      idioma: _parsearTexto(json['idioma'], porDefecto: 'es'),
      titulo: _parsearTexto(json['titulo']),
      // El backend expone el cuerpo de texto en la clave "texto"
      // (ContenidoResponse.texto). Se acepta "descripcion" como respaldo
      // porque el mock local de ApiService todavía usa ese nombre.
      descripcion: _parsearTexto(json['texto'] ?? json['descripcion']),
      urlRecurso: _resolverUrlRecurso(json['url_recurso']),
    );
  }

  static int _parsearEntero(dynamic valor) {
    if (valor is num) return valor.toInt();
    if (valor is String) return int.tryParse(valor) ?? 0;
    return 0;
  }

  static String _parsearTexto(dynamic valor, {String porDefecto = ''}) {
    if (valor is String && valor.trim().isNotEmpty) return valor;
    return porDefecto;
  }

  /// El endpoint de subida de archivos (`POST /contenido/upload`) devuelve
  /// `url_recurso` como una ruta relativa (ej. "/static/audio/x.mp3"), no
  /// como una URL completa — por eso hay que anteponerle el host de la API
  /// para que `just_audio`/`CachedNetworkImage` puedan cargarla. Si ya viene
  /// absoluta (http/https, ej. datos de demo o un recurso externo) se deja
  /// tal cual.
  static String _resolverUrlRecurso(dynamic valor) {
    final texto = _parsearTexto(valor);
    if (texto.isEmpty) return texto;

    final uri = Uri.tryParse(texto);
    if (uri != null && uri.hasScheme) return texto;

    final separador = texto.startsWith('/') ? '' : '/';
    return '${AppConfig.apiBaseUrl}$separador$texto';
  }
}
