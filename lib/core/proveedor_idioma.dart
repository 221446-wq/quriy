import 'package:flutter/foundation.dart';
import 'traducciones.dart';

/// Gestiona el idioma seleccionado por el turista a nivel global.
/// Patrón Observer: notifica a todos los widgets cuando el idioma cambia.
class ProveedorDeIdioma extends ChangeNotifier {
  Traducciones _traducciones = const TraduccionesEspanol();

  Traducciones get traducciones => _traducciones;
  String get codigoIdiomaActual => _traducciones.codigoIdioma;

  /// Cambia el idioma de toda la aplicación y notifica a los widgets suscritos.
  void cambiarIdioma(String codigoIdioma) {
    _traducciones = FabricaDeTraducciones.obtenerPorCodigo(codigoIdioma);
    notifyListeners();
  }
}
