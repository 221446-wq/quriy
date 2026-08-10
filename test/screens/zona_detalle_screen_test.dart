import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:mobile/models/contenido.dart';
import 'package:mobile/models/zona.dart';
import 'package:mobile/screens/zona_detalle_screen.dart';

/// `contenidoInicial: []` evita la llamada de red al montar la pantalla
/// (ver ZonaDetalleScreen.initState), así estos tests son rápidos y
/// deterministas sin depender del backend ni de su fallback local.
Widget envolverZonaDetalle({List<Contenido>? contenidoInicial}) {
  final zona = Zona(
    id: 1,
    nombre: 'Plaza Sagrada',
    descripcion: 'Centro ceremonial principal.',
    latitud: -13.517,
    longitud: -71.9785,
    activa: true,
  );
  return MaterialApp(
    home: ZonaDetalleScreen(
      zona: zona,
      contenidoInicial: contenidoInicial ?? [],
    ),
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    // registrarVisitaZona usa el token guardado (SharedPreferences).
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('muestra el nombre y la descripción de la zona', (tester) async {
    await tester.pumpWidget(envolverZonaDetalle());
    await tester.pump();

    expect(find.text('Plaza Sagrada'), findsWidgets);
    expect(find.text('Centro ceremonial principal.'), findsOneWidget);
  });

  testWidgets(
    'muestra "No hay contenido en español" cuando no hay contenido inicial',
    (tester) async {
      await tester.pumpWidget(envolverZonaDetalle());
      await tester.pump();

      expect(find.text('No hay contenido en español'), findsOneWidget);
    },
  );

  testWidgets('arranca con las 5 estrellas vacías (sin calificar)', (
    tester,
  ) async {
    await tester.pumpWidget(envolverZonaDetalle());
    await tester.pump();

    expect(find.byIcon(Icons.star_border), findsNWidgets(5));
    expect(find.byIcon(Icons.star), findsNothing);
  });

  testWidgets('tocar la 3ra estrella pinta las estrellas 1, 2 y 3', (
    tester,
  ) async {
    await tester.pumpWidget(envolverZonaDetalle());
    await tester.pump();

    final estrellas = find.byIcon(Icons.star_border);
    await tester.tap(estrellas.at(2)); // la 3ra estrella (índice 2)
    await tester.pump();

    expect(find.byIcon(Icons.star), findsNWidgets(3));
    expect(find.byIcon(Icons.star_border), findsNWidgets(2));
  });

  testWidgets('el botón "Marcar como visitada" arranca visible y habilitado', (
    tester,
  ) async {
    await tester.pumpWidget(envolverZonaDetalle());
    await tester.pump();

    expect(find.text('Marcar como visitada'), findsOneWidget);
    expect(find.byIcon(Icons.check_circle), findsNothing);
  });

  testWidgets(
    'tocar "Marcar como visitada" sin backend real avisa el error y vuelve al estado inicial',
    (tester) async {
      await tester.pumpWidget(envolverZonaDetalle());
      await tester.pump();

      await tester.tap(find.text('Marcar como visitada'));
      await tester.pump(); // dispara el POST (flutter_test lo intercepta)
      await tester.pump(); // procesa la respuesta y el catch de error

      // Sin backend real, registrarVisitaZona falla → SnackBar de error y
      // el botón vuelve a su estado inicial (no se queda trabado).
      expect(find.byType(SnackBar), findsOneWidget);
      expect(find.text('Marcar como visitada'), findsOneWidget);
    },
  );
}
