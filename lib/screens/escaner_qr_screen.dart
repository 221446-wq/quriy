import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:provider/provider.dart';
import '../core/tema_quriy.dart';
import '../core/proveedor_idioma.dart';
import '../models/zona.dart';
import '../models/contenido.dart';
import '../services/api_service.dart';
import 'zona_detalle_screen.dart';

class EscanerQRScreen extends StatefulWidget {
  const EscanerQRScreen({super.key});

  @override
  State<EscanerQRScreen> createState() => _EscanerQRScreenState();
}

class _EscanerQRScreenState extends State<EscanerQRScreen> {
  bool _procesando = false;

  void _procesarCodigoEscaneado(BarcodeCapture captura) async {
    if (_procesando) return;
    final codigoRaw = captura.barcodes.firstOrNull?.rawValue;
    if (codigoRaw == null) return;

    setState(() => _procesando = true);

    final zonaId = _extraerIdDeZona(codigoRaw);
    final traducciones =
        context.read<ProveedorDeIdioma>().traducciones;

    if (zonaId == null) {
      if (!mounted) return;
      _mostrarMensajeError(traducciones.errorQRInvalido);
      setState(() => _procesando = false);
      return;
    }

    final contenidoDeZona =
    await ApiService.obtenerContenidoDeZona(zonaId);

    if (!mounted) return;

    if (contenidoDeZona.isEmpty) {
      _mostrarMensajeError(traducciones.errorZonaSinContenido);
      setState(() => _procesando = false);
      return;
    }

    final zonaEscaneada = Zona(
      id: zonaId,
      nombre: 'Zona $zonaId',
      descripcion: '',
      latitud: 0,
      longitud: 0,
      activa: true,
    );

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => ZonaDetalleScreen(
          zona: zonaEscaneada,
          contenidoInicial: contenidoDeZona
              .map((json) => Contenido.desdeJson(json as Map<String, dynamic>))
              .toList(),
        ),
      ),
    );
  }

  int? _extraerIdDeZona(String codigoQR) {
    try {
      if (codigoQR.startsWith('zona:')) {
        return int.parse(codigoQR.split(':')[1]);
      }
      return int.tryParse(codigoQR);
    } catch (_) {
      return null;
    }
  }

  void _mostrarMensajeError(String mensaje) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(mensaje),
        backgroundColor: const Color(0xFFDC2626),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final traducciones = context.watch<ProveedorDeIdioma>().traducciones;

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: Text(traducciones.tituloEscanerQR),
        backgroundColor: Colors.black,
      ),
      body: Stack(
        children: [
          // Cámara
          MobileScanner(onDetect: _procesarCodigoEscaneado),

          // Marco del visor — fiel al prototipo
          Center(
            child: SizedBox(
              width: 200,
              height: 200,
              child: Stack(
                children: [
                  // Marco exterior con esquinas verdes
                  ..._construirEsquinasDelVisor(),
                  // Línea de escaneo animada
                  Positioned(
                    top: 80,
                    left: 10,
                    right: 10,
                    child: Container(
                      height: 2,
                      decoration: BoxDecoration(
                        color: PaletaQuriy.esmeraldaPrincipal,
                        boxShadow: [
                          BoxShadow(
                            color: PaletaQuriy.esmeraldaPrincipal
                                .withOpacity(0.6),
                            blurRadius: 6,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Instrucción inferior
          Positioned(
            bottom: 60,
            left: 0,
            right: 0,
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 20, vertical: 10),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.6),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  traducciones.instruccionEscanear,
                  style: const TextStyle(
                      color: Colors.white, fontSize: 13),
                ),
              ),
            ),
          ),

          // Overlay de carga
          if (_procesando)
            Container(
              color: Colors.black.withOpacity(0.6),
              child: const Center(
                child: CircularProgressIndicator(
                    color: PaletaQuriy.esmeraldaPrincipal),
              ),
            ),
        ],
      ),
    );
  }

  /// Construye las 4 esquinas verdes del visor QR, igual al prototipo.
  List<Widget> _construirEsquinasDelVisor() {
    const tamanioEsquina = 20.0;
    const grosorBorde    = 3.0;
    const colorEsquina   = PaletaQuriy.esmeraldaPrincipal;

    return [
      // Superior izquierda
      Positioned(
        top: 0, left: 0,
        child: _EsquinaVisor(
          bordeTop: grosorBorde, bordeLeft: grosorBorde,
          radioTopLeft: 4, tamanio: tamanioEsquina,
          color: colorEsquina,
        ),
      ),
      // Superior derecha
      Positioned(
        top: 0, right: 0,
        child: _EsquinaVisor(
          bordeTop: grosorBorde, bordeRight: grosorBorde,
          radioTopRight: 4, tamanio: tamanioEsquina,
          color: colorEsquina,
        ),
      ),
      // Inferior izquierda
      Positioned(
        bottom: 0, left: 0,
        child: _EsquinaVisor(
          bordeBottom: grosorBorde, bordeLeft: grosorBorde,
          radioBottomLeft: 4, tamanio: tamanioEsquina,
          color: colorEsquina,
        ),
      ),
      // Inferior derecha
      Positioned(
        bottom: 0, right: 0,
        child: _EsquinaVisor(
          bordeBottom: grosorBorde, bordeRight: grosorBorde,
          radioBottomRight: 4, tamanio: tamanioEsquina,
          color: colorEsquina,
        ),
      ),
    ];
  }
}

/// Widget para cada esquina del visor QR.
class _EsquinaVisor extends StatelessWidget {
  final double tamanio;
  final Color color;
  final double bordeTop, bordeBottom, bordeLeft, bordeRight;
  final double radioTopLeft, radioTopRight, radioBottomLeft, radioBottomRight;

  const _EsquinaVisor({
    required this.tamanio,
    required this.color,
    this.bordeTop = 0, this.bordeBottom = 0,
    this.bordeLeft = 0, this.bordeRight = 0,
    this.radioTopLeft = 0, this.radioTopRight = 0,
    this.radioBottomLeft = 0, this.radioBottomRight = 0,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: tamanio,
      height: tamanio,
      decoration: BoxDecoration(
        border: Border(
          top:    BorderSide(color: color, width: bordeTop),
          bottom: BorderSide(color: color, width: bordeBottom),
          left:   BorderSide(color: color, width: bordeLeft),
          right:  BorderSide(color: color, width: bordeRight),
        ),
        borderRadius: BorderRadius.only(
          topLeft:     Radius.circular(radioTopLeft),
          topRight:    Radius.circular(radioTopRight),
          bottomLeft:  Radius.circular(radioBottomLeft),
          bottomRight: Radius.circular(radioBottomRight),
        ),
      ),
    );
  }
}