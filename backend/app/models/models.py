from sqlalchemy import Column, Integer, String, Boolean, ForeignKey, DateTime, Text
from sqlalchemy.orm import relationship
from datetime import datetime
from app.database import Base

class Usuario(Base):
    __tablename__ = "usuarios"
    id = Column(Integer, primary_key=True, index=True)
    email = Column(String, unique=True, index=True, nullable=False)
    hashed_password = Column(String, nullable=False)
    rol = Column(String, default="turista")
    activo = Column(Boolean, default=True)
    creado_en = Column(DateTime, default=datetime.utcnow)

class Turista(Base):
    __tablename__ = "turistas"
    id = Column(Integer, primary_key=True, index=True)
    usuario_id = Column(Integer, ForeignKey("usuarios.id"))
    nombre = Column(String)
    idioma_preferido = Column(String, default="es")
    usuario = relationship("Usuario")
    visitas = relationship("VisitaZona", back_populates="turista")

class Administrador(Base):
    __tablename__ = "administradores"
    id = Column(Integer, primary_key=True, index=True)
    usuario_id = Column(Integer, ForeignKey("usuarios.id"))
    nombre = Column(String)
    usuario = relationship("Usuario")

class SitioArqueologico(Base):
    __tablename__ = "sitios_arqueologicos"
    id = Column(Integer, primary_key=True, index=True)
    nombre = Column(String, nullable=False)
    descripcion = Column(Text)
    ubicacion = Column(String)
    imagen_url = Column(String)
    activo = Column(Boolean, default=True)
    zonas = relationship("Zona", back_populates="sitio")

class Zona(Base):
    __tablename__ = "zonas"
    id = Column(Integer, primary_key=True, index=True)
    sitio_id = Column(Integer, ForeignKey("sitios_arqueologicos.id"))
    nombre = Column(String, nullable=False)
    descripcion = Column(Text)
    orden = Column(Integer, default=0)
    sitio = relationship("SitioArqueologico", back_populates="zonas")
    contenidos = relationship("Contenido", back_populates="zona")
    codigos_qr = relationship("CodigoQR", back_populates="zona")
    visitas = relationship("VisitaZona", back_populates="zona")

class Contenido(Base):
    __tablename__ = "contenidos"
    id = Column(Integer, primary_key=True, index=True)
    zona_id = Column(Integer, ForeignKey("zonas.id"))
    tipo = Column(String)
    idioma = Column(String, default="es")
    url = Column(String)
    texto = Column(Text)
    zona = relationship("Zona", back_populates="contenidos")

class CodigoQR(Base):
    __tablename__ = "codigos_qr"
    id = Column(Integer, primary_key=True, index=True)
    zona_id = Column(Integer, ForeignKey("zonas.id"))
    codigo = Column(String, unique=True, index=True)
    url_destino = Column(String)
    creado_en = Column(DateTime, default=datetime.utcnow)
    zona = relationship("Zona", back_populates="codigos_qr")

class Recorrido(Base):
    __tablename__ = "recorridos"
    id = Column(Integer, primary_key=True, index=True)
    turista_id = Column(Integer, ForeignKey("turistas.id"))
    sitio_id = Column(Integer, ForeignKey("sitios_arqueologicos.id"))
    inicio = Column(DateTime, default=datetime.utcnow)
    fin = Column(DateTime, nullable=True)
    turista = relationship("Turista")
    sitio = relationship("SitioArqueologico")

class VisitaZona(Base):
    __tablename__ = "visitas_zona"
    id = Column(Integer, primary_key=True, index=True)
    turista_id = Column(Integer, ForeignKey("turistas.id"))
    zona_id = Column(Integer, ForeignKey("zonas.id"))
    timestamp = Column(DateTime, default=datetime.utcnow)
    idioma = Column(String, default="es")
    turista = relationship("Turista", back_populates="visitas")
    zona = relationship("Zona", back_populates="visitas")