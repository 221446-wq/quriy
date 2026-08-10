# mobile

A new Flutter project.

## Getting Started

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Learn Flutter](https://docs.flutter.dev/get-started/learn-flutter)
- [Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Flutter learning resources](https://docs.flutter.dev/reference/learning-resources)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.

## Configuración de entorno

La app no trae ninguna URL de backend hardcodeada: la URL base se inyecta
en tiempo de compilación con `--dart-define=API_BASE_URL=...`
(ver [`lib/core/config/app_config.dart`](lib/core/config/app_config.dart)).
Si no se pasa nada, cae al valor por defecto del emulador Android
(`http://10.0.2.2:8000`).

### Emulador Android

```
flutter run --dart-define=API_BASE_URL=http://10.0.2.2:8000
```

`10.0.2.2` es la dirección especial con la que el emulador de Android
accede al `localhost` de la máquina host, así que este comando funciona
sin cambios si el backend corre en tu PC en el puerto 8000.

### Dispositivo físico

El celular y el PC deben estar conectados a **la misma red Wi-Fi**. Obtén
la IP LAN de tu PC:

- **Windows:** abre una terminal y ejecuta `ipconfig`, busca
  "Dirección IPv4" en el adaptador de Wi-Fi (ej. `192.168.1.23`).
- **macOS/Linux:** `ifconfig` o `ip addr`.

Luego ejecuta:

```
flutter run --dart-define=API_BASE_URL=http://192.168.X.X:8000
```

reemplazando `192.168.X.X` por la IP obtenida.

También puedes usar las configuraciones ya creadas en
[`.vscode/launch.json`](.vscode/launch.json) — "Quriy (emulador)" y
"Quriy (dispositivo físico)" — actualizando el placeholder `<IP_LAN>` en
esta última con tu IP.

### Build (APK)

```
flutter build apk --dart-define=API_BASE_URL=http://192.168.X.X:8000
```

### Producción

**PENDIENTE** — se documentará en el Hito 9 cuando exista la URL
desplegada.
