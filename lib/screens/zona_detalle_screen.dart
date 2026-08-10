import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:just_audio/just_audio.dart';
import '../core/banner_modo_demo.dart';
import '../core/estado_visitas_sesion.dart';
import '../core/manejo_sesion.dart';
import '../core/tema_quriy.dart';
import '../models/zona.dart';
import '../models/contenido.dart';
import '../services/api_service.dart';

/// Estados visuales del botón "Marcar como visitada".
enum EstadoVisita { noVisitada, enviando, visitada }

class ZonaDetalleScreen extends StatefulWidget {
  final Zona zona;
  final List<Contenido>? contenidoInicial;

  /// Si `contenidoInicial` vino de datos locales de demo (lo decide quien
  /// ya lo haya cargado, ej. EscanerQRScreen).
  final bool contenidoInicialEsDemo;

  const ZonaDetalleScreen({
    super.key,
    required this.zona,
    this.contenidoInicial,
    this.contenidoInicialEsDemo = false,
  });

  @override
  State<ZonaDetalleScreen> createState() => _ZonaDetalleScreenState();
}

class _ZonaDetalleScreenState extends State<ZonaDetalleScreen> {
  List<Contenido> _contenido = [];
  bool _cargando = true;
  bool _esModoDemo = false;
  String _idiomaSeleccionado = 'es';

  // Reproductor de audio
  final AudioPlayer _audioPlayer = AudioPlayer();
  String? _urlAudioActual;
  bool _reproduciendo = false;

  // Calificación de la visita (1-5, 0 = sin seleccionar aún)
  int _calificacionSeleccionada = 0;

  // Estado del botón "Marcar como visitada"
  late EstadoVisita _estadoVisita;

  // Refresca en segundo plano para reflejar cambios que haga el admin
  // (audios, imágenes, textos nuevos o editados) sin que el turista tenga
  // que salir y volver a entrar a la zona.
  Timer? _timerActualizacion;
  bool _actualizandoEnSegundoPlano = false;
  static const _intervaloActualizacion = Duration(seconds: 12);

  @override
  void initState() {
    super.initState();
    _estadoVisita = EstadoVisitasSesion.estaVisitada(widget.zona.id)
        ? EstadoVisita.visitada
        : EstadoVisita.noVisitada;
    if (widget.contenidoInicial != null) {
      _contenido = widget.contenidoInicial!;
      _esModoDemo = widget.contenidoInicialEsDemo;
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

    _timerActualizacion = Timer.periodic(
      _intervaloActualizacion,
      (_) => _actualizarContenidoEnSegundoPlano(),
    );
  }

  Future<void> _cargarContenido() async {
    try {
      final respuesta = await ApiService.obtenerContenidoDeZona(widget.zona.id);
      if (!mounted) return;
      setState(() {
        _contenido = respuesta.datos
            .map((json) => Contenido.desdeJson(json as Map<String, dynamic>))
            .toList();
        _esModoDemo = respuesta.esDatosLocales;
        _cargando = false;
      });
    } on ExcepcionSesionExpirada {
      if (!mounted) return;
      await manejarSesionExpirada(context);
    }
  }

  /// Igual que [_cargarContenido] pero sin tocar el indicador de carga: si
  /// falla (backend caído, sin red) se descarta el intento y se reintenta
  /// en el próximo ciclo, sin interrumpir el audio que esté sonando ni
  /// mostrar un spinner de pantalla completa.
  Future<void> _actualizarContenidoEnSegundoPlano() async {
    if (_cargando || _actualizandoEnSegundoPlano) return;
    _actualizandoEnSegundoPlano = true;
    try {
      final respuesta = await ApiService.obtenerContenidoDeZona(widget.zona.id);
      if (!mounted) return;
      setState(() {
        _contenido = respuesta.datos
            .map((json) => Contenido.desdeJson(json as Map<String, dynamic>))
            .toList();
        _esModoDemo = respuesta.esDatosLocales;
      });
    } on ExcepcionSesionExpirada {
      if (!mounted) return;
      await manejarSesionExpirada(context);
    } catch (_) {
      // Silencioso a propósito: es un refresco de fondo.
    } finally {
      _actualizandoEnSegundoPlano = false;
    }
  }

  List<Contenido> get _contenidoFiltrado =>
      _contenido.where((c) => c.idioma == _idiomaSeleccionado).toList();

  /// Idiomas con contenido que el selector ES/EN no puede mostrar (el
  /// backend no está limitado a esos dos). Sin esto, ese contenido queda
  /// invisible sin ningún aviso.
  Set<String> get _idiomasNoSoportados => _contenido
      .map((c) => c.idioma)
      .where((idioma) => idioma != 'es' && idioma != 'en')
      .toSet();

  Future<void> _toggleAudio(String url) async {
    try {
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
    } catch (_) {
      if (!mounted) return;
      setState(() => _urlAudioActual = null);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _idiomaSeleccionado == 'es'
                ? 'No se pudo reproducir el audio. Intenta de nuevo.'
                : 'Could not play the audio. Please try again.',
          ),
          backgroundColor: const Color(0xFFDC2626),
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  @override
  void dispose() {
    _timerActualizacion?.cancel();
    _audioPlayer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: PaletaQuriy.fondoGeneral,
      appBar: AppBar(
        title: Text(widget.zona.nombre),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: DropdownButton<String>(
              value: _idiomaSeleccionado,
              dropdownColor: PaletaQuriy.esmeraldaOscura,
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
          : Column(
              children: [
                if (_esModoDemo) const BannerModoDemo(),
                Expanded(
                  child: ListView(
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
                              color: Colors.black.withValues(alpha: 0.07),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Icon(
                                  Icons.location_on,
                                  color: PaletaQuriy.esmeraldaPrincipal,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    widget.zona.nombre,
                                    style: const TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                      color: PaletaQuriy.textoPrincipal,
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
                                  color: Colors.grey[700],
                                  height: 1.5,
                                ),
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
                              color: Colors.black.withValues(alpha: 0.07),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
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
                                color: PaletaQuriy.textoPrincipal,
                              ),
                            ),
                            const SizedBox(height: 8),
                            _construirSelectorEstrellas(),
                            const SizedBox(height: 16),
                            _construirBotonVisitada(),
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
                          color: PaletaQuriy.textoPrincipal,
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
                        ..._contenidoFiltrado.map((c) => _construirTarjeta(c)),

                      // ── Aviso de contenido en otros idiomas ────────
                      if (_idiomasNoSoportados.isNotEmpty) ...[
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFF3CD),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.translate,
                                size: 16,
                                color: Color(0xFF92600B),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  _idiomaSeleccionado == 'es'
                                      ? 'Esta zona también tiene contenido en otros idiomas '
                                            '(${_idiomasNoSoportados.join(', ')}) que esta app '
                                            'todavía no puede mostrar.'
                                      : 'This zone also has content in other languages '
                                            '(${_idiomasNoSoportados.join(', ')}) that this app '
                                            'cannot display yet.',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: Color(0xFF92600B),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
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
            color: Colors.black.withValues(alpha: 0.07),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
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
                  color: Colors.orange.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.article,
                  color: Colors.orange,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  c.titulo.isNotEmpty ? c.titulo : 'Información',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
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
                  placeholder: (_, _) => Container(
                    height: 200,
                    color: Colors.grey[200],
                    child: const Center(child: CircularProgressIndicator()),
                  ),
                  errorWidget: (_, _, _) => Container(
                    height: 200,
                    color: Colors.grey[200],
                    child: const Icon(
                      Icons.broken_image,
                      size: 48,
                      color: Colors.grey,
                    ),
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
                      color: Colors.green.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Icon(
                      Icons.image,
                      color: Colors.green,
                      size: 18,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    c.titulo.isNotEmpty ? c.titulo : 'Imagen',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                  ),
                ],
              ),
              if (c.descripcion.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  c.descripcion,
                  style: TextStyle(color: Colors.grey[600], fontSize: 13),
                ),
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
                  color: Colors.blue.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.headphones,
                  color: Colors.blue,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      c.titulo.isNotEmpty ? c.titulo : 'Audioguía',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                    ),
                    if (c.descripcion.isNotEmpty)
                      Text(
                        c.descripcion,
                        style: TextStyle(color: Colors.grey[600], fontSize: 12),
                      ),
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
                    final duracion = snapDuration.data ?? Duration.zero;
                    final posicion = snapPos.data ?? Duration.zero;
                    final progreso = duracion.inMilliseconds > 0
                        ? posicion.inMilliseconds / duracion.inMilliseconds
                        : 0.0;

                    return Column(
                      children: [
                        LinearProgressIndicator(
                          value: progreso.clamp(0.0, 1.0),
                          backgroundColor: Colors.blue.withValues(alpha: 0.2),
                          color: Colors.blue,
                        ),
                        const SizedBox(height: 4),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              _formatearDuracion(posicion),
                              style: const TextStyle(
                                fontSize: 11,
                                color: Colors.grey,
                              ),
                            ),
                            Text(
                              _formatearDuracion(duracion),
                              style: const TextStyle(
                                fontSize: 11,
                                color: Colors.grey,
                              ),
                            ),
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
              label: Text(
                estaReproduciendo
                    ? (_idiomaSeleccionado == 'es' ? 'Pausar' : 'Pause')
                    : (_idiomaSeleccionado == 'es'
                          ? 'Reproducir audioguía'
                          : 'Play audio guide'),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: estaReproduciendo
                    ? Colors.blue[700]
                    : Colors.blue,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
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
        return Semantics(
          button: true,
          label: _idiomaSeleccionado == 'es'
              ? 'Calificar con $numeroEstrella de 5 estrellas'
              : 'Rate $numeroEstrella out of 5 stars',
          selected: seleccionada,
          child: GestureDetector(
            onTap: () {
              setState(() => _calificacionSeleccionada = numeroEstrella);
            },
            child: Padding(
              padding: const EdgeInsets.only(right: 4),
              child: Icon(
                seleccionada ? Icons.star : Icons.star_border,
                color: PaletaQuriy.doradoAccento,
                size: 32,
              ),
            ),
          ),
        );
      }),
    );
  }

  // ── Botón "Marcar como visitada" ──────────────────────────────
  Widget _construirBotonVisitada() {
    final esEs = _idiomaSeleccionado == 'es';

    switch (_estadoVisita) {
      case EstadoVisita.visitada:
        return Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.green, size: 20),
            const SizedBox(width: 8),
            Text(
              esEs ? 'Visitada' : 'Visited',
              style: const TextStyle(
                color: Colors.green,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        );
      case EstadoVisita.enviando:
        return SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: null,
            child: SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Colors.grey[400],
              ),
            ),
          ),
        );
      case EstadoVisita.noVisitada:
        return SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: _marcarComoVisitada,
            icon: const Icon(Icons.check),
            label: Text(esEs ? 'Marcar como visitada' : 'Mark as visited'),
            style: ElevatedButton.styleFrom(
              backgroundColor: PaletaQuriy.esmeraldaPrincipal,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              padding: const EdgeInsets.symmetric(vertical: 12),
            ),
          ),
        );
    }
  }

  // El backend no expone ningún endpoint para resolver el turista_id
  // real (Turista.id) del usuario logueado, así que usamos el "sub" del
  // JWT (Usuario.id) como sustituto — es mejor que un id fijo compartido
  // por todos, pero NO es necesariamente el turista_id correcto según el
  // schema del backend (Turista.id != Usuario.id en general). Este
  // fallback fijo solo se usa en modo demo local, donde el token no es
  // un JWT real y no hay id que decodificar.
  static const int _turistaIdFallbackDemo = 1;

  Future<void> _marcarComoVisitada() async {
    setState(() => _estadoVisita = EstadoVisita.enviando);
    try {
      final usuarioId =
          await ApiService.obtenerUsuarioId() ?? _turistaIdFallbackDemo;
      await ApiService.registrarVisitaZona(
        turistaId: usuarioId,
        zonaId: widget.zona.id,
        idioma: _idiomaSeleccionado,
        metodoAcceso: 'app',
        calificacion: _calificacionSeleccionada > 0
            ? _calificacionSeleccionada.toDouble()
            : null,
      );
      EstadoVisitasSesion.marcarVisitada(widget.zona.id);
      if (!mounted) return;
      setState(() => _estadoVisita = EstadoVisita.visitada);
    } on ExcepcionSesionExpirada {
      if (!mounted) return;
      await manejarSesionExpirada(context);
    } catch (_) {
      if (!mounted) return;
      setState(() => _estadoVisita = EstadoVisita.noVisitada);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _idiomaSeleccionado == 'es'
                ? 'No se pudo registrar la visita. Intenta de nuevo.'
                : 'Could not register the visit. Please try again.',
          ),
          backgroundColor: const Color(0xFFDC2626),
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  String _formatearDuracion(Duration d) {
    final minutos = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final segundos = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$minutos:$segundos';
  }
}
