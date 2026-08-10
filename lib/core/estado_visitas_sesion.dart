/// Registro en memoria de las zonas marcadas como visitadas durante esta
/// sesión de la app.
///
/// No persiste entre reinicios ni viene del backend: no existe ningún
/// endpoint que un turista pueda consultar para saber qué zonas visitó
/// (`ZonaResponse` no trae ese campo y `GET /valoraciones` es solo para
/// admins). Es feedback visual inmediato, no la fuente de verdad.
class EstadoVisitasSesion {
  EstadoVisitasSesion._();

  static final Set<int> _idsVisitados = {};

  static bool estaVisitada(int zonaId) => _idsVisitados.contains(zonaId);

  static void marcarVisitada(int zonaId) => _idsVisitados.add(zonaId);
}
