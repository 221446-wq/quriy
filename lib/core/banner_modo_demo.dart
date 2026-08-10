import 'package:flutter/material.dart';

/// Aviso visible cuando la pantalla está mostrando el fallback local de
/// demo (`ApiService` no pudo hablar con el backend real) en vez de datos
/// reales del servidor.
class BannerModoDemo extends StatelessWidget {
  const BannerModoDemo({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      color: const Color(0xFFFFF3CD),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: const Row(
        children: [
          Icon(Icons.info_outline, size: 16, color: Color(0xFF92600B)),
          SizedBox(width: 8),
          Expanded(
            child: Text(
              'Sin conexión al servidor: mostrando datos de ejemplo, no reales.',
              style: TextStyle(fontSize: 12, color: Color(0xFF92600B)),
            ),
          ),
        ],
      ),
    );
  }
}
