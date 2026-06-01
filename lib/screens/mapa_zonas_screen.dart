import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../models/zona.dart';
import '../services/api_service.dart';
import 'zona_detalle_screen.dart';
import 'escaner_qr_screen.dart';


class MapaZonasScreen extends StatefulWidget {
  final int sitioId;
  const MapaZonasScreen({super.key, required this.sitioId});

  @override
  State<MapaZonasScreen> createState() => _MapaZonasScreenState();
}

class _MapaZonasScreenState extends State<MapaZonasScreen> {
  List<Zona> _zonas = [];
  bool _cargando = true;
  String? _mensajeError;

  static const _centroMapa = LatLng(-13.5319, -71.9675); // Cusco

  @override
  void initState() {
    super.initState();
    _cargarZonas();
  }

  Future<void> _cargarZonas() async {
    setState(() {
      _cargando = true;
      _mensajeError = null;
    });
    final datos = await ApiService.obtenerZonasDeSitio(widget.sitioId);
    if (!mounted) return;
    if (datos.isEmpty) {
      setState(() {
        _cargando = false;
        _mensajeError = 'No se pudieron cargar las zonas. Verifica tu conexión.';
      });
      return;
    }
    setState(() {
      _zonas = datos.map((j) => Zona.desdeJson(j)).toList();
      _cargando = false;
    });
  }

  void _navegarADetalle(Zona zona) {
    Navigator.push(context,
        MaterialPageRoute(builder: (_) => ZonaDetalleScreen(zona: zona)));
  }

  void _abrirEscanerQR() {
    Navigator.push(context,
        MaterialPageRoute(builder: (_) => const EscanerQRScreen()));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mapa de Zonas'),
        backgroundColor: const Color(0xFF8B4513),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await ApiService.eliminarToken();
              if (!mounted) return;
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
                onPressed: _cargarZonas,
                child: const Text('Reintentar'),
              ),
            ],
          ),
        ),
      )
          : FlutterMap(
        options: MapOptions(
          initialCenter: _zonas.isNotEmpty
              ? LatLng(_zonas[0].latitud, _zonas[0].longitud)
              : _centroMapa,
          initialZoom: 15,
        ),
        children: [
          TileLayer(
            urlTemplate:
            'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
            userAgentPackageName: 'com.quriy.mobile',
          ),
          MarkerLayer(
            markers: _zonas.map((zona) {
              return Marker(
                point: LatLng(zona.latitud, zona.longitud),
                width: 80,
                height: 80,
                child: GestureDetector(
                  onTap: () => _navegarADetalle(zona),
                  child: Column(
                    children: [
                      const Icon(Icons.location_pin,
                          color: Color(0xFF8B4513), size: 40),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 4, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(4),
                          boxShadow: const [
                            BoxShadow(
                                color: Colors.black26, blurRadius: 2)
                          ],
                        ),
                        child: Text(
                          zona.nombre,
                          style: const TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _abrirEscanerQR,
        backgroundColor: const Color(0xFF8B4513),
        foregroundColor: Colors.white,
        icon: const Icon(Icons.qr_code_scanner),
        label: const Text('Escanear QR'),
      ),
    );
  }
}