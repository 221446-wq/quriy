import os
from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from fastapi.staticfiles import StaticFiles
from app.database import engine, Base
from app.models import models
from app.routes import auth, sitios, contenido, recorridos, visitas, estadisticas

Base.metadata.create_all(bind=engine)

app = FastAPI(
    title="Quriy API",
    description="Sistema de Autoguiado Turístico - Cusco",
    version="1.0.0"
)

CORS_ORIGINS = os.getenv(
    "CORS_ORIGINS",
    "http://localhost:5173,http://localhost:3000"
).split(",")

app.add_middleware(
    CORSMiddleware,
    allow_origins=CORS_ORIGINS,
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

app.mount("/static", StaticFiles(directory="app/static"), name="static")
app.include_router(auth.router)
app.include_router(sitios.router)
app.include_router(contenido.router)
app.include_router(recorridos.router)
app.include_router(visitas.router)
app.include_router(estadisticas.router)

@app.get("/")
def root():
    return {"mensaje": "Quriy API funcionando", "version": "1.0.0"}

@app.get("/health")
def health():
    return {"status": "ok"}