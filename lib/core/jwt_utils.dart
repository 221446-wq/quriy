import 'dart:convert';

/// Decodifica el payload de un JWT (sin verificar la firma — eso lo hace
/// el backend en cada request) para leer el `sub` (id de `Usuario`) sin
/// una llamada de red extra a `/auth/me`.
///
/// Retorna `null` si el token no es un JWT válido (ej. el token local
/// de demo `token_local_prueba` que usa el modo sin backend).
int? extraerUsuarioIdDesdeToken(String token) {
  try {
    final partes = token.split('.');
    if (partes.length != 3) return null;

    final payloadJson = utf8.decode(
      base64Url.decode(base64Url.normalize(partes[1])),
    );
    final payload = jsonDecode(payloadJson) as Map<String, dynamic>;

    final sub = payload['sub'];
    if (sub is int) return sub;
    if (sub is String) return int.tryParse(sub);
    return null;
  } catch (_) {
    return null;
  }
}
