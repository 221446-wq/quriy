import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/models/zona.dart';

void main() {
  group('Zona.desdeJson — coordenadas', () {
    test('JSON completo con lat/lon numéricos parsea correctamente', () {
      final zona = Zona.desdeJson({
        'id': 1,
        'nombre': 'Plaza Sagrada',
        'descripcion': 'Centro ceremonial',
        'latitud': -13.5170,
        'longitud': -71.9785,
        'activa': true,
      });

      expect(zona.id, equals(1));
      expect(zona.nombre, equals('Plaza Sagrada'));
      expect(zona.descripcion, equals('Centro ceremonial'));
      expect(zona.latitud, equals(-13.5170));
      expect(zona.longitud, equals(-71.9785));
      expect(zona.activa, isTrue);
      expect(zona.tieneCoordenadas, isTrue);
    });

    test('lat/lon en null no lanza excepción y quedan null', () {
      final zona = Zona.desdeJson({
        'id': 2,
        'nombre': 'Sector sin ubicar',
        'descripcion': '',
        'latitud': null,
        'longitud': null,
        'activa': true,
      });

      expect(zona.latitud, isNull);
      expect(zona.longitud, isNull);
      expect(zona.tieneCoordenadas, isFalse);
    });

    test('JSON sin las claves latitud/longitud no lanza excepción', () {
      final zona = Zona.desdeJson({
        'id': 3,
        'nombre': 'Sector sin claves',
        'descripcion': '',
        'activa': true,
      });

      expect(zona.latitud, isNull);
      expect(zona.longitud, isNull);
      expect(zona.tieneCoordenadas, isFalse);
    });

    test('lat/lon como String numérico se parsean a double', () {
      final zona = Zona.desdeJson({
        'id': 4,
        'nombre': 'Sector con strings',
        'descripcion': '',
        'latitud': '-13.5170',
        'longitud': '-71.9785',
        'activa': true,
      });

      expect(zona.latitud, equals(-13.5170));
      expect(zona.longitud, equals(-71.9785));
      expect(zona.tieneCoordenadas, isTrue);
    });

    test('lat/lon como String vacío quedan null en vez de lanzar excepción', () {
      final zona = Zona.desdeJson({
        'id': 5,
        'nombre': 'Sector con strings vacíos',
        'descripcion': '',
        'latitud': '',
        'longitud': '',
        'activa': true,
      });

      expect(zona.latitud, isNull);
      expect(zona.longitud, isNull);
    });

    test('lat/lon como String no numérico quedan null en vez de lanzar excepción', () {
      final zona = Zona.desdeJson({
        'id': 6,
        'nombre': 'Sector con strings inválidos',
        'descripcion': '',
        'latitud': 'no-es-un-numero',
        'longitud': 'tampoco',
        'activa': true,
      });

      expect(zona.latitud, isNull);
      expect(zona.longitud, isNull);
    });
  });

  group('Zona.desdeJson — campos obligatorios con parseo defensivo', () {
    test('id ausente cae a valor por defecto 0 en vez de lanzar excepción', () {
      final zona = Zona.desdeJson({
        'nombre': 'Sin id',
        'descripcion': '',
        'activa': true,
      });

      expect(zona.id, equals(0));
    });

    test('id como String numérico se parsea a int', () {
      final zona = Zona.desdeJson({
        'id': '7',
        'nombre': 'Id como string',
        'descripcion': '',
        'activa': true,
      });

      expect(zona.id, equals(7));
    });

    test('nombre y descripcion ausentes caen a string vacío', () {
      final zona = Zona.desdeJson({'id': 8, 'activa': true});

      expect(zona.nombre, equals(''));
      expect(zona.descripcion, equals(''));
    });

    test('activa ausente o con tipo inválido cae a true por defecto', () {
      final zonaSinActiva = Zona.desdeJson({
        'id': 9,
        'nombre': 'Sin activa',
        'descripcion': '',
      });
      final zonaActivaInvalida = Zona.desdeJson({
        'id': 10,
        'nombre': 'Activa inválida',
        'descripcion': '',
        'activa': 'si',
      });

      expect(zonaSinActiva.activa, isTrue);
      expect(zonaActivaInvalida.activa, isTrue);
    });

    test('JSON completamente vacío no lanza excepción', () {
      expect(() => Zona.desdeJson({}), returnsNormally);
    });
  });
}
