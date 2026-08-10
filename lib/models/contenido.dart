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
      urlRecurso: _parsearTexto(json['url_recurso']),
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
}
