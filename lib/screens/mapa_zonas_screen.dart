import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../core/banner_modo_demo.dart';
import '../core/estado_visitas_sesion.dart';
import '../core/manejo_sesion.dart';
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
  bool _esModoDemo = false;
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
    try {
      final respuesta = await ApiService.obtenerZonasDeSitio(widget.sitioId);
      if (!mounted) return;
      if (respuesta.datos.isEmpty) {
        setState(() {
          _cargando = false;
          _mensajeError =
              'No se pudieron cargar las zonas. Verifica tu conexión.';
        });
        return;
      }
      setState(() {
        _zonas = respuesta.datos.map((j) => Zona.desdeJson(j)).toList();
        _esModoDemo = respuesta.esDatosLocales;
        _cargando = false;
      });
    } on ExcepcionSesionExpirada {
      if (!mounted) return;
      await manejarSesionExpirada(context);
    }
  }

  Future<void> _navegarADetalle(Zona zona) async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => ZonaDetalleScreen(zona: zona)),
    );
    // Al volver, refresca por si se marcó la zona como visitada allá.
    if (!mounted) return;
    setState(() {});
  }

  void _abrirEscanerQR() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const EscanerQRScreen()),
    );
  }

  /// Arma el cuerpo principal una vez que las zonas cargaron sin error.
  ///
  /// Las zonas sin coordenadas nunca se descartan: si al menos una zona
  /// tiene ubicación se muestran en un panel colapsable bajo el mapa; si
  /// ninguna la tiene, reemplazan al mapa como lista para no dejar un
  /// mapa en blanco.
  Widget _construirCuerpoMapa() {
    final zonasConCoordenadas = _zonas
        .where((zona) => zona.tieneCoordenadas)
        .toList();
    final zonasSinCoordenadas = _zonas
        .where((zona) => !zona.tieneCoordenadas)
        .toList();

    if (zonasConCoordenadas.isEmpty) {
      return _construirListaSinMapa(zonasSinCoordenadas);
    }

    return Column(
      children: [
        Expanded(child: _construirMapa(zonasConCoordenadas)),
        if (zonasSinCoordenadas.isNotEmpty)
          _construirPanelSinCoordenadas(zonasSinCoordenadas),
      ],
    );
  }

  Widget _construirMapa(List<Zona> zonasConCoordenadas) {
    return FlutterMap(
      options: MapOptions(
        initialCenter: zonasConCoordenadas.isNotEmpty
            ? LatLng(
                zonasConCoordenadas[0].latitud!,
                zonasConCoordenadas[0].longitud!,
              )
            : _centroMapa,
        initialZoom: 15,
      ),
      children: [
        TileLayer(
          urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
          userAgentPackageName: 'com.quriy.mobile',
        ),
        MarkerLayer(
          markers: zonasConCoordenadas.map((zona) {
            final visitada = EstadoVisitasSesion.estaVisitada(zona.id);
            return Marker(
              point: LatLng(zona.latitud!, zona.longitud!),
              width: 80,
              height: 80,
              child: Semantics(
                button: true,
                label: visitada ? '${zona.nombre} (visitada)' : zona.nombre,
                child: GestureDetector(
                  onTap: () => _navegarADetalle(zona),
                  child: Column(
                    children: [
                      Icon(
                        visitada ? Icons.check_circle : Icons.location_pin,
                        color: visitada
                            ? Colors.green
                            : const Color(0xFF8B4513),
                        size: 40,
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 4,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(4),
                          boxShadow: const [
                            BoxShadow(color: Colors.black26, blurRadius: 2),
                          ],
                        ),
                        child: Text(
                          zona.nombre,
                          style: const TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  /// Panel colapsable bajo el mapa con las zonas que no tienen coordenadas.
  Widget _construirPanelSinCoordenadas(List<Zona> zonas) {
    return SafeArea(
      top: false,
      child: Container(
        constraints: const BoxConstraints(maxHeight: 220),
        decoration: const BoxDecoration(
          color: Colors.white,
          boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 4)],
        ),
        child: Theme(
          data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
          child: ExpansionTile(
            leading: const Icon(Icons.location_off, color: Color(0xFF8B4513)),
            title: Text('Zonas sin ubicación en el mapa (${zonas.length})'),
            children: [
              ConstrainedBox(
                constraints: const BoxConstraints(maxHeight: 160),
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: zonas.length,
                  itemBuilder: (_, indice) =>
                      _construirItemZonaLista(zonas[indice]),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Reemplaza el mapa cuando ninguna zona tiene coordenadas: lista simple
  /// en vez de un mapa vacío, con las zonas igual de accesibles.
  Widget _construirListaSinMapa(List<Zona> zonas) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: const [
              Icon(Icons.map_outlined, color: Colors.grey),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Ninguna zona tiene ubicación registrada todavía. '
                  'Mostrando la lista de zonas disponibles.',
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: RefreshIndicator(
            onRefresh: _cargarZonas,
            child: ListView.builder(
              itemCount: zonas.length,
              itemBuilder: (_, indice) =>
                  _construirItemZonaLista(zonas[indice]),
            ),
          ),
        ),
      ],
    );
  }

  Widget _construirItemZonaLista(Zona zona) {
    final visitada = EstadoVisitasSesion.estaVisitada(zona.id);
    return ListTile(
      leading: Icon(
        visitada ? Icons.check_circle : Icons.location_pin,
        color: visitada ? Colors.green : const Color(0xFF8B4513),
      ),
      title: Text(zona.nombre),
      subtitle: zona.descripcion.isNotEmpty
          ? Text(zona.descripcion, maxLines: 1, overflow: TextOverflow.ellipsis)
          : null,
      trailing: const Icon(Icons.chevron_right),
      onTap: () => _navegarADetalle(zona),
    );
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
            icon: const Icon(Icons.refresh),
            tooltip: 'Actualizar zonas',
            onPressed: _cargando ? null : _cargarZonas,
          ),
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
                      onPressed: _cargarZonas,
                      child: const Text('Reintentar'),
                    ),
                  ],
                ),
              ),
            )
          : Column(
              children: [
                if (_esModoDemo) const BannerModoDemo(),
                Expanded(child: _construirCuerpoMapa()),
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
