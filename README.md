# Quriy — Sistema Integral de Autoguiado Multimedia y Gestión Turística

> Plataforma multicliente para recorridos autoguiados en sitios arqueológicos del Cusco

---

## Descripción

Quriy permite a los turistas recorrer sitios arqueológicos del Cusco de forma autoguiada, accediendo a contenido histórico y audioguías en español e inglés mediante el escaneo de códigos QR. A su vez, los administradores pueden gestionar sitios, zonas y contenido multimedia desde una plataforma web.

La solución está conformada por tres capas:
- **App móvil** para el turista (Flutter)
- **Panel web** para el administrador (React)
- **API REST centralizada** que sirve a ambos clientes (FastAPI)

---

## Integrantes

| Nombre | Rol |
|--------|-----|
| Diaz Misme, Pamela | Coordinadora · Frontend Web |
| Llancaya Tapia, Aracely | Backend Developer |
| Vargas Zegarra, Marco Antonio Axel | Mobile Developer (Flutter) |

**Asignatura:** Desarrollo de Software II  
**Docente:** Hans Harley Ccacyahuillca Bejar  
**Universidad:** UNSAAC — Escuela Profesional de Ingeniería de Informática y de Sistemas  
**Año:** 2026

---

## Tecnologías

| Capa | Tecnología |
|------|------------|
| Backend | FastAPI, SQLite, SQLAlchemy, JWT |
| Frontend Web | React, Vite, Axios, React Router Dom |
| Mobile | Flutter, mobile_scanner, flutter_map, provider |

---

## Funcionalidades MVP

### Turista (App Móvil)
- Explorar mapa interactivo de sitios arqueológicos
- Escanear código QR de una zona
- Reproducir audioguía en español / inglés
- Ver imágenes del sitio
- Registrar y calificar recorrido
- Modo sin conexión (contenido básico)

### Administrador (Panel Web)
- Login con autenticación JWT
- Gestionar sitios arqueológicos y zonas
- Subir audio e imágenes
- Generar y descargar códigos QR
- Ver estadísticas de visitas

---

## Diagrama de Clases

El sistema está modelado con las siguientes entidades principales:

`Usuario` · `Turista` · `Administrador` · `SitioArqueologico` · `Zona` · `Contenido` · `CodigoQR` · `Recorrido` · `VisitaZona`

![Diagrama de clases](./docs/diagrama-clases.png)

---

## Cómo correr el proyecto localmente

### Backend
```bash
cd backend
pip install -r requirements.txt
python seed.py
uvicorn app.main:app --reload
```
La API estará disponible en `http://localhost:8000`  
Documentación interactiva: `http://localhost:8000/docs`

### Frontend Web
```bash
cd frontend-web
npm install
npm run dev
```
El panel estará disponible en `http://localhost:5173`

### Mobile
```bash
cd mobile
flutter pub get
flutter run
```


## Estructura del Repositorio

```
quriy/
├── backend/
│   ├── app/
│   │   ├── models/
│   │   ├── routes/
│   │   ├── schemas/
│   │   └── main.py
│   ├── tests/
│   ├── seed.py
│   └── requirements.txt
├── frontend-web/
│   └── src/
│       ├── components/
│       ├── pages/
│       └── services/
└── mobile/
    └── lib/
        ├── models/
        ├── services/
        └── screens/
```

---

*Proyecto académico — UNSAAC 2026*