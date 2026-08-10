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

### Inicio de sesión con Google

El botón "Continuar con Google" (registro e inicio de sesión) llama a
`POST /auth/google` en el backend, que valida el `id_token` contra los
client IDs listados en su variable de entorno `GOOGLE_CLIENT_ID`. Para que
esto funcione, la app necesita el **mismo client ID web** inyectado como
`GOOGLE_SERVER_CLIENT_ID`:

```
flutter run --dart-define=API_BASE_URL=http://10.0.2.2:8000 --dart-define=GOOGLE_SERVER_CLIENT_ID=<TU_CLIENT_ID>.apps.googleusercontent.com
```

Pasos para obtener los IDs necesarios en
[Google Cloud Console](https://console.cloud.google.com/apis/credentials):

1. Crea (o reutiliza) un **OAuth client ID de tipo "Web application"** —
   este es el que va en `GOOGLE_SERVER_CLIENT_ID` (app) y en
   `GOOGLE_CLIENT_ID` (backend, ver `backend/.env`). No necesita
   redirect URIs para este flujo.
2. Crea un **OAuth client ID de tipo "Android"** con el
   `applicationId` del módulo `android/` (por defecto `com.example.mobile`
   — ver [`android/app/build.gradle.kts`](android/app/build.gradle.kts),
   cámbialo antes de publicar) y el SHA-1 de tu firma de debug/release
   (`cd android && ./gradlew signingReport`). Este client no se pega en
   ningún dart-define: Google lo usa automáticamente al validar la firma
   del paquete.
3. Sin el client Android registrado con el SHA-1 correcto, el selector de
   cuentas falla con `GoogleSignInExceptionCode.clientConfigurationError`
   (ver [`google_sign_in_android`](https://pub.dev/packages/google_sign_in_android#integration)).

Si `GOOGLE_SERVER_CLIENT_ID` no se define, el botón muestra un mensaje de
error claro en vez de intentar abrir el selector de cuentas.

### Build (APK)

```
flutter build apk --dart-define=API_BASE_URL=http://192.168.X.X:8000 --dart-define=GOOGLE_SERVER_CLIENT_ID=<TU_CLIENT_ID>.apps.googleusercontent.com
```

### Producción

**PENDIENTE** — se documentará en el Hito 9 cuando exista la URL
desplegada.
