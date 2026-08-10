import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/models/contenido.dart';

void main() {
  group('Contenido.desdeJson — contrato real del backend (campo "texto")', () {
    test('JSON completo con "texto" (nombre real del backend) parsea correctamente', () {
      final contenido = Contenido.desdeJson({
        'id': 1,
        'zona_id': 3,
        'tipo': 'texto',
        'idioma': 'es',
        'titulo': 'Historia de la zona',
        'texto': 'Construida en el siglo XV.',
        'url_recurso': null,
      });

      expect(contenido.id, equals(1));
      expect(contenido.zonaId, equals(3));
      expect(contenido.tipo, equals('texto'));
      expect(contenido.idioma, equals('es'));
      expect(contenido.titulo, equals('Historia de la zona'));
      expect(contenido.descripcion, equals('Construida en el siglo XV.'));
      expect(contenido.urlRecurso, equals(''));
    });

    test('cae a "descripcion" cuando "texto" no viene (compatibilidad con el mock local)', () {
      final contenido = Contenido.desdeJson({
        'id': 2,
        'zona_id': 3,
        'tipo': 'texto',
        'idioma': 'es',
        'titulo': 'Historia',
        'descripcion': 'Texto del mock local.',
      });

      expect(contenido.descripcion, equals('Texto del mock local.'));
    });

    test('"texto" ausente y sin "descripcion" no lanza excepción, queda vacío', () {
      final contenido = Contenido.desdeJson({
        'id': 3,
        'zona_id': 3,
        'tipo': 'texto',
        'idioma': 'es',
        'titulo': 'Sin cuerpo',
      });

      expect(contenido.descripcion, equals(''));
    });
  });

  group('Contenido.desdeJson — url_recurso', () {
    test('url_recurso null no lanza excepción y queda string vacío', () {
      final contenido = Contenido.desdeJson({
        'id': 4,
        'zona_id': 3,
        'tipo': 'imagen',
        'idioma': 'es',
        'titulo': 'Vista panorámica',
        'texto': '',
        'url_recurso': null,
      });

      expect(contenido.urlRecurso, equals(''));
    });

    test('url_recurso ausente no lanza excepción y queda string vacío', () {
      final contenido = Contenido.desdeJson({
        'id': 5,
        'zona_id': 3,
        'tipo': 'audio',
        'idioma': 'es',
        'titulo': 'Audioguía',
      });

      expect(contenido.urlRecurso, equals(''));
    });

    test('url_recurso con valor se parsea sin cambios', () {
      final contenido = Contenido.desdeJson({
        'id': 6,
        'zona_id': 3,
        'tipo': 'audio',
        'idioma': 'es',
        'titulo': 'Audioguía',
        'url_recurso': 'https://ejemplo.com/audio.mp3',
      });

      expect(contenido.urlRecurso, equals('https://ejemplo.com/audio.mp3'));
    });
  });

  group('Contenido.desdeJson — campos obligatorios con parseo defensivo', () {
    test('JSON completamente vacío no lanza excepción', () {
      expect(() => Contenido.desdeJson({}), returnsNormally);
    });

    test('tipo e idioma ausentes caen a valores por defecto', () {
      final contenido = Contenido.desdeJson({'id': 7});

      expect(contenido.tipo, equals('texto'));
      expect(contenido.idioma, equals('es'));
    });

    test('id y zona_id ausentes caen a 0 en vez de lanzar excepción', () {
      final contenido = Contenido.desdeJson({'tipo': 'texto'});

      expect(contenido.id, equals(0));
      expect(contenido.zonaId, equals(0));
    });

    test('id como String numérico se parsea a int', () {
      final contenido = Contenido.desdeJson({'id': '9', 'zona_id': '3'});

      expect(contenido.id, equals(9));
      expect(contenido.zonaId, equals(3));
    });
  });
}
