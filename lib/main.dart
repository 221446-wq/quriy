import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'core/config/app_config.dart';
import 'core/tema_quriy.dart';
import 'core/proveedor_idioma.dart';
import 'screens/login_screen.dart';
// funcional
void main() {
  AppConfig.validar();
  runApp(
    ChangeNotifierProvider(
      create: (_) => ProveedorDeIdioma(),
      child: const AplicacionQuriy(),
    ),
  );
}

class AplicacionQuriy extends StatelessWidget {
  const AplicacionQuriy({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'QURIY',
      debugShowCheckedModeBanner: false,
      theme: TemaQuriy.construir(),
      home: const LoginScreen(),
    );
  }
}