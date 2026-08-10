import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../core/banner_modo_demo.dart';
import '../core/estado_visitas_sesion.dart';
import '../core/manejo_sesion.dart';
import '../core/tema_quriy.dart';
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

  // Refresca en segundo plano para reflejar cambios que haga el admin
  // (coordenadas, nombres, zonas nuevas) sin que el turista tenga que
  // salir y volver a entrar a la pantalla.
  Timer? _timerActualizacion;
  bool _actualizandoEnSegundoPlano = false;
  static const _intervaloActualizacion = Duration(seconds: 12);

  static const _centroMapa = LatLng(-13.5319, -71.9675); // Cusco

  @override
  void initState() {
    super.initState();
    _cargarZonas();
    _timerActualizacion = Timer.periodic(
      _intervaloActualizacion,
      (_) => _actualizarZonasEnSegundoPlano(),
    );
  }

  @override
  void dispose() {
    _timerActualizacion?.cancel();
    super.dispose();
  }

  /// Igual que [_cargarZonas] pero sin tocar los indicadores de carga ni
  /// de error: si falla (backend caído, sin red) simplemente se descarta
  /// el intento y se reintenta en el próximo ciclo, sin interrumpir lo que
  /// el turista esté viendo.
  Future<void> _actualizarZonasEnSegundoPlano() async {
    if (_cargando || _actualizandoEnSegundoPlano) return;
    _actualizandoEnSegundoPlano = true;
    try {
      final respuesta = await ApiService.obtenerZonasDeSitio(widget.sitioId);
      if (!mounted) return;
      if (respuesta.datos.isEmpty) return;
      final zonasActualizadas = respuesta.datos
          .map((j) => Zona.desdeJson(j))
          .toList();
      setState(() {
        _zonas = zonasActualizadas;
        _esModoDemo = respuesta.esDatosLocales;
        _mensajeError = null;
      });
    } on ExcepcionSesionExpirada {
      if (!mounted) return;
      await manejarSesionExpirada(context);
    } catch (_) {
      // Silencioso a propósito: es un refresco de fondo, no una acción
      // que el usuario haya pedido.
    } finally {
      _actualizandoEnSegundoPlano = false;
    }
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

  /// Agrupa zonas que comparten prácticamente la misma coordenada (~1m de
  /// precisión). Varias zonas de un mismo sitio a veces se registran todas
  /// con el mismo punto GPS — sin agrupar, sus marcadores quedarían
  /// perfectamente apilados y solo la última sería visible/tocable.
  List<List<Zona>> _agruparPorCoordenada(List<Zona> zonasConCoordenadas) {
    final grupos = <String, List<Zona>>{};
    for (final zona in zonasConCoordenadas) {
      final clave =
          '${zona.latitud!.toStringAsFixed(5)},${zona.longitud!.toStringAsFixed(5)}';
      grupos.putIfAbsent(clave, () => []).add(zona);
    }
    return grupos.values.toList();
  }

  void _mostrarSelectorDeZonas(List<Zona> grupo) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                child: Row(
                  children: [
                    const Icon(
                      Icons.location_on,
                      color: PaletaQuriy.esmeraldaPrincipal,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '${grupo.length} zonas en este punto',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              ),
              Flexible(
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: grupo.length,
                  itemBuilder: (_, indice) {
                    return _construirItemZonaLista(grupo[indice], cerrarHoja: true);
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _construirMapa(List<Zona> zonasConCoordenadas) {
    final grupos = _agruparPorCoordenada(zonasConCoordenadas);

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
          markers: grupos.map((grupo) {
            final zona = grupo.first;
            final esGrupo = grupo.length > 1;
            final todasVisitadas = grupo.every(
              (z) => EstadoVisitasSesion.estaVisitada(z.id),
            );
            final etiqueta = esGrupo ? '${grupo.length} zonas' : zona.nombre;

            return Marker(
              point: LatLng(zona.latitud!, zona.longitud!),
              width: 90,
              height: 80,
              child: Semantics(
                button: true,
                label: esGrupo
                    ? '${grupo.length} zonas en este punto'
                    : (todasVisitadas ? '${zona.nombre} (visitada)' : zona.nombre),
                child: GestureDetector(
                  onTap: () => esGrupo
                      ? _mostrarSelectorDeZonas(grupo)
                      : _navegarADetalle(zona),
                  child: Column(
                    children: [
                      Stack(
                        clipBehavior: Clip.none,
                        alignment: Alignment.center,
                        children: [
                          Icon(
                            todasVisitadas
                                ? Icons.check_circle
                                : Icons.flag_circle,
                            color: todasVisitadas
                                ? PaletaQuriy.esmeraldaPrincipal
                                : PaletaQuriy.azulMarino,
                            size: 40,
                          ),
                          if (esGrupo)
                            Positioned(
                              top: -2,
                              right: -2,
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 5,
                                  vertical: 1,
                                ),
                                decoration: BoxDecoration(
                                  color: PaletaQuriy.esmeraldaOscura,
                                  borderRadius: BorderRadius.circular(99),
                                  border: Border.all(
                                    color: Colors.white,
                                    width: 1.5,
                                  ),
                                ),
                                child: Text(
                                  '${grupo.length}',
                                  style: const TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ),
                        ],
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
                          etiqueta,
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
        const RichAttributionWidget(
          attributions: [
            TextSourceAttribution('OpenStreetMap contributors'),
          ],
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
            leading: const Icon(
              Icons.location_off,
              color: PaletaQuriy.azulMarino,
            ),
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

  Widget _construirItemZonaLista(Zona zona, {bool cerrarHoja = false}) {
    final visitada = EstadoVisitasSesion.estaVisitada(zona.id);
    return ListTile(
      leading: Icon(
        visitada ? Icons.check_circle : Icons.flag_circle,
        color: visitada
            ? PaletaQuriy.esmeraldaPrincipal
            : PaletaQuriy.azulMarino,
      ),
      title: Text(zona.nombre),
      subtitle: zona.descripcion.isNotEmpty
          ? Text(zona.descripcion, maxLines: 1, overflow: TextOverflow.ellipsis)
          : null,
      trailing: const Icon(Icons.chevron_right),
      onTap: () {
        if (cerrarHoja) Navigator.pop(context);
        _navegarADetalle(zona);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mapa de Zonas'),
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
        backgroundColor: PaletaQuriy.esmeraldaPrincipal,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.qr_code_scanner),
        label: const Text('Escanear QR'),
      ),
    );
  }
}
