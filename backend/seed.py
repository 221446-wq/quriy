from app.database import SessionLocal, engine, Base
from app.models.models import (
    Usuario, Turista, Administrador,
    SitioArqueologico, Zona, Contenido, CodigoQR
)
from app.auth import hashear_password
import uuid

Base.metadata.create_all(bind=engine)

def poblar_base_de_datos():
    db = SessionLocal()
    try:
        if db.query(Usuario).count() > 0:
            print("La base de datos ya tiene datos.")
            return

        # Usuarios
        admin_usuario = Usuario(
            email="admin@quriy.com",
            hashed_password=hashear_password("admin123"),
            rol="admin",
            activo=True
        )
        turista_usuario = Usuario(
            email="turista@quriy.com",
            hashed_password=hashear_password("turista123"),
            rol="turista",
            activo=True
        )
        db.add(admin_usuario)
        db.add(turista_usuario)
        db.commit()

        # Administrador
        admin = Administrador(
            usuario_id=admin_usuario.id,
            nombre="Administrador Quriy",
            institucion="Municipalidad de Cusco"
        )
        db.add(admin)

        # Turista
        turista = Turista(
            usuario_id=turista_usuario.id,
            nombre="Turista Demo",
            idioma_preferido="es"
        )
        db.add(turista)
        db.commit()

        # Sitios arqueológicos
        machu_picchu = SitioArqueologico(
            nombre="Machu Picchu",
            descripcion="Ciudadela inca del siglo XV",
            ubicacion="Cusco, Perú",
            horario="6:00 AM - 5:30 PM",
            activo=True
        )
        sacsayhuaman = SitioArqueologico(
            nombre="Sacsayhuamán",
            descripcion="Fortaleza inca con enormes bloques de piedra",
            ubicacion="Cusco, Perú",
            horario="7:00 AM - 6:00 PM",
            activo=True
        )
        qorikancha = SitioArqueologico(
            nombre="Qorikancha",
            descripcion="Templo del Sol, centro religioso inca",
            ubicacion="Cusco, Perú",
            horario="8:00 AM - 5:00 PM",
            activo=True
        )
        db.add(machu_picchu)
        db.add(sacsayhuaman)
        db.add(qorikancha)
        db.commit()

        # Zonas de Machu Picchu
        zona_entrada = Zona(
            sitio_id=machu_picchu.id,
            nombre="Zona de Entrada",
            descripcion="Puerta principal de acceso",
            orden=1,
            latitud=-13.1631,
            longitud=-72.5450,
            activa=True
        )
        zona_templo_sol = Zona(
            sitio_id=machu_picchu.id,
            nombre="Templo del Sol",
            descripcion="Templo dedicado al dios Inti",
            orden=2,
            latitud=-13.1633,
            longitud=-72.5455,
            activa=True
        )
        zona_intihuatana = Zona(
            sitio_id=machu_picchu.id,
            nombre="Intihuatana",
            descripcion="Reloj solar inca",
            orden=3,
            latitud=-13.1628,
            longitud=-72.5448,
            activa=True
        )
        db.add(zona_entrada)
        db.add(zona_templo_sol)
        db.add(zona_intihuatana)
        db.commit()

        # Contenido multimedia
        contenido_es = Contenido(
            zona_id=zona_entrada.id,
            tipo="audio",
            idioma="es",
            titulo="Bienvenida a Machu Picchu",
            texto="Bienvenido a la ciudadela inca de Machu Picchu...",
            url_recurso="/static/audio/entrada_es.mp3"
        )
        contenido_en = Contenido(
            zona_id=zona_entrada.id,
            tipo="audio",
            idioma="en",
            titulo="Welcome to Machu Picchu",
            texto="Welcome to the Inca citadel of Machu Picchu...",
            url_recurso="/static/audio/entrada_en.mp3"
        )
        contenido_texto = Contenido(
            zona_id=zona_templo_sol.id,
            tipo="texto",
            idioma="es",
            titulo="Historia del Templo del Sol",
            texto="El Templo del Sol fue construido para rendir culto al dios Inti..."
        )
        db.add(contenido_es)
        db.add(contenido_en)
        db.add(contenido_texto)
        db.commit()

        # Códigos QR
        qr1 = CodigoQR(
            zona_id=zona_entrada.id,
            codigo=str(uuid.uuid4()),
            url_destino=f"https://quriy.onrender.com/zonas/{zona_entrada.id}",
            activo=True
        )
        qr2 = CodigoQR(
            zona_id=zona_templo_sol.id,
            codigo=str(uuid.uuid4()),
            url_destino=f"https://quriy.onrender.com/zonas/{zona_templo_sol.id}",
            activo=True
        )
        db.add(qr1)
        db.add(qr2)
        db.commit()

        print(" Base de datos poblada exitosamente!")
        print(f"   - Admin: admin@quriy.com / admin123")
        print(f"   - Turista: turista@quriy.com / turista123")
        print(f"   - Sitios: {db.query(SitioArqueologico).count()}")
        print(f"   - Zonas: {db.query(Zona).count()}")
        print(f"   - Contenidos: {db.query(Contenido).count()}")
        print(f"   - QRs: {db.query(CodigoQR).count()}")

    finally:
        db.close()

if __name__ == "__main__":
    poblar_base_de_datos()

