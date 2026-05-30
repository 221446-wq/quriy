"""
seed.py — Datos de prueba para Quriy
Ejecutar desde la carpeta /backend:
    python seed.py
"""

import sys
import os
sys.path.append(os.path.dirname(os.path.abspath(__file__)))

from app.database import SessionLocal, engine, Base
from app.models.models import (
    Usuario, Administrador, Turista,
    SitioArqueologico, Zona, Contenido
)
from app.auth import hashear_password

# Crear todas las tablas si no existen
Base.metadata.create_all(bind=engine)

db = SessionLocal()

# ── Limpiar datos previos (orden por dependencias) ──────
print("🗑  Limpiando datos anteriores...")
db.query(Contenido).delete()
db.query(Zona).delete()
db.query(SitioArqueologico).delete()
db.query(Administrador).delete()
db.query(Turista).delete()
db.query(Usuario).delete()
db.commit()

# ── Usuarios ────────────────────────────────────────────
print("👤 Creando usuarios...")

admin_usuario = Usuario(
    email="admin@quriy.pe",
    hashed_password=hashear_password("admin123"),
    rol="admin",
    activo=True,
)
turista_usuario = Usuario(
    email="turista@quriy.pe",
    hashed_password=hashear_password("turista123"),
    rol="turista",
    activo=True,
)
db.add_all([admin_usuario, turista_usuario])
db.commit()
db.refresh(admin_usuario)
db.refresh(turista_usuario)

# ── Perfiles ─────────────────────────────────────────────
admin_perfil = Administrador(usuario_id=admin_usuario.id, nombre="Pamela Admin")
turista_perfil = Turista(usuario_id=turista_usuario.id, nombre="Marco Turista", idioma_preferido="es")
db.add_all([admin_perfil, turista_perfil])
db.commit()

# ── Sitios arqueológicos ─────────────────────────────────
print("🏛  Creando sitios arqueológicos...")

sacsayhuaman = SitioArqueologico(
    nombre="Sacsayhuamán",
    descripcion="Fortaleza inca construida con enormes bloques de piedra, ubicada al norte del Cusco.",
    ubicacion="Cusco, Perú",
    imagen_url="https://upload.wikimedia.org/wikipedia/commons/thumb/b/b4/Sacsahuaman_1.jpg/1280px-Sacsahuaman_1.jpg",
    activo=True,
)
qorikancha = SitioArqueologico(
    nombre="Qorikancha",
    descripcion="Templo del Sol, el más importante del Imperio Inca, cubierto originalmente de oro.",
    ubicacion="Cusco, Perú",
    imagen_url="https://upload.wikimedia.org/wikipedia/commons/2/2e/Koricancha-Cusco.jpg",
    activo=True,
)
ollantaytambo = SitioArqueologico(
    nombre="Ollantaytambo",
    descripcion="Fortaleza y pueblo inca en el Valle Sagrado de los Incas.",
    ubicacion="Valle Sagrado, Cusco",
    imagen_url="https://upload.wikimedia.org/wikipedia/commons/0/0e/Ollantaytambo-Cusco-Peru.jpg",
    activo=True,
)
db.add_all([sacsayhuaman, qorikancha, ollantaytambo])
db.commit()
db.refresh(sacsayhuaman)
db.refresh(qorikancha)
db.refresh(ollantaytambo)

# ── Zonas ────────────────────────────────────────────────
print("📍 Creando zonas...")

zonas_sacsay = [
    Zona(sitio_id=sacsayhuaman.id, nombre="Murallas Principales", descripcion="Tres terrazas de enormes bloques calcáreos en zigzag.", orden=1),
    Zona(sitio_id=sacsayhuaman.id, nombre="Trono del Inca", descripcion="Plataforma ceremonial donde se realizaban rituales.", orden=2),
    Zona(sitio_id=sacsayhuaman.id, nombre="Torre Muyucmarca", descripcion="Torre circular de tres pisos, centro del complejo.", orden=3),
]
zonas_qori = [
    Zona(sitio_id=qorikancha.id, nombre="Templo del Sol", descripcion="Recinto principal dedicado a Inti, el dios sol.", orden=1),
    Zona(sitio_id=qorikancha.id, nombre="Jardín de Oro", descripcion="Jardín donde había plantas y animales de oro macizo.", orden=2),
]
zonas_ollan = [
    Zona(sitio_id=ollantaytambo.id, nombre="Templo del Sol", descripcion="Seis monolitos rosados que forman el templo principal.", orden=1),
    Zona(sitio_id=ollantaytambo.id, nombre="Andenes de Cultivo", descripcion="Terrazas agrícolas escalonadas aún en uso hoy.", orden=2),
    Zona(sitio_id=ollantaytambo.id, nombre="Fuente Ceremonial", descripcion="Complejo sistema de canales y fuentes rituales.", orden=3),
]

todas_las_zonas = zonas_sacsay + zonas_qori + zonas_ollan
db.add_all(todas_las_zonas)
db.commit()
for z in todas_las_zonas:
    db.refresh(z)

# ── Contenido ────────────────────────────────────────────
print("📝 Creando contenido...")

contenidos = []
textos = {
    "es": "Este es un lugar de gran importancia histórica para la cultura inca. Los visitantes pueden apreciar la arquitectura milenaria.",
    "en": "This is a place of great historical importance for the Inca culture. Visitors can appreciate the ancient architecture.",
}

for zona in todas_las_zonas:
    contenidos.append(Contenido(
        zona_id=zona.id, tipo="texto", idioma="es",
        texto=textos["es"], url=None,
    ))
    contenidos.append(Contenido(
        zona_id=zona.id, tipo="texto", idioma="en",
        texto=textos["en"], url=None,
    ))
    contenidos.append(Contenido(
        zona_id=zona.id, tipo="audio", idioma="es",
        url="https://www.soundhelix.com/examples/mp3/SoundHelix-Song-1.mp3",
        texto=None,
    ))

db.add_all(contenidos)
db.commit()

db.close()

print("")
print("✅ Base de datos lista con datos de prueba")
print("")
print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
print("  CREDENCIALES DE PRUEBA")
print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
print("  Admin:   admin@quriy.pe   / admin123")
print("  Turista: turista@quriy.pe / turista123")
print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
print(f"  Sitios creados : 3")
print(f"  Zonas creadas  : {len(todas_las_zonas)}")
print(f"  Contenidos     : {len(contenidos)}")
print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")