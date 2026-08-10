import os
import uuid
from fastapi import APIRouter, Depends, HTTPException, status, UploadFile, File, Form
from fastapi.security import HTTPBearer, HTTPAuthorizationCredentials
from sqlalchemy.orm import Session
from typing import List
from gtts import gTTS
from gtts.tts import gTTSError
from deep_translator import GoogleTranslator
from deep_translator.exceptions import RequestError as TraduccionRequestError
import cloudinary
import cloudinary.uploader
from app.database import get_db
from app.models.models import Contenido, Zona, Usuario
from app.auth import verificar_token
from app.schemas.schemas import (
    ContenidoCreate, ContenidoUpdate, ContenidoResponse, ArchivoSubidoResponse,
    GenerarAudioRequest, GenerarAudioResponse,
    TraducirRequest, TraducirResponse,
)

# ============================================================
# CLOUDINARY (almacenamiento permanente de imagenes, gratis)
# Se configura solo si las 3 variables de entorno existen. Si no
# existen (por ejemplo en desarrollo local sin cuenta configurada),
# se usa el guardado local como respaldo (comportamiento anterior).
# ============================================================
CLOUDINARY_ACTIVO = bool(
    os.getenv("CLOUDINARY_CLOUD_NAME")
    and os.getenv("CLOUDINARY_API_KEY")
    and os.getenv("CLOUDINARY_API_SECRET")
)

if CLOUDINARY_ACTIVO:
    cloudinary.config(
        cloud_name=os.getenv("CLOUDINARY_CLOUD_NAME"),
        api_key=os.getenv("CLOUDINARY_API_KEY"),
        api_secret=os.getenv("CLOUDINARY_API_SECRET"),
        secure=True,
    )

DIRECTORIO_STATIC = os.path.join(os.path.dirname(__file__), "..", "static")
EXTENSIONES_PERMITIDAS = {
    "imagen": {".jpg", ".jpeg", ".png", ".webp", ".gif"},
    "audio": {".mp3", ".wav", ".ogg", ".m4a"},
}
TAMANO_MAXIMO_BYTES = {
    "imagen": 8 * 1024 * 1024,
    "audio": 20 * 1024 * 1024,
}

router = APIRouter(tags=["Contenido Multimedia"])
security = HTTPBearer()

def obtener_usuario_token(
    credentials: HTTPAuthorizationCredentials = Depends(security),
    db: Session = Depends(get_db)
):
    payload = verificar_token(credentials.credentials)
    if not payload:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Token inválido o expirado"
        )
    usuario = db.query(Usuario).filter(
        Usuario.id == int(payload.get("sub"))
    ).first()
    if not usuario:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Usuario no encontrado"
        )
    return usuario

def verificar_admin(usuario: Usuario = Depends(obtener_usuario_token)):
    if usuario.rol != "admin":
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Solo administradores pueden realizar esta acción"
        )
    return usuario


@router.post("/contenido/upload", response_model=ArchivoSubidoResponse, status_code=201)
def subir_archivo_contenido(
    tipo: str = Form(...),
    archivo: UploadFile = File(...),
    admin: Usuario = Depends(verificar_admin)
):
    if tipo not in EXTENSIONES_PERMITIDAS:
        raise HTTPException(status_code=400, detail="El tipo debe ser 'imagen' o 'audio'")

    extension = os.path.splitext(archivo.filename or "")[1].lower()
    if extension not in EXTENSIONES_PERMITIDAS[tipo]:
        permitidas = ", ".join(sorted(EXTENSIONES_PERMITIDAS[tipo]))
        raise HTTPException(
            status_code=400,
            detail=f"Extensión no permitida para {tipo}. Usa: {permitidas}"
        )

    contenido_bytes = archivo.file.read()
    if len(contenido_bytes) > TAMANO_MAXIMO_BYTES[tipo]:
        raise HTTPException(status_code=400, detail="El archivo excede el tamaño máximo permitido")

    # Las imagenes van a Cloudinary (permanente) si esta configurado.
    # El audio sigue guardandose local por ahora (no se pidio persistencia para audio todavia).
    if tipo == "imagen" and CLOUDINARY_ACTIVO:
        try:
            resultado = cloudinary.uploader.upload(
                contenido_bytes,
                folder="quriy",
                resource_type="image",
            )
            return {"url_recurso": resultado["secure_url"]}
        except Exception as error:
            raise HTTPException(
                status_code=502,
                detail=f"No se pudo subir la imagen a Cloudinary: {error}"
            )

    subcarpeta = "imagenes" if tipo == "imagen" else "audio"
    carpeta_destino = os.path.join(DIRECTORIO_STATIC, subcarpeta)
    os.makedirs(carpeta_destino, exist_ok=True)

    nombre_archivo = f"{uuid.uuid4().hex}{extension}"
    with open(os.path.join(carpeta_destino, nombre_archivo), "wb") as destino:
        destino.write(contenido_bytes)

    return {"url_recurso": f"/static/{subcarpeta}/{nombre_archivo}"}


@router.post("/zonas/{id}/contenido", response_model=ContenidoResponse, status_code=201)
def crear_contenido_zona(
    id: int,
    datos: ContenidoCreate,
    db: Session = Depends(get_db),
    admin: Usuario = Depends(verificar_admin)
):
    zona = db.query(Zona).filter(Zona.id == id).first()
    if not zona:
        raise HTTPException(status_code=404, detail="Zona no encontrada")
    contenido = Contenido(
        zona_id=id,
        tipo=datos.tipo,
        idioma=datos.idioma,
        url=datos.url,
        texto=datos.texto,
        titulo=datos.titulo,
        url_recurso=datos.url_recurso
    )
    db.add(contenido)
    db.commit()
    db.refresh(contenido)
    return contenido


@router.put("/contenido/{id}", response_model=ContenidoResponse)
def editar_contenido(
    id: int,
    datos: ContenidoUpdate,
    db: Session = Depends(get_db),
    admin: Usuario = Depends(verificar_admin)
):
    contenido = db.query(Contenido).filter(Contenido.id == id).first()
    if not contenido:
        raise HTTPException(status_code=404, detail="Contenido no encontrado")
    if datos.tipo is not None:
        contenido.tipo = datos.tipo
    if datos.idioma is not None:
        contenido.idioma = datos.idioma
    if datos.url is not None:
        contenido.url = datos.url
    if datos.texto is not None:
        contenido.texto = datos.texto
    if datos.titulo is not None:
        contenido.titulo = datos.titulo
    if datos.url_recurso is not None:
        contenido.url_recurso = datos.url_recurso
    db.commit()
    db.refresh(contenido)
    return contenido


@router.delete("/contenido/{id}", status_code=204)
def eliminar_contenido(
    id: int,
    db: Session = Depends(get_db),
    admin: Usuario = Depends(verificar_admin)
):
    contenido = db.query(Contenido).filter(Contenido.id == id).first()
    if not contenido:
        raise HTTPException(status_code=404, detail="Contenido no encontrado")
    db.delete(contenido)
    db.commit()
    return None

@router.get("/contenido/audios", response_model=List[ContenidoResponse])
def listar_biblioteca_audios(
    zona_id: int = None,
    idioma: str = None,
    db: Session = Depends(get_db),
    admin: Usuario = Depends(verificar_admin)
):
    query = db.query(Contenido).filter(Contenido.tipo == "audio")

    if zona_id:
        query = query.filter(Contenido.zona_id == zona_id)
    if idioma:
        query = query.filter(Contenido.idioma == idioma)

    audios = query.order_by(Contenido.id.desc()).all()
    return audios

# ============================================================
# GENERACION DE AUDIO CON IA (gTTS) - Issue #93
# ============================================================
# Idiomas soportados por gTTS que usa este proyecto (es/en).
IDIOMAS_TTS_VALIDOS = {"es", "en"}


@router.post("/contenido/generar-audio", response_model=GenerarAudioResponse, status_code=201)
def generar_audio_con_ia(
    datos: GenerarAudioRequest,
    admin: Usuario = Depends(verificar_admin)
):
    """
    Recibe un texto (por ejemplo, el guion de una audioguia) y devuelve
    la URL de un archivo de audio MP3 generado automaticamente con IA
    (gTTS - Google Text-to-Speech, gratuito, sin API key).
    """
    if not datos.texto or not datos.texto.strip():
        raise HTTPException(status_code=400, detail="El texto no puede estar vacio")

    if len(datos.texto) > 5000:
        raise HTTPException(
            status_code=400,
            detail="El texto no puede superar los 5000 caracteres por generacion"
        )

    if datos.idioma not in IDIOMAS_TTS_VALIDOS:
        raise HTTPException(
            status_code=400,
            detail=f"Idioma no soportado. Usa: {', '.join(sorted(IDIOMAS_TTS_VALIDOS))}"
        )

    subcarpeta = "audio"
    carpeta_destino = os.path.join(DIRECTORIO_STATIC, subcarpeta)
    os.makedirs(carpeta_destino, exist_ok=True)

    nombre_archivo = f"ia_{uuid.uuid4().hex}.mp3"
    ruta_completa = os.path.join(carpeta_destino, nombre_archivo)

    try:
        audio = gTTS(text=datos.texto, lang=datos.idioma, slow=False)
        audio.save(ruta_completa)
    except gTTSError as error:
        raise HTTPException(
            status_code=502,
            detail=f"No se pudo generar el audio con el servicio de IA: {error}"
        )
    except Exception as error:
        raise HTTPException(
            status_code=502,
            detail=f"Error inesperado generando el audio: {error}"
        )

    return {"url_recurso": f"/static/{subcarpeta}/{nombre_archivo}"}


# ============================================================
# TRADUCCION AUTOMATICA ES -> EN (deep-translator) - Issue #93
# ============================================================
IDIOMAS_TRADUCCION_VALIDOS = {"es", "en"}


@router.post("/contenido/traducir", response_model=TraducirResponse)
def traducir_texto_con_ia(
    datos: TraducirRequest,
    admin: Usuario = Depends(verificar_admin)
):
    """
    Traduce un texto de forma automatica (por defecto espanol -> ingles)
    usando deep-translator (gratuito, sin API key). Pensado para generar
    rapidamente la version en ingles del guion de una audioguia.
    """
    if not datos.texto or not datos.texto.strip():
        raise HTTPException(status_code=400, detail="El texto no puede estar vacio")

    if datos.idioma_origen not in IDIOMAS_TRADUCCION_VALIDOS:
        raise HTTPException(status_code=400, detail="Idioma de origen no soportado")
    if datos.idioma_destino not in IDIOMAS_TRADUCCION_VALIDOS:
        raise HTTPException(status_code=400, detail="Idioma de destino no soportado")
    if datos.idioma_origen == datos.idioma_destino:
        raise HTTPException(
            status_code=400,
            detail="El idioma de origen y destino no pueden ser el mismo"
        )

    try:
        traductor = GoogleTranslator(
            source=datos.idioma_origen,
            target=datos.idioma_destino
        )
        texto_traducido = traductor.translate(datos.texto)
    except TraduccionRequestError as error:
        raise HTTPException(
            status_code=502,
            detail=f"No se pudo contactar el servicio de traduccion: {error}"
        )
    except Exception as error:
        raise HTTPException(
            status_code=502,
            detail=f"Error inesperado traduciendo el texto: {error}"
        )

    return {"texto_traducido": texto_traducido}

# ============================================================
# GENERAR AUDIOGUIA COMPLETA (ES audio + EN texto + EN audio)
# a partir del guion en espanol ya existente en la zona.
# Es idempotente: si algo ya existe, no lo duplica.
# ============================================================
@router.post("/zonas/{id}/generar-audioguia-completa")
def generar_audioguia_completa(
    id: int,
    db: Session = Depends(get_db),
    admin: Usuario = Depends(verificar_admin)
):
    zona = db.query(Zona).filter(Zona.id == id).first()
    if not zona:
        raise HTTPException(status_code=404, detail="Zona no encontrada")

    resultado = {
        "audio_es": "ya existia",
        "texto_en": "ya existia",
        "audio_en": "ya existia",
    }

    # 1) Buscar el guion base en espanol (creado por seed.py)
    texto_es = db.query(Contenido).filter(
        Contenido.zona_id == id,
        Contenido.tipo == "texto",
        Contenido.idioma == "es",
    ).first()

    if not texto_es or not texto_es.texto:
        raise HTTPException(
            status_code=404,
            detail="Esta zona no tiene un guion en espanol todavia. "
                   "Crea primero un contenido de tipo texto en espanol."
        )

    subcarpeta = "audio"
    carpeta_destino = os.path.join(DIRECTORIO_STATIC, subcarpeta)
    os.makedirs(carpeta_destino, exist_ok=True)

    # 2) Generar audio en espanol si no existe
    audio_es = db.query(Contenido).filter(
        Contenido.zona_id == id,
        Contenido.tipo == "audio",
        Contenido.idioma == "es",
    ).first()

    if not audio_es:
        try:
            nombre_archivo = f"ia_{uuid.uuid4().hex}.mp3"
            ruta = os.path.join(carpeta_destino, nombre_archivo)
            gTTS(text=texto_es.texto, lang="es", slow=False).save(ruta)
            nuevo_audio_es = Contenido(
                zona_id=id,
                tipo="audio",
                idioma="es",
                titulo=texto_es.titulo or f"Audioguía: {zona.nombre}",
                texto=texto_es.texto,
                url_recurso=f"/static/{subcarpeta}/{nombre_archivo}",
            )
            db.add(nuevo_audio_es)
            db.commit()
            resultado["audio_es"] = "generado"
        except Exception as error:
            resultado["audio_es"] = f"error: {error}"

    # 3) Traducir el texto al ingles si no existe
    texto_en = db.query(Contenido).filter(
        Contenido.zona_id == id,
        Contenido.tipo == "texto",
        Contenido.idioma == "en",
    ).first()

    texto_en_valor = texto_en.texto if texto_en else None

    if not texto_en:
        try:
            texto_en_valor = GoogleTranslator(
                source="es", target="en"
            ).translate(texto_es.texto)
            nuevo_texto_en = Contenido(
                zona_id=id,
                tipo="texto",
                idioma="en",
                titulo=f"Audio guide: {zona.nombre}",
                texto=texto_en_valor,
            )
            db.add(nuevo_texto_en)
            db.commit()
            resultado["texto_en"] = "generado"
        except Exception as error:
            resultado["texto_en"] = f"error: {error}"
            texto_en_valor = None

    # 4) Generar audio en ingles si no existe y ya tenemos el texto traducido
    audio_en = db.query(Contenido).filter(
        Contenido.zona_id == id,
        Contenido.tipo == "audio",
        Contenido.idioma == "en",
    ).first()

    if not audio_en and texto_en_valor:
        try:
            nombre_archivo = f"ia_{uuid.uuid4().hex}.mp3"
            ruta = os.path.join(carpeta_destino, nombre_archivo)
            gTTS(text=texto_en_valor, lang="en", slow=False).save(ruta)
            nuevo_audio_en = Contenido(
                zona_id=id,
                tipo="audio",
                idioma="en",
                titulo=f"Audio guide: {zona.nombre}",
                texto=texto_en_valor,
                url_recurso=f"/static/{subcarpeta}/{nombre_archivo}",
            )
            db.add(nuevo_audio_en)
            db.commit()
            resultado["audio_en"] = "generado"
        except Exception as error:
            resultado["audio_en"] = f"error: {error}"

    return resultado