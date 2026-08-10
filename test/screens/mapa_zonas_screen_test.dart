import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:mobile/screens/mapa_zonas_screen.dart';

/// No se testea el mapa cargado con datos (requeriría esperar el timeout de
/// red de ApiService y renderizar tiles de OpenStreetMap sobre la red, algo
/// lento y frágil en CI). Se cubre el andamiaje de la pantalla que no
/// depende de la respuesta del backend.
///
/// Cada test drena al final el timer de 500ms del fallback local de
/// ApiService.obtenerZonasDeSitioInterno — si no, flutter_test lo reporta
/// como un timer pendiente al terminar, aunque las aserciones ya pasaron.
Future<void> _pumpMapaZonasYDrenar(WidgetTester tester) async {
  await tester.pumpWidget(const MaterialApp(home: MapaZonasScreen(sitioId: 1)));
  await tester.pump();
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('muestra el indicador de carga apenas se monta', (tester) async {
    await _pumpMapaZonasYDrenar(tester);

    expect(find.byType(CircularProgressIndicator), findsOneWidget);

    await tester.pump(const Duration(seconds: 1));
  });

  testWidgets('el AppBar muestra el título "Mapa de Zonas"', (tester) async {
    await _pumpMapaZonasYDrenar(tester);

    expect(find.text('Mapa de Zonas'), findsOneWidget);

    await tester.pump(const Duration(seconds: 1));
  });

  testWidgets('el botón flotante "Escanear QR" está presente', (tester) async {
    await _pumpMapaZonasYDrenar(tester);

    expect(find.text('Escanear QR'), findsOneWidget);
    expect(find.byIcon(Icons.qr_code_scanner), findsOneWidget);

    await tester.pump(const Duration(seconds: 1));
  });

  testWidgets('el ícono de logout está en el AppBar', (tester) async {
    await _pumpMapaZonasYDrenar(tester);

    expect(find.byIcon(Icons.logout), findsOneWidget);

    await tester.pump(const Duration(seconds: 1));
  });
}
