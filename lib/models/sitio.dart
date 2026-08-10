class Sitio {
  final int id;
  final String nombre;
  final String descripcion;
  final String ubicacion;
  final String horario;
  final String imagenUrl;

  Sitio({
    required this.id,
    required this.nombre,
    required this.descripcion,
    required this.ubicacion,
    required this.horario,
    this.imagenUrl = '',
  });

  factory Sitio.desdeJson(Map<String, dynamic> json) {
    return Sitio(
      id: _parsearEntero(json['id']),
      nombre: _parsearTexto(json['nombre']),
      descripcion: _parsearTexto(json['descripcion']),
      ubicacion: _parsearTexto(json['ubicacion']),
      horario: _parsearTexto(json['horario']),
      imagenUrl: _parsearTexto(json['imagen_url']),
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
}
