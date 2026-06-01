import 'package:flutter/material.dart';
import '../models/zona.dart';
import '../services/api_service.dart';

class ZonaDetalleScreen extends StatefulWidget {
  final Zona zona;
  final List<dynamic>? contenidoInicial;

  const ZonaDetalleScreen({super.key, required this.zona, this.contenidoInicial});

  @override
  State<ZonaDetalleScreen> createState() => _ZonaDetalleScreenState();
}

class _ZonaDetalleScreenState extends State<ZonaDetalleScreen> {
  List<dynamic> _contenido = [];
  bool _cargando = true;
  String _idiomaSeleccionado = 'es';

  @override
  void initState() {
    super.initState();
    if (widget.contenidoInicial != null) {
      _contenido = widget.contenidoInicial!;
      _cargando = false;
    } else {
      _cargarContenido();
    }
  }

  Future<void> _cargarContenido() async {
    final datos = await ApiService.obtenerContenidoDeZona(widget.zona.id);
    if (!mounted) return;
    setState(() {
      _contenido = datos;
      _cargando = false;
    });
  }

  List<dynamic> get _contenidoFiltrado =>
      _contenido.where((c) => c['idioma'] == _idiomaSeleccionado).toList();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.zona.nombre),
        backgroundColor: const Color(0xFF8B4513),
        foregroundColor: Colors.white,
        actions: [
          DropdownButton<String>(
            value: _idiomaSeleccionado,
            dropdownColor: const Color(0xFF8B4513),
            style: const TextStyle(color: Colors.white),
            underline: const SizedBox(),
            items: const [
              DropdownMenuItem(value: 'es', child: Text('🇵🇪 ES')),
              DropdownMenuItem(value: 'en', child: Text('🇺🇸 EN')),
            ],
            onChanged: (v) {
              if (v != null) setState(() => _idiomaSeleccionado = v);
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: _cargando
          ? const Center(child: CircularProgressIndicator())
          : CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(widget.zona.nombre,
                      style: Theme.of(context)
                          .textTheme
                          .headlineSmall
                          ?.copyWith(fontWeight: FontWeight.bold)),
                  if (widget.zona.descripcion.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Text(widget.zona.descripcion),
                  ],
                  const Divider(height: 24),
                  Text('Contenido multimedia',
                      style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 8),
                ],
              ),
            ),
          ),
          _contenidoFiltrado.isEmpty
              ? SliverToBoxAdapter(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Text(
                  'No hay contenido en ${_idiomaSeleccionado == "es" ? "español" : "inglés"}',
                  style: const TextStyle(color: Colors.grey),
                ),
              ),
            ),
          )
              : SliverList(
            delegate: SliverChildBuilderDelegate(
                  (context, i) =>
                  _construirTarjetaContenido(_contenidoFiltrado[i]),
              childCount: _contenidoFiltrado.length,
            ),
          ),
        ],
      ),
    );
  }

  Widget _construirTarjetaContenido(Map<String, dynamic> contenido) {
    final tipo = contenido['tipo'] ?? 'texto';
    final titulo = contenido['titulo'] ?? 'Sin título';
    final url = contenido['url_recurso'] ?? '';

    final (icono, color) = switch (tipo) {
      'audio' => (Icons.headphones, Colors.blue),
      'imagen' => (Icons.image, Colors.green),
      'video' => (Icons.play_circle, Colors.red),
      _ => (Icons.article, Colors.orange),
    };

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: color.withOpacity(0.15),
          child: Icon(icono, color: color),
        ),
        title: Text(titulo,
            style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Text(tipo.toUpperCase(),
            style: TextStyle(color: color, fontSize: 12)),
        trailing: url.isNotEmpty
            ? const Icon(Icons.open_in_new, color: Colors.grey)
            : null,
        onTap: url.isNotEmpty
            ? () => ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Abriendo: $url')),
        )
            : null,
      ),
    );
  }
}