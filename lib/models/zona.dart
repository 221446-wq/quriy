class Zona {
  final int id;
  final String nombre;
  final String descripcion;
  final double latitud;
  final double longitud;
  final bool activa;

  Zona({
    required this.id,
    required this.nombre,
    required this.descripcion,
    required this.latitud,
    required this.longitud,
    required this.activa,
  });

  factory Zona.desdeJson(Map<String, dynamic> json) {
    return Zona(
      id: json['id'],
      nombre: json['nombre'],
      descripcion: json['descripcion'] ?? '',
      latitud: (json['latitud'] as num).toDouble(),
      longitud: (json['longitud'] as num).toDouble(),
      activa: json['activa'] ?? true,
    );
  }
}