# Quriy — Sistema Integral de Autoguiado Multimedia y Gestión Turística

Quriy es una plataforma multicliente diseñada para enriquecer la experiencia del turista en los sitios arqueológicos de la región Cusco, combinando audioguías, mapas interactivos y códigos QR.

Descripción 

Quriy permite a los turistas recorrer sitios arqueológicos del Cusco de forma autoguiada, accediendo a contenido histórico y audioguías en español e inglés mediante el escaneo de códigos QR. A su vez, los administradores pueden gestionar sitios, zonas y contenido multimedia desde una plataforma web.

Integrantes

- Diaz Misme, Pamela: Coordinadora, Frontend Web
- Llancaya Tapia, Aracely: Backend Developer
- Vargas Zegarra, Marco Antonio Axel: Mobile,Developer (Flutter)

Asignatura: Desarrollo de Software II  
Docente: Hans Harley Ccacyahuillca Bejar  
Universidad: UNSAAC — Escuela Profesional de Ingeniería de Informática y de Sistemas  

Funcionalidades MVP
Turista (App Móvil)

- Explorar mapa interactivo de sitios arqueológicos
- Escanear código QR de una zona
- Reproducir audioguía en español / inglés
- Ver imágenes del sitio
- Registrar y calificar recorrido
- Modo sin conexión (contenido básico)

Administrador (Web)

- Login con autenticación JWT
- Gestionar sitios arqueológicos y zonas
- Subir audio e imágenes
- Generar y descargar códigos QR
- Ver estadísticas de visitas


Diagrama de Clases
El sistema está modelado con las siguientes entidades principales:
Usuario, Turista, Administrador, Recorrido, VisitaZona, SitioArqueologico, Zona, Contenido, CodigoQR