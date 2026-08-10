import 'package:flutter/material.dart';
import '../screens/login_screen.dart';
import '../services/api_service.dart';

/// Limpia la sesión local y vuelve al login con un aviso, para cuando el
/// backend responde 401 (token expirado o revocado). Se usa un
/// `mensajeInicial` en vez de un SnackBar porque para cuando el usuario
/// lo vería, la pantalla que lo dispara ya no existe (se reemplaza todo
/// el stack de navegación).
Future<void> manejarSesionExpirada(BuildContext context) async {
  await ApiService.eliminarToken();
  if (!context.mounted) return;
  Navigator.of(context).pushAndRemoveUntil(
    MaterialPageRoute(
      builder: (_) => const LoginScreen(
        mensajeInicial: 'Tu sesión expiró. Inicia sesión de nuevo.',
      ),
    ),
    (route) => false,
  );
}

/// Pide confirmación antes de cerrar sesión. Retorna `true` solo si el
/// usuario tocó "Cerrar sesión" en el diálogo.
Future<bool> confirmarCerrarSesion(BuildContext context) async {
  final confirmado = await showDialog<bool>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: const Text('Cerrar sesión'),
      content: const Text('¿Seguro que querés cerrar tu sesión?'),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(dialogContext, false),
          child: const Text('Cancelar'),
        ),
        TextButton(
          onPressed: () => Navigator.pop(dialogContext, true),
          child: const Text('Cerrar sesión'),
        ),
      ],
    ),
  );
  return confirmado ?? false;
}
