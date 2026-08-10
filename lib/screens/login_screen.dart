import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/tema_quriy.dart';
import '../core/proveedor_idioma.dart';
import '../services/api_service.dart';
import 'seleccion_sitio_screen.dart';

class LoginScreen extends StatefulWidget {
  /// Mensaje a mostrar apenas se abre (ej. "tu sesión expiró"). No es un
  /// error de este login, sino el motivo por el que volviste acá.
  final String? mensajeInicial;

  const LoginScreen({super.key, this.mensajeInicial});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _controladorEmail = TextEditingController();
  final _controladorPassword = TextEditingController();
  bool _cargando = false;
  bool _cargandoGoogle = false;
  late String? _mensajeError = widget.mensajeInicial;

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
      await ApiService.guardarToken(resultado['datos']['access_token']);
      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const SeleccionSitioScreen()),
      );
    } else {
      setState(() => _mensajeError = resultado['mensaje']);
    }
  }

  /// Botón único para registro e inicio de sesión con Google: el backend
  /// crea la cuenta automáticamente en el primer ingreso con una cuenta de
  /// Google dada, y en los siguientes solo autentica — no hace falta una
  /// pantalla de registro separada.
  Future<void> _continuarConGoogle() async {
    setState(() {
      _cargandoGoogle = true;
      _mensajeError = null;
    });

    final resultado = await ApiService.iniciarSesionConGoogle();

    if (!mounted) return;
    setState(() => _cargandoGoogle = false);

    if (resultado['exito'] == true) {
      await ApiService.guardarToken(resultado['datos']['access_token']);
      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const SeleccionSitioScreen()),
      );
    } else if (resultado['cancelado'] != true) {
      // Si el usuario cerró el selector de cuentas sin elegir ninguna, no
      // es un error real — no mostramos nada y listo.
      setState(() => _mensajeError = resultado['mensaje']);
    }
  }

  @override
  Widget build(BuildContext context) {
    final traducciones = context.watch<ProveedorDeIdioma>().traducciones;

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF064E3B), Color(0xFF059669), Color(0xFF10B981)],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // ── Logo splash ────────────────────────────
                  Container(
                    width: 88,
                    height: 88,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.2),
                          blurRadius: 16,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: ClipOval(
                      child: Image.asset(
                        'assets/images/logoquriy.png',
                        fit: BoxFit.cover,
                        cacheWidth: 176,
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  const Text(
                    'QURIY',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                      letterSpacing: 2,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    traducciones.codigoIdioma == 'es'
                        ? 'Sitios Arqueológicos del Cusco'
                        : 'Archaeological Sites of Cusco',
                    style: const TextStyle(color: Colors.white60, fontSize: 12),
                  ),
                  const SizedBox(height: 36),

                  // ── Tarjeta de login ────────────────────────
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.15),
                          blurRadius: 24,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Selector de idioma
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [_SelectorIdioma()],
                        ),
                        const SizedBox(height: 8),

                        // Campo email
                        Text(
                          traducciones.etiquetaCorreo,
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                            color: Color(0xFF374151),
                          ),
                        ),
                        const SizedBox(height: 4),
                        TextField(
                          controller: _controladorEmail,
                          keyboardType: TextInputType.emailAddress,
                          style: const TextStyle(fontSize: 13),
                          decoration: InputDecoration(
                            hintText: 'marco@quriy.com',
                            hintStyle: const TextStyle(
                              color: PaletaQuriy.textoSutil,
                              fontSize: 12,
                            ),
                            prefixIcon: const Icon(
                              Icons.email_outlined,
                              size: 18,
                              color: PaletaQuriy.textoSecundario,
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 10,
                            ),
                          ),
                        ),
                        const SizedBox(height: 14),

                        // Campo contraseña
                        Text(
                          traducciones.etiquetaContrasena,
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                            color: Color(0xFF374151),
                          ),
                        ),
                        const SizedBox(height: 4),
                        TextField(
                          controller: _controladorPassword,
                          obscureText: true,
                          style: const TextStyle(fontSize: 13),
                          decoration: InputDecoration(
                            hintText: '••••••••',
                            hintStyle: const TextStyle(
                              color: PaletaQuriy.textoSutil,
                              fontSize: 12,
                            ),
                            prefixIcon: const Icon(
                              Icons.lock_outline,
                              size: 18,
                              color: PaletaQuriy.textoSecundario,
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 10,
                            ),
                          ),
                        ),

                        // Error
                        if (_mensajeError != null) ...[
                          const SizedBox(height: 10),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFEE2E2),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.error_outline,
                                  size: 14,
                                  color: Color(0xFFDC2626),
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  _mensajeError!,
                                  style: const TextStyle(
                                    fontSize: 11,
                                    color: Color(0xFFDC2626),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                        const SizedBox(height: 18),

                        // Botón ingresar
                        SizedBox(
                          width: double.infinity,
                          height: 44,
                          child: ElevatedButton(
                            onPressed: (_cargando || _cargandoGoogle)
                                ? null
                                : _iniciarSesion,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: PaletaQuriy.esmeraldaPrincipal,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                            child: _cargando
                                ? const SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator(
                                      color: Colors.white,
                                      strokeWidth: 2,
                                    ),
                                  )
                                : Text(
                                    traducciones.botonIngresar,
                                    style: const TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                          ),
                        ),

                        // Separador "o"
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            const Expanded(child: Divider()),
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                              ),
                              child: Text(
                                traducciones.separadorO,
                                style: TextStyle(
                                  fontSize: 11,
                                  color: Colors.grey[500],
                                ),
                              ),
                            ),
                            const Expanded(child: Divider()),
                          ],
                        ),
                        const SizedBox(height: 16),

                        // Botón continuar con Google
                        SizedBox(
                          width: double.infinity,
                          height: 44,
                          child: OutlinedButton(
                            onPressed: (_cargando || _cargandoGoogle)
                                ? null
                                : _continuarConGoogle,
                            style: OutlinedButton.styleFrom(
                              backgroundColor: Colors.white,
                              side: const BorderSide(
                                color: Color(0xFFD1D5DB),
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                            child: _cargandoGoogle
                                ? const SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator(
                                      color: PaletaQuriy.esmeraldaPrincipal,
                                      strokeWidth: 2,
                                    ),
                                  )
                                : Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      const _LogoGoogle(),
                                      const SizedBox(width: 10),
                                      Text(
                                        traducciones.botonContinuarConGoogle,
                                        style: const TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w600,
                                          color: Color(0xFF374151),
                                        ),
                                      ),
                                    ],
                                  ),
                          ),
                        ),

                        // Hint credenciales locales
                        const SizedBox(height: 12),
                        Center(
                          child: Text(
                            'Demo (sin backend): axel@quiry / axel1',
                            style: TextStyle(
                              fontSize: 9,
                              color: Colors.grey[400],
                            ),
                          ),
                        ),
                      ],
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

/// "G" de Google en un círculo blanco, sin depender de un asset ni de red
/// (el logo multicolor oficial requeriría un asset SVG que este proyecto
/// no tiene). Suficiente para que el botón se identifique junto al texto
/// "Continuar con Google" / "Continue with Google".
class _LogoGoogle extends StatelessWidget {
  const _LogoGoogle();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 18,
      height: 18,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: const Text(
        'G',
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: Color(0xFF4285F4),
          height: 1,
        ),
      ),
    );
  }
}

/// Widget reutilizable para seleccionar idioma.
class _SelectorIdioma extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final proveedorIdioma = context.watch<ProveedorDeIdioma>();

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _PildoraIdioma(
          etiqueta: '🇵🇪 ES',
          seleccionado: proveedorIdioma.codigoIdiomaActual == 'es',
          alPresionar: () => proveedorIdioma.cambiarIdioma('es'),
        ),
        const SizedBox(width: 4),
        _PildoraIdioma(
          etiqueta: '🇺🇸 EN',
          seleccionado: proveedorIdioma.codigoIdiomaActual == 'en',
          alPresionar: () => proveedorIdioma.cambiarIdioma('en'),
        ),
      ],
    );
  }
}

class _PildoraIdioma extends StatelessWidget {
  final String etiqueta;
  final bool seleccionado;
  final VoidCallback alPresionar;

  const _PildoraIdioma({
    required this.etiqueta,
    required this.seleccionado,
    required this.alPresionar,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: alPresionar,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: seleccionado
              ? PaletaQuriy.esmeraldaPrincipal
              : const Color(0xFFF3F4F6),
          borderRadius: BorderRadius.circular(99),
        ),
        child: Text(
          etiqueta,
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w600,
            color: seleccionado ? Colors.white : const Color(0xFF6B7280),
          ),
        ),
      ),
    );
  }
}
