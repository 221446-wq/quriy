from sqlalchemy import create_engine, inspect, text
from sqlalchemy.ext.declarative import declarative_base
from sqlalchemy.orm import sessionmaker

DATABASE_URL = "sqlite:///./quriy.db"

engine = create_engine(
    DATABASE_URL, connect_args={"check_same_thread": False}
)

SessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=engine)

Base = declarative_base()

def get_db():
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()

def migrar_columnas_nuevas():
    """Agrega columnas nuevas a tablas ya existentes (no hay Alembic en
    este proyecto). Base.metadata.create_all no altera tablas existentes,
    así que las columnas agregadas al modelo después del primer deploy
    necesitan un ALTER TABLE explícito."""
    inspector = inspect(engine)
    if "usuarios" not in inspector.get_table_names():
        return

    columnas_existentes = {c["name"] for c in inspector.get_columns("usuarios")}
    columnas_nuevas = {
        "proveedor": "ALTER TABLE usuarios ADD COLUMN proveedor VARCHAR DEFAULT 'local'",
        "google_id": "ALTER TABLE usuarios ADD COLUMN google_id VARCHAR",
    }

    with engine.begin() as conn:
        for columna, sentencia in columnas_nuevas.items():
            if columna not in columnas_existentes:
                conn.execute(text(sentencia))