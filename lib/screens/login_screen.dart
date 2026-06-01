import 'package:flutter/material.dart';
import '../services/api_service.dart';
import 'mapa_zonas_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _controladorEmail = TextEditingController();
  final _controladorPassword = TextEditingController();
  bool _cargando = false;
  String? _mensajeError;

  Future<void> _iniciarSesion() async {
    setState(() {
      _cargando = true;
      _mensajeError = null;
    });

    final resultado = await ApiService.iniciarSesion(
      _controladorEmail.text.trim(),
      _controladorPassword.text,
    );

    if (!mounted) return;
    setState(() => _cargando = false);

    if (resultado['exito'] == true) {
      final token = resultado['datos']['access_token'];
      await ApiService.guardarToken(token);
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => const MapaZonasScreen(sitioId: 1),
        ),
      );
    } else {
      setState(() => _mensajeError = resultado['mensaje']);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF8B4513), Color(0xFF3E1A00)],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.temple_buddhist,
                      size: 80, color: Colors.white),
                  const SizedBox(height: 12),
                  const Text(
                    'Quriy',
                    style: TextStyle(
                      fontSize: 40,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      letterSpacing: 4,
                    ),
                  ),
                  const Text(
                    'Sitios Arqueológicos del Cusco',
                    style: TextStyle(color: Colors.white70, fontSize: 14),
                  ),
                  const SizedBox(height: 48),
                  Card(
                    elevation: 8,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16)),
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        children: [
                          TextField(
                            controller: _controladorEmail,
                            keyboardType: TextInputType.emailAddress,
                            decoration: const InputDecoration(
                              labelText: 'Correo electrónico',
                              prefixIcon: Icon(Icons.email),
                              border: OutlineInputBorder(),
                            ),
                          ),
                          const SizedBox(height: 16),
                          TextField(
                            controller: _controladorPassword,
                            obscureText: true,
                            decoration: const InputDecoration(
                              labelText: 'Contraseña',
                              prefixIcon: Icon(Icons.lock),
                              border: OutlineInputBorder(),
                            ),
                          ),
                          if (_mensajeError != null) ...[
                            const SizedBox(height: 12),
                            Text(_mensajeError!,
                                style: const TextStyle(color: Colors.red)),
                          ],
                          const SizedBox(height: 24),
                          SizedBox(
                            width: double.infinity,
                            height: 50,
                            child: ElevatedButton(
                              onPressed: _cargando ? null : _iniciarSesion,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF8B4513),
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8)),
                              ),
                              child: _cargando
                                  ? const CircularProgressIndicator(
                                  color: Colors.white)
                                  : const Text('Ingresar',
                                  style: TextStyle(fontSize: 16)),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _controladorEmail.dispose();
    _controladorPassword.dispose();
    super.dispose();
  }
}