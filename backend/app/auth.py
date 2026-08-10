import os
from datetime import datetime, timedelta
from jose import JWTError, jwt
from passlib.context import CryptContext
from google.auth.transport import requests as google_requests
from google.oauth2 import id_token as google_id_token

SECRET_KEY = os.getenv("SECRET_KEY", "quriy-secret-key-cusco-2024")
ALGORITHM = "HS256"
ACCESS_TOKEN_EXPIRE_MINUTES = 1440

# IDs de cliente OAuth de Google Cloud válidos como audience del id_token
# (normalmente el "Web client ID" usado como serverClientId en la app
# móvil). Se admite más de uno separado por comas por si se agregan
# clientes adicionales en el futuro.
GOOGLE_CLIENT_IDS = [
    cid.strip() for cid in os.getenv("GOOGLE_CLIENT_ID", "").split(",") if cid.strip()
]

pwd_context = CryptContext(schemes=["sha256_crypt"], deprecated="auto")

def verificar_password(plain, hashed):
    return pwd_context.verify(plain, hashed)

def hashear_password(password):
    return pwd_context.hash(password)

def crear_token(data: dict):
    to_encode = data.copy()
    expira = datetime.utcnow() + timedelta(minutes=ACCESS_TOKEN_EXPIRE_MINUTES)
    to_encode.update({"exp": expira})
    return jwt.encode(to_encode, SECRET_KEY, algorithm=ALGORITHM)

def verificar_token(token: str):
    try:
        payload = jwt.decode(token, SECRET_KEY, algorithms=[ALGORITHM])
        return payload
    except JWTError:
        return None

def verificar_id_token_google(token: str):
    """Valida un id_token de Google Sign-In (firma, expiración y audience).
    Devuelve el payload verificado o None si el token no es válido."""
    if not GOOGLE_CLIENT_IDS:
        return None

    try:
        payload = google_id_token.verify_oauth2_token(token, google_requests.Request())
    except ValueError:
        return None

    if payload.get("aud") not in GOOGLE_CLIENT_IDS:
        return None
    if payload.get("iss") not in ("accounts.google.com", "https://accounts.google.com"):
        return None

    return payload