# Quriy — Sistema Integral de Autoguiado Multimedia y Gestión Turística

> Plataforma multicliente para recorridos autoguiados en sitios arqueológicos del Cusco.

---

## Descripción

Quriy permite a los turistas recorrer sitios arqueológicos del Cusco de forma autoguiada, accediendo a contenido histórico y audioguías en español e inglés mediante el escaneo de códigos QR. A su vez, los administradores pueden gestionar sitios, zonas y contenido multimedia desde una plataforma web.

La solución está conformada por tres capas principales:

* **App móvil** para el turista desarrollada con Flutter.
* **Panel web** para el administrador desarrollado con React.
* **API REST centralizada** desarrollada con FastAPI, que sirve a ambos clientes.

---

## Integrantes

| Nombre                             | Rol                         |
| ---------------------------------- | --------------------------- |
| Diaz Misme, Pamela                 | Coordinadora · Frontend Web |
| Llancaya Tapia, Aracely            | Backend Developer           |
| Vargas Zegarra, Marco Antonio Axel | Mobile Developer (Flutter)  |

**Asignatura:** Desarrollo de Software II
**Docente:** Hans Harley Ccacyahuillca Bejar
**Universidad:** UNSAAC — Escuela Profesional de Ingeniería de Informática y de Sistemas
**Año:** 2026

---

## Tecnologías

| Capa         | Tecnología                                     |
| ------------ | ---------------------------------------------- |
| Backend      | FastAPI, SQLite, SQLAlchemy, JWT               |
| Frontend Web | React, Vite, Axios, React Router DOM           |
| Mobile       | Flutter, mobile_scanner, flutter_map, provider |

---

## Funcionalidades MVP

### Turista — App Móvil

* Explorar un mapa interactivo de sitios arqueológicos.
* Visualizar los sitios turísticos disponibles.
* Consultar información de cada sitio arqueológico.
* Consultar las diferentes zonas de cada sitio.
* Escanear códigos QR asociados a las zonas.
* Visualizar información histórica de cada zona.
* Reproducir audioguías en español e inglés.
* Visualizar imágenes relacionadas con las zonas.
* Registrar las zonas visitadas.
* Calificar y valorar el recorrido.
* Contar con contenido básico disponible sin conexión.

### Administrador — Panel Web

* Login con autenticación JWT.
* Gestionar sitios arqueológicos.
* Registrar nuevos sitios arqueológicos.
* Editar información de sitios.
* Gestionar las zonas correspondientes a cada sitio.
* Registrar nuevas zonas.
* Editar información de las zonas.
* Gestionar contenido multimedia.
* Subir audios e imágenes.
* Generar códigos QR funcionales para cada zona.
* Descargar códigos QR.
* Consultar estadísticas de visitas.

---

## Arquitectura del Sistema

Quriy utiliza una arquitectura de tres capas principales:

```text
                    ┌──────────────────────┐
                    │       TURISTA        │
                    │    App Flutter       │
                    └──────────┬───────────┘
                               │
                               │ HTTP / JSON
                               │ JWT
                               ▼
                    ┌──────────────────────┐
                    │       BACKEND        │
                    │   FastAPI + SQLite   │
                    │     SQLAlchemy       │
                    └──────────┬───────────┘
                               │
                               │ HTTP / JSON
                               │ JWT
                               ▼
                    ┌──────────────────────┐
                    │    ADMINISTRADOR     │
                    │    Panel React       │
                    └──────────────────────┘
```

La API REST centralizada permite que el panel web y la aplicación móvil se comuniquen con el backend mediante solicitudes HTTP y respuestas en formato JSON.

---

## Modelo de Datos

El sistema está modelado mediante las siguientes entidades principales:

```text
Usuario
├── Turista
└── Administrador

SitioArqueologico
└── Zona
    ├── Contenido
    └── CodigoQR

Recorrido
└── VisitaZona
```

### Entidades principales

* `Usuario`
* `Turista`
* `Administrador`
* `SitioArqueologico`
* `Zona`
* `Contenido`
* `CodigoQR`
* `Recorrido`
* `VisitaZona`

---

## Estructura del Repositorio

```text
quriy/
│
├── backend/
│   ├── app/
│   │   ├── models/
│   │   ├── routes/
│   │   ├── schemas/
│   │   ├── static/
│   │   ├── auth.py
│   │   ├── database.py
│   │   └── main.py
│   │
│   ├── tests/
│   ├── seed.py
│   └── requirements.txt
│
├── frontend-web/
│   └── src/
│       ├── components/
│       ├── pages/
│       └── services/
│
└── mobile/
    └── lib/
        ├── models/
        ├── services/
        └── screens/
```

---

# Cómo ejecutar el proyecto localmente

## 1. Backend

Ingresar a la carpeta del backend:

```bash
cd backend
```

Instalar las dependencias:

```bash
pip install -r requirements.txt
```

Poblar la base de datos con datos de prueba:

```bash
python seed.py
```

Ejecutar el servidor:

```bash
uvicorn app.main:app --reload
```

La API estará disponible en:

```text
http://localhost:8000
```

### Documentación interactiva de FastAPI

```text
http://localhost:8000/docs
```

---

## 2. Frontend Web

Desde la raíz del proyecto:

```bash
cd frontend-web
```

Instalar las dependencias:

```bash
npm install
```

Ejecutar el proyecto:

```bash
npm run dev
```

El panel web estará disponible en:

```text
http://localhost:5173
```

---

## 3. Mobile

Desde la raíz del proyecto:

```bash
cd mobile
```

Instalar las dependencias:

```bash
flutter pub get
```

Ejecutar la aplicación:

```bash
flutter run
```

---

# API Pública

La API de Quriy se encuentra desplegada en Render:

```text
https://quriy.onrender.com
```

### Documentación interactiva

```text
https://quriy.onrender.com/docs
```

---

## Autenticación

El backend utiliza autenticación mediante **JWT (JSON Web Token)**.

El flujo general de autenticación es:

```text
Usuario
   │
   ▼
POST /auth/login
   │
   ▼
Access Token (JWT)
   │
   ▼
Frontend
   │
   ▼
Authorization: Bearer <token>
   │
   ▼
API protegida
```

El panel web almacena el token de autenticación y lo utiliza para realizar solicitudes a los endpoints protegidos de la API.

---

# Estado del Proyecto

## Backend

Implementado con:

* FastAPI.
* SQLAlchemy.
* SQLite.
* Autenticación JWT.
* Gestión de usuarios.
* Gestión de sitios arqueológicos.
* Gestión de zonas.
* Gestión de contenido.
* Códigos QR.
* Recorridos y visitas.
* Estadísticas.
* Pruebas automatizadas.

## Frontend Web

Implementado con:

* React.
* Vite.
* Axios.
* React Router.
* Autenticación mediante JWT.
* Gestión de sitios arqueológicos.
* Gestión de zonas.
* Generación de códigos QR.
* Pruebas con Vitest y Testing Library.

## Mobile

Aplicación desarrollada con Flutter para el usuario turista.

El proyecto móvil contempla funcionalidades como:

* Lectura de códigos QR.
* Mapas.
* Visualización de sitios arqueológicos.
* Visualización de zonas.
* Contenido multimedia.
* Audioguías.
* Recorridos turísticos.
* Registro de visitas.

---

# Flujo General del Sistema

## Flujo del Turista

```text
                 ┌───────────────┐
                 │    Turista    │
                 └───────┬───────┘
                         │
                         ▼
                ┌─────────────────┐
                │ Iniciar sesión  │
                └────────┬────────┘
                         │
                         ▼
                ┌─────────────────┐
                │ Seleccionar     │
                │ idioma          │
                │ Español/Inglés  │
                └────────┬────────┘
                         │
                         ▼
                ┌─────────────────┐
                │ Mapa turístico  │
                └────────┬────────┘
                         │
                         ▼
                ┌─────────────────┐
                │ Seleccionar     │
                │ sitio            │
                └────────┬────────┘
                         │
                         ▼
                ┌─────────────────┐
                │ Seleccionar     │
                │ zona             │
                └────────┬────────┘
                         │
                         ▼
                ┌─────────────────┐
                │ Escanear QR     │
                └────────┬────────┘
                         │
                         ▼
                ┌─────────────────┐
                │ Información     │
                │ histórica       │
                └────────┬────────┘
                         │
                         ▼
                ┌─────────────────┐
                │ Audioguía       │
                │ + imágenes      │
                └────────┬────────┘
                         │
                         ▼
                ┌─────────────────┐
                │ Marcar como     │
                │ visitado        │
                └────────┬────────┘
                         │
                         ▼
                ┌─────────────────┐
                │ Calificar       │
                │ experiencia     │
                └─────────────────┘
```

---

## Flujo del Administrador

```text
                 ┌────────────────┐
                 │ Administrador   │
                 └───────┬────────┘
                         │
                         ▼
                ┌─────────────────┐
                │ Login            │
                └────────┬────────┘
                         │
                         ▼
                ┌─────────────────┐
                │ Panel principal │
                └────────┬────────┘
                         │
              ┌──────────┴──────────┐
              │                     │
              ▼                     ▼
       ┌───────────────┐     ┌───────────────┐
       │ Sitios        │     │ Estadísticas  │
       └───────┬───────┘     └───────────────┘
               │
               ▼
       ┌───────────────┐
       │ Zonas         │
       └───────┬───────┘
               │
               ▼
       ┌───────────────┐
       │ Contenido     │
       │ multimedia    │
       └───────┬───────┘
               │
               ▼
       ┌───────────────┐
       │ Generar QR    │
       └───────┬───────┘
               │
               ▼
       ┌───────────────┐
       │ Descargar QR  │
       └───────────────┘
```

---

## Gestión de Sitios y Zonas

El administrador puede gestionar la información turística mediante la siguiente estructura:

```text
Sitio Arqueológico
│
├── Información general
│
├── Ubicación
│
├── Imagen principal
│
└── Zonas
    │
    ├── Zona 1
    │   ├── Descripción
    │   ├── Imagen
    │   ├── Audio español
    │   ├── Audio inglés
    │   └── Código QR
    │
    ├── Zona 2
    │   ├── Descripción
    │   ├── Imagen
    │   ├── Audio español
    │   ├── Audio inglés
    │   └── Código QR
    │
    └── Zona N
        ├── Descripción
        ├── Imagen
        ├── Audio español
        ├── Audio inglés
        └── Código QR
```

---

## Código QR

Cada zona turística puede tener asociado un código QR único.

El código QR permite identificar la zona que está visitando el turista y recuperar desde la API la información correspondiente.

El flujo es:

```text
Administrador
      │
      ▼
Selecciona una zona
      │
      ▼
Genera código QR
      │
      ▼
Descarga / imprime QR
      │
      ▼
QR colocado físicamente
en el sitio arqueológico
      │
      ▼
Turista escanea QR
      │
      ▼
Aplicación móvil
      │
      ▼
API Quriy
      │
      ▼
Información de la zona
```

---

## Idiomas

Quriy contempla soporte para dos idiomas:

* 🇪🇸 Español
* 🇬🇧 Inglés

El idioma seleccionado por el turista determina el contenido que se presenta durante el recorrido, incluyendo las audioguías.

---

## Objetivo del Proyecto

El objetivo de Quriy es proporcionar una solución tecnológica que permita mejorar la experiencia turística en los sitios arqueológicos del Cusco mediante el uso de mapas interactivos, códigos QR, contenido multimedia y audioguías bilingües.

La plataforma también permite centralizar la administración del contenido turístico, facilitando a los administradores la creación y actualización de sitios, zonas, imágenes, audios y códigos QR.

---

## Proyecto Académico

**Quriy — Sistema Integral de Autoguiado Multimedia y Gestión Turística**

**UNSAAC — Escuela Profesional de Ingeniería de Informática y de Sistemas**

**Asignatura:** Desarrollo de Software II

**Año:** 2026
