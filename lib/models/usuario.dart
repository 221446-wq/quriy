class Usuario {
  final int id;
  final String nombre;
  final String email;
  final String rol;
  final String idiomaPref;

  Usuario({
    required this.id,
    required this.nombre,
    required this.email,
    required this.rol,
    this.idiomaPref = 'es',
  });

  factory Usuario.desdeJson(Map<String, dynamic> json) {
    return Usuario(
      id: json['id'],
      nombre: json['nombre'],
      email: json['email'],
      rol: json['rol'],
      idiomaPref: json['idioma_pref'] ?? 'es',
    );
  }
}