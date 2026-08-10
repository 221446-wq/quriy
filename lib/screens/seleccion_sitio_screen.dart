import 'package:flutter/material.dart';
import '../core/banner_modo_demo.dart';
import '../core/manejo_sesion.dart';
import '../models/sitio.dart';
import '../services/api_service.dart';
import 'mapa_zonas_screen.dart';

class SeleccionSitioScreen extends StatefulWidget {
  const SeleccionSitioScreen({super.key});

  @override
  State<SeleccionSitioScreen> createState() => _SeleccionSitioScreenState();
}

class _SeleccionSitioScreenState extends State<SeleccionSitioScreen> {
  List<Sitio> _sitios = [];
  bool _cargando = true;
  bool _esModoDemo = false;
  String? _mensajeError;

  @override
  void initState() {
    super.initState();
    _cargarSitios();
  }

  Future<void> _cargarSitios() async {
    setState(() {
      _cargando = true;
      _mensajeError = null;
    });
    try {
      final respuesta = await ApiService.obtenerSitios();
      if (!mounted) return;
      if (respuesta.datos.isEmpty) {
        setState(() {
          _cargando = false;
          _mensajeError =
              'No se pudieron cargar los sitios. Verifica tu conexión.';
        });
        return;
      }
      setState(() {
        _sitios = respuesta.datos
            .map((json) => Sitio.desdeJson(json as Map<String, dynamic>))
            .toList();
        _esModoDemo = respuesta.esDatosLocales;
        _cargando = false;
      });
    } on ExcepcionSesionExpirada {
      if (!mounted) return;
      await manejarSesionExpirada(context);
    }
  }

  void _navegarAMapaDeZonas(Sitio sitio) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => MapaZonasScreen(sitioId: sitio.id)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Elige un sitio'),
        backgroundColor: const Color(0xFF8B4513),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Cerrar sesión',
            onPressed: () async {
              final confirmado = await confirmarCerrarSesion(context);
              if (!confirmado) return;
              await ApiService.eliminarToken();
              if (!context.mounted) return;
              Navigator.pushReplacementNamed(context, '/');
            },
          ),
        ],
      ),
      body: _cargando
          ? const Center(child: CircularProgressIndicator())
          : _mensajeError != null
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.wifi_off, size: 64, color: Colors.grey),
                    const SizedBox(height: 16),
                    Text(_mensajeError!, textAlign: TextAlign.center),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: _cargarSitios,
                      child: const Text('Reintentar'),
                    ),
                  ],
                ),
              ),
            )
          : Column(
              children: [
                if (_esModoDemo) const BannerModoDemo(),
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _sitios.length,
                    itemBuilder: (_, indice) {
                      final sitio = _sitios[indice];
                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        child: ListTile(
                          leading: const Icon(
                            Icons.account_balance,
                            color: Color(0xFF8B4513),
                          ),
                          title: Text(
                            sitio.nombre,
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          subtitle: sitio.ubicacion.isNotEmpty
                              ? Text(sitio.ubicacion)
                              : null,
                          trailing: const Icon(Icons.chevron_right),
                          onTap: () => _navegarAMapaDeZonas(sitio),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
    );
  }
}
