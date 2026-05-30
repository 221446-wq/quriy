from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware  # ← agregar
from app.database import engine, Base
from app.models import models
from app.routes import auth, sitios

Base.metadata.create_all(bind=engine)

app = FastAPI(
    title="Quriy API",
    description="Sistema de Autoguiado Turístico - Cusco",
    version="1.0.0"
)

# ← agregar todo esto
app.add_middleware(
    CORSMiddleware,
    allow_origins=["http://localhost:5173"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

app.include_router(auth.router)
app.include_router(sitios.router)

@app.get("/")
def root():
    return {"mensaje": "Quriy API funcionando", "version": "1.0.0"}

@app.get("/health")
def health():
    return {"status": "ok"}