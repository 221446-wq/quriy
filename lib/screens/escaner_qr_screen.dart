import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../models/zona.dart';
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
    final codigo = captura.barcodes.firstOrNull?.rawValue;
    if (codigo == null) return;

    setState(() => _procesando = true);

    final zonaId = _extraerIdDeZona(codigo);

    if (zonaId == null) {
      if (!mounted) return;
      _mostrarError('Código QR no válido para este sitio');
      setState(() => _procesando = false);
      return;
    }

    final contenido = await ApiService.obtenerContenidoDeZona(zonaId);

    if (!mounted) return;

    if (contenido.isEmpty) {
      _mostrarError('No se encontró contenido para esta zona');
      setState(() => _procesando = false);
      return;
    }

    final zona = Zona(
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
        builder: (_) =>
            ZonaDetalleScreen(zona: zona, contenidoInicial: contenido),
      ),
    );
  }

  int? _extraerIdDeZona(String codigo) {
    try {
      if (codigo.startsWith('zona:')) return int.parse(codigo.split(':')[1]);
      return int.tryParse(codigo);
    } catch (_) {
      return null;
    }
  }

  void _mostrarError(String mensaje) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
          content: Text(mensaje),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 3)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Escanear QR'),
        backgroundColor: const Color(0xFF8B4513),
        foregroundColor: Colors.white,
      ),
      body: Stack(
        children: [
          MobileScanner(onDetect: _procesarCodigoEscaneado),
          Center(
            child: Container(
              width: 250,
              height: 250,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.white, width: 3),
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
          Positioned(
            bottom: 60,
            left: 0,
            right: 0,
            child: Center(
              child: Container(
                padding:
                const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                decoration: BoxDecoration(
                    color: Colors.black54,
                    borderRadius: BorderRadius.circular(8)),
                child: const Text(
                  'Apunta al código QR de la zona',
                  style: TextStyle(color: Colors.white, fontSize: 16),
                ),
              ),
            ),
          ),
          if (_procesando)
            Container(
              color: Colors.black54,
              child: const Center(
                  child: CircularProgressIndicator(color: Colors.white)),
            ),
        ],
      ),
    );
  }
}