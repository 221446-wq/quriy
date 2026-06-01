import 'package:flutter/material.dart';

/// Paleta oficial de Quriy extraída del prototipo de diseño.
/// Centraliza todos los colores para mantener consistencia visual.
abstract class PaletaQuriy {
  static const Color esmeraldaPrincipal = Color(0xFF10B981);
  static const Color esmeraldaOscura    = Color(0xFF065F46);
  static const Color esmeraldaMedio     = Color(0xFF059669);
  static const Color esmeraldaClara     = Color(0xFFD1FAE5);
  static const Color doradoAccento      = Color(0xFFD97706);
  static const Color doradoClaro        = Color(0xFFFEF3C7);
  static const Color fondoGeneral       = Color(0xFFF9FAFB);
  static const Color superficieBlanca   = Color(0xFFFFFFFF);
  static const Color textoPrincipal     = Color(0xFF111827);
  static const Color textoSecundario    = Color(0xFF6B7280);
  static const Color textoSutil         = Color(0xFF9CA3AF);
  static const Color bordeGeneral       = Color(0xFFE5E7EB);
}

/// Tema visual centralizado de la aplicación Quriy.
class TemaQuriy {
  TemaQuriy._(); // Previene instanciación — patrón Utility Class

  static ThemeData construir() {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: PaletaQuriy.esmeraldaPrincipal,
        brightness: Brightness.light,
      ),
      scaffoldBackgroundColor: PaletaQuriy.fondoGeneral,
      appBarTheme: const AppBarTheme(
        backgroundColor: PaletaQuriy.esmeraldaOscura,
        foregroundColor: PaletaQuriy.superficieBlanca,
        elevation: 0,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: PaletaQuriy.esmeraldaPrincipal,
          foregroundColor: PaletaQuriy.superficieBlanca,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: PaletaQuriy.bordeGeneral),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(
              color: PaletaQuriy.esmeraldaPrincipal, width: 1.5),
        ),
        labelStyle: const TextStyle(color: PaletaQuriy.textoSecundario),
      ),
    );
  }
}