# Quriy

Sistema Integral de Autoguiado Multimedia y Gestión Turística para sitios arqueológicos de Cusco (Qorikancha, Plaza de Armas, Piedra de los 12 Ángulos, Qenqo, Cristo Blanco, entre otros).

Los turistas escanean un código QR en cada zona de un sitio arqueológico y acceden a contenido multimedia (texto, audio, imágenes) en español e inglés. Los administradores gestionan sitios, zonas, contenido y códigos QR desde un panel con estadísticas de uso.

## Demo pública

- API: https://quriy.onrender.com
- Documentación interactiva (Swagger): https://quriy.onrender.com/docs

## Estructura del repositorio

```
quriy/
├── backend/   API REST (FastAPI + SQLAlchemy + SQLite)
└── mobile/    App móvil (Flutter) — en fase inicial
```

## Backend

### Stack

- **FastAPI** — framework web/API
- **SQLAlchemy** — ORM
- **SQLite** — base de datos
- **python-jose** + **passlib** — autenticación JWT
- **Cloudinary** — almacenamiento permanente de imágenes subidas
- **gTTS** (Google Text-to-Speech) — generación de audioguías con IA
- **deep-translator** — traducción automática ES → EN
- **pytest** — pruebas automatizadas

### Funcionalidades principales

- Autenticación con JWT y roles (`admin` / `turista`)
- CRUD de sitios arqueológicos y sus zonas
- Generación y consulta de códigos QR por zona (idempotente)
- Gestión de contenido multimedia por zona e idioma (texto, audio, imagen)
- Subida de archivos (imágenes a Cloudinary, audio a almacenamiento local)
- Generación automática de audioguías con IA (texto → audio ES, traducción a EN, audio EN)
- Registro de visitas por zona y valoraciones de recorridos
- Panel de estadísticas: sitios más visitados, escaneos por día/mes, idioma más usado, calificación promedio

### Requisitos

- Python 3.11 (ver `backend/.python-version`)

### Instalación y ejecución local

```bash
cd backend
python -m venv venv
venv\Scripts\activate        # Windows
# source venv/bin/activate   # Linux/macOS

pip install -r requirements.txt

uvicorn app.main:app --reload
```

La API queda disponible en `http://localhost:8000` y la documentación interactiva en `http://localhost:8000/docs`.

Al iniciar, el servidor crea las tablas automáticamente y ejecuta el seed (`seed.py`) si la base de datos está vacía, poblándola con sitios, zonas, usuarios y contenido de ejemplo. Ver `backend/RESEED.MD` para más detalle sobre cómo repoblar los datos.

### Variables de entorno

Configurables en `backend/.env` (opcional en desarrollo local, con valores por defecto):

| Variable | Descripción | Por defecto |
|---|---|---|
| `SECRET_KEY` | Clave para firmar los tokens JWT | `quriy-secret-key-cusco-2024` |
| `CORS_ORIGINS` | Orígenes permitidos por CORS, separados por coma | `http://localhost:5173,http://localhost:3000,https://quriy.vercel.app` |
| `CLOUDINARY_CLOUD_NAME` | Cloud name de Cloudinary | — |
| `CLOUDINARY_API_KEY` | API key de Cloudinary | — |
| `CLOUDINARY_API_SECRET` | API secret de Cloudinary | — |

Si las tres variables de Cloudinary no están configuradas, la subida de imágenes cae automáticamente a almacenamiento local en `backend/app/static`.

### Usuarios de prueba (creados por el seed)

| Email | Password | Rol |
|---|---|---|
| `admin@quriy.com` | `admin123` | admin |
| `turista@quriy.com` | `turista123` | turista |
| `tourist@quriy.com` | `tourist123` | turista |

### Endpoints principales

| Recurso | Rutas |
|---|---|
| Autenticación | `POST /auth/login`, `POST /auth/logout`, `GET /auth/me` |
| Sitios | `GET/POST /sitios`, `PUT/DELETE /sitios/{id}` |
| Zonas | `GET/POST /sitios/{id}/zonas`, `PUT/DELETE /zonas/{id}` |
| Códigos QR | `POST /zonas/{id}/qr`, `GET /zonas/{id}/qr`, `GET /qr/todos` |
| Contenido | `GET /zonas/{id}/contenido`, `POST /zonas/{id}/contenido`, `PUT/DELETE /contenido/{id}`, `GET /contenido/audios` |
| Subida de archivos | `POST /contenido/upload` |
| IA (audio y traducción) | `POST /contenido/generar-audio`, `POST /contenido/traducir`, `POST /zonas/{id}/generar-audioguia-completa` |
| Recorridos | `POST /recorridos`, `PUT /recorridos/{id}` |
| Visitas y valoraciones | `POST /visitas-zona`, `GET /valoraciones` |
| Estadísticas | `GET /estadisticas/resumen`, `/sitios-mas-visitados`, `/escaneos-por-dia`, `/escaneos-por-mes`, `/idioma-mas-usado`, `/calificacion-promedio` |

El detalle completo de request/response de cada endpoint está disponible en `/docs`.

### Tests

```bash
cd backend
pytest
```

Incluye pruebas de endpoints (`test_endpoints.py`), modelos (`test_modelos.py`) y flujos de integración completos (`test_integracion.py`).

### Despliegue

El backend está desplegado en [Render](https://render.com) usando `backend/render.yaml` y `backend/Procfile` (`uvicorn app.main:app --host 0.0.0.0 --port $PORT`).

## Mobile

App cliente en **Flutter** ubicada en `mobile/`, en fase inicial de desarrollo (aún sobre el proyecto base generado por Flutter). Pensada para que los turistas escaneen los códigos QR y accedan a las audioguías de cada zona.

```bash
cd mobile
flutter pub get
flutter run
```

## Licencia

Proyecto académico/institucional para la gestión turística de sitios arqueológicos de Cusco.
