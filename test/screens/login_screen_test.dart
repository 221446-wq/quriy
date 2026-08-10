import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:mobile/core/proveedor_idioma.dart';
import 'package:mobile/screens/login_screen.dart';

/// Envuelve LoginScreen con lo que necesita para montarse: el
/// ChangeNotifierProvider de idioma (usa context.watch en el selector ES/EN).
Widget envolverLoginScreen({String? mensajeInicial}) {
  return ChangeNotifierProvider(
    create: (_) => ProveedorDeIdioma(),
    child: MaterialApp(home: LoginScreen(mensajeInicial: mensajeInicial)),
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    // ApiService.guardarToken usa SharedPreferences al iniciar sesión.
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('muestra el título QURIY y los campos de email/contraseña', (
    tester,
  ) async {
    await tester.pumpWidget(envolverLoginScreen());

    expect(find.text('QURIY'), findsOneWidget);
    expect(find.byType(TextField), findsNWidgets(2));
  });

  testWidgets(
    'muestra el mensajeInicial cuando se navega acá por sesión expirada',
    (tester) async {
      await tester.pumpWidget(
        envolverLoginScreen(
          mensajeInicial: 'Tu sesión expiró. Inicia sesión de nuevo.',
        ),
      );

      expect(
        find.text('Tu sesión expiró. Inicia sesión de nuevo.'),
        findsOneWidget,
      );
    },
  );

  testWidgets('no muestra ningún mensaje de error al abrir sin sesión previa', (
    tester,
  ) async {
    await tester.pumpWidget(envolverLoginScreen());

    expect(find.byIcon(Icons.error_outline), findsNothing);
  });

  testWidgets('tocar "Iniciar sesión" muestra el spinner de carga', (
    tester,
  ) async {
    await tester.pumpWidget(envolverLoginScreen());

    await tester.tap(find.byType(ElevatedButton));
    await tester.pump(); // un solo frame: no esperamos a que la red resuelva

    expect(find.byType(CircularProgressIndicator), findsOneWidget);

    // Drena el timer de 800ms del fallback local de ApiService antes de
    // que termine el test — si no, flutter_test lo reporta como un timer
    // pendiente ("_verifyInvariants") aunque la aserción ya haya pasado.
    await tester.pump(const Duration(milliseconds: 900));
  });

  testWidgets('el selector de idioma cambia el subtítulo a inglés', (
    tester,
  ) async {
    await tester.pumpWidget(envolverLoginScreen());

    expect(find.text('Sitios Arqueológicos del Cusco'), findsOneWidget);

    await tester.tap(find.text('🇺🇸 EN'));
    await tester.pump();

    expect(find.text('Archaeological Sites of Cusco'), findsOneWidget);
    expect(find.text('Sitios Arqueológicos del Cusco'), findsNothing);
  });

  testWidgets('muestra el botón "Continuar con Google" junto al de login', (
    tester,
  ) async {
    await tester.pumpWidget(envolverLoginScreen());

    // No se toca (dispararía el plugin nativo de Google Sign-In, que no
    // está disponible en el entorno de tests): solo se verifica que esté.
    expect(find.text('Continuar con Google'), findsOneWidget);
    expect(find.byType(OutlinedButton), findsOneWidget);
    expect(find.byType(ElevatedButton), findsOneWidget);
  });
}
