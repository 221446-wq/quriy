import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:just_audio/just_audio.dart';
import '../models/zona.dart';
import '../models/contenido.dart';
import '../services/api_service.dart';

class ZonaDetalleScreen extends StatefulWidget {
  final Zona zona;
  final List<Contenido>? contenidoInicial;

  const ZonaDetalleScreen({
    super.key,
    required this.zona,
    this.contenidoInicial,
  });

  @override
  State<ZonaDetalleScreen> createState() => _ZonaDetalleScreenState();
}

class _ZonaDetalleScreenState extends State<ZonaDetalleScreen> {
  List<Contenido> _contenido = [];
  bool _cargando = true;
  String _idiomaSeleccionado = 'es';

  // Reproductor de audio
  final AudioPlayer _audioPlayer = AudioPlayer();
  String? _urlAudioActual;
  bool _reproduciendo = false;

  // Calificación de la visita (1-5, 0 = sin seleccionar aún)
  int _calificacionSeleccionada = 0;

  @override
  void initState() {
    super.initState();
    if (widget.contenidoInicial != null) {
      _contenido = widget.contenidoInicial!;
      _cargando = false;
    } else {
      _cargarContenido();
    }

    _audioPlayer.playerStateStream.listen((estado) {
      if (!mounted) return;
      setState(() {
        _reproduciendo = estado.playing;
      });
    });
  }

  Future<void> _cargarContenido() async {
    final datos = await ApiService.obtenerContenidoDeZona(widget.zona.id);
    if (!mounted) return;
    setState(() {
      _contenido = datos
          .map((json) => Contenido.desdeJson(json as Map<String, dynamic>))
          .toList();
      _cargando = false;
    });
  }

  List<Contenido> get _contenidoFiltrado =>
      _contenido.where((c) => c.idioma == _idiomaSeleccionado).toList();

  Future<void> _toggleAudio(String url) async {
    if (_urlAudioActual == url && _reproduciendo) {
      await _audioPlayer.pause();
    } else if (_urlAudioActual == url && !_reproduciendo) {
      await _audioPlayer.play();
    } else {
      await _audioPlayer.stop();
      await _audioPlayer.setUrl(url);
      setState(() => _urlAudioActual = url);
      await _audioPlayer.play();
    }
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F0EB),
      appBar: AppBar(
        title: Text(widget.zona.nombre),
        backgroundColor: const Color(0xFF8B4513),
        foregroundColor: Colors.white,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: DropdownButton<String>(
              value: _idiomaSeleccionado,
              dropdownColor: const Color(0xFF8B4513),
              style: const TextStyle(color: Colors.white, fontSize: 14),
              underline: const SizedBox(),
              items: const [
                DropdownMenuItem(value: 'es', child: Text('🇵🇪 ES')),
                DropdownMenuItem(value: 'en', child: Text('🇺🇸 EN')),
              ],
              onChanged: (v) {
                if (v != null) {
                  _audioPlayer.stop();
                  setState(() {
                    _idiomaSeleccionado = v;
                    _urlAudioActual = null;
                  });
                }
              },
            ),
          ),
        ],
      ),
      body: _cargando
          ? const Center(child: CircularProgressIndicator())
          : ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // ── Encabezado de la zona ──────────────────────
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                    color: Colors.black.withOpacity(0.07),
                    blurRadius: 8,
                    offset: const Offset(0, 2)),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.location_on,
                        color: Color(0xFF8B4513)),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        widget.zona.nombre,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF3E1A00),
                        ),
                      ),
                    ),
                  ],
                ),
                if (widget.zona.descripcion.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  Text(
                    widget.zona.descripcion,
                    style: TextStyle(
                        color: Colors.grey[700], height: 1.5),
                  ),
                ],
              ],
            ),
          ),

          const SizedBox(height: 16),

          // ── Tarjeta "Tu visita" (calificación) ─────────
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                    color: Colors.black.withOpacity(0.07),
                    blurRadius: 8,
                    offset: const Offset(0, 2)),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _idiomaSeleccionado == 'es'
                      ? 'Califica tu visita'
                      : 'Rate your visit',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF3E1A00),
                  ),
                ),
                const SizedBox(height: 8),
                _construirSelectorEstrellas(),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // ── Título sección contenido ───────────────────
          Text(
            _idiomaSeleccionado == 'es'
                ? 'Contenido multimedia'
                : 'Multimedia content',
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Color(0xFF3E1A00),
            ),
          ),
          const SizedBox(height: 10),

          // ── Lista de contenido ─────────────────────────
          if (_contenidoFiltrado.isEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Text(
                  _idiomaSeleccionado == 'es'
                      ? 'No hay contenido en español'
                      : 'No content available in English',
                  style: const TextStyle(color: Colors.grey),
                ),
              ),
            )
          else
            ..._contenidoFiltrado
                .map((c) => _construirTarjeta(c))
                .toList(),
        ],
      ),
    );
  }

  Widget _construirTarjeta(Contenido contenido) {
    final tipo = contenido.tipo;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.07),
              blurRadius: 8,
              offset: const Offset(0, 2)),
        ],
      ),
      child: switch (tipo) {
        'imagen' => _tarjetaImagen(contenido),
        'audio' => _tarjetaAudio(contenido),
        _ => _tarjetaTexto(contenido),
      },
    );
  }

  // ── Tarjeta TEXTO ────────────────────────────────────────────
  Widget _tarjetaTexto(Contenido c) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.orange.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.article, color: Colors.orange, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  c.titulo.isNotEmpty ? c.titulo : 'Información',
                  style: const TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 15),
                ),
              ),
            ],
          ),
          if (c.descripcion.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(
              c.descripcion,
              style: TextStyle(color: Colors.grey[700], height: 1.5),
            ),
          ],
        ],
      ),
    );
  }

  // ── Tarjeta IMAGEN ───────────────────────────────────────────
  Widget _tarjetaImagen(Contenido c) {
    final url = c.urlRecurso;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Imagen
        ClipRRect(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
          child: url.isNotEmpty
              ? CachedNetworkImage(
            imageUrl: url,
            height: 200,
            width: double.infinity,
            fit: BoxFit.cover,
            placeholder: (_, __) => Container(
              height: 200,
              color: Colors.grey[200],
              child: const Center(child: CircularProgressIndicator()),
            ),
            errorWidget: (_, __, ___) => Container(
              height: 200,
              color: Colors.grey[200],
              child: const Icon(Icons.broken_image,
                  size: 48, color: Colors.grey),
            ),
          )
              : Container(
            height: 200,
            color: Colors.grey[200],
            child: const Icon(Icons.image, size: 48, color: Colors.grey),
          ),
        ),
        // Título e info
        Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: Colors.green.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Icon(Icons.image, color: Colors.green, size: 18),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    c.titulo.isNotEmpty ? c.titulo : 'Imagen',
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 15),
                  ),
                ],
              ),
              if (c.descripcion.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(c.descripcion,
                    style: TextStyle(color: Colors.grey[600], fontSize: 13)),
              ],
            ],
          ),
        ),
      ],
    );
  }

  // ── Tarjeta AUDIO ────────────────────────────────────────────
  Widget _tarjetaAudio(Contenido c) {
    final url = c.urlRecurso;
    final esEsteAudio = _urlAudioActual == url;
    final estaReproduciendo = esEsteAudio && _reproduciendo;

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.headphones, color: Colors.blue, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      c.titulo.isNotEmpty ? c.titulo : 'Audioguía',
                      style: const TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 15),
                    ),
                    if (c.descripcion.isNotEmpty)
                      Text(c.descripcion,
                          style: TextStyle(
                              color: Colors.grey[600], fontSize: 12)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          // Barra de progreso si está reproduciendo
          if (esEsteAudio)
            StreamBuilder<Duration?>(
              stream: _audioPlayer.durationStream,
              builder: (context, snapDuration) {
                return StreamBuilder<Duration>(
                  stream: _audioPlayer.positionStream,
                  builder: (context, snapPos) {
                    final duracion =
                        snapDuration.data ?? Duration.zero;
                    final posicion = snapPos.data ?? Duration.zero;
                    final progreso = duracion.inMilliseconds > 0
                        ? posicion.inMilliseconds /
                        duracion.inMilliseconds
                        : 0.0;

                    return Column(
                      children: [
                        LinearProgressIndicator(
                          value: progreso.clamp(0.0, 1.0),
                          backgroundColor: Colors.blue.withOpacity(0.2),
                          color: Colors.blue,
                        ),
                        const SizedBox(height: 4),
                        Row(
                          mainAxisAlignment:
                          MainAxisAlignment.spaceBetween,
                          children: [
                            Text(_formatearDuracion(posicion),
                                style: const TextStyle(
                                    fontSize: 11, color: Colors.grey)),
                            Text(_formatearDuracion(duracion),
                                style: const TextStyle(
                                    fontSize: 11, color: Colors.grey)),
                          ],
                        ),
                        const SizedBox(height: 8),
                      ],
                    );
                  },
                );
              },
            ),
          // Botón reproducir/pausar
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: url.isNotEmpty ? () => _toggleAudio(url) : null,
              icon: Icon(estaReproduciendo ? Icons.pause : Icons.play_arrow),
              label: Text(estaReproduciendo
                  ? (_idiomaSeleccionado == 'es' ? 'Pausar' : 'Pause')
                  : (_idiomaSeleccionado == 'es'
                  ? 'Reproducir audioguía'
                  : 'Play audio guide')),
              style: ElevatedButton.styleFrom(
                backgroundColor:
                estaReproduciendo ? Colors.blue[700] : Colors.blue,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8)),
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Selector de estrellas (1-5) ───────────────────────────────
  Widget _construirSelectorEstrellas() {
    return Row(
      children: List.generate(5, (indice) {
        final numeroEstrella = indice + 1;
        final seleccionada = numeroEstrella <= _calificacionSeleccionada;
        return GestureDetector(
          onTap: () {
            setState(() => _calificacionSeleccionada = numeroEstrella);
          },
          child: Padding(
            padding: const EdgeInsets.only(right: 4),
            child: Icon(
              seleccionada ? Icons.star : Icons.star_border,
              color: const Color(0xFF8B4513),
              size: 32,
            ),
          ),
        );
      }),
    );
  }

  String _formatearDuracion(Duration d) {
    final minutos = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final segundos = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$minutos:$segundos';
  }
}