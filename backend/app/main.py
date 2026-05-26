from fastapi import FastAPI
from app.database import engine, Base
from app.models import models

Base.metadata.create_all(bind=engine)

app = FastAPI(
    title="Quriy API",
    description="Sistema de Autoguiado Turístico - Cusco",
    version="1.0.0"
)

@app.get("/")
def root():
    return {"mensaje": "Quriy API funcionando", "version": "1.0.0"}

@app.get("/health")
def health():
    return {"status": "ok"}