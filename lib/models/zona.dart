class Zona {
  final int id;
  final String nombre;
  final String descripcion;
  final double? latitud;
  final double? longitud;
  final bool activa;

  Zona({
    required this.id,
    required this.nombre,
    required this.descripcion,
    this.latitud,
    this.longitud,
    required this.activa,
  });

  /// true si la zona tiene coordenadas válidas para ubicarla en el mapa.
  bool get tieneCoordenadas => latitud != null && longitud != null;

  factory Zona.desdeJson(Map<String, dynamic> json) {
    return Zona(
      id: _parsearEntero(json['id']),
      nombre: _parsearTexto(json['nombre']),
      descripcion: _parsearTexto(json['descripcion']),
      latitud: _parsearDecimalOpcional(json['latitud']),
      longitud: _parsearDecimalOpcional(json['longitud']),
      activa: json['activa'] is bool ? json['activa'] as bool : true,
    );
  }

  static int _parsearEntero(dynamic valor) {
    if (valor is num) return valor.toInt();
    if (valor is String) return int.tryParse(valor) ?? 0;
    return 0;
  }

  static String _parsearTexto(dynamic valor) {
    if (valor is String) return valor;
    return '';
  }

  /// Acepta num, String numérico, o null/ausente/string vacío → null.
  static double? _parsearDecimalOpcional(dynamic valor) {
    if (valor is num) return valor.toDouble();
    if (valor is String && valor.trim().isNotEmpty) {
      return double.tryParse(valor);
    }
    return null;
  }
}