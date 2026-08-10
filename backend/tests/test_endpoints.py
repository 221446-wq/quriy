import os

from app.routes import auth as auth_routes


def test_login_exitoso_retorna_jwt(client):
    response = client.post("/auth/login", json={
        "email": "admin@quriy.com",
        "password": "admin123"
    })
    assert response.status_code == 200
    data = response.json()
    assert "access_token" in data
    assert data["token_type"] == "bearer"
    assert len(data["access_token"]) > 10


def test_login_credenciales_incorrectas_retorna_401(client):
    response = client.post("/auth/login", json={
        "email": "admin@quriy.com",
        "password": "password_malo"
    })
    assert response.status_code == 401
    assert response.json()["detail"] == "Credenciales incorrectas"


def test_login_google_token_invalido_retorna_401(client, monkeypatch):
    monkeypatch.setattr(auth_routes, "verificar_id_token_google", lambda token: None)

    response = client.post("/auth/google", json={"id_token": "token-falso"})

    assert response.status_code == 401
    assert response.json()["detail"] == "Token de Google inválido o expirado"


def test_login_google_usuario_nuevo_se_crea_automaticamente(client, monkeypatch):
    monkeypatch.setattr(
        auth_routes,
        "verificar_id_token_google",
        lambda token: {
            "email": "nueva.persona@gmail.com",
            "email_verified": True,
            "sub": "google-uid-123",
            "name": "Nueva Persona",
        },
    )

    response = client.post("/auth/google", json={"id_token": "token-valido"})
    assert response.status_code == 200
    data = response.json()
    assert "access_token" in data

    perfil = client.get(
        "/auth/me", headers={"Authorization": f"Bearer {data['access_token']}"}
    )
    assert perfil.status_code == 200
    assert perfil.json()["email"] == "nueva.persona@gmail.com"
    assert perfil.json()["rol"] == "turista"


def test_login_google_usuario_existente_se_vincula_por_email(client, monkeypatch):
    monkeypatch.setattr(
        auth_routes,
        "verificar_id_token_google",
        lambda token: {
            "email": "turista@quriy.com",
            "email_verified": True,
            "sub": "google-uid-456",
            "name": "Turista Demo",
        },
    )

    response = client.post("/auth/google", json={"id_token": "token-valido"})
    assert response.status_code == 200

    perfil = client.get(
        "/auth/me",
        headers={"Authorization": f"Bearer {response.json()['access_token']}"},
    )
    assert perfil.json()["email"] == "turista@quriy.com"


def test_listar_sitios_retorna_lista(client):
    response = client.get("/sitios")
    assert response.status_code == 200
    assert isinstance(response.json(), list)


def test_crear_zona_sin_jwt_retorna_403(client, token_admin):
    sitio = client.post(
        "/sitios",
        json={"nombre": "Machu Picchu", "descripcion": "Ciudadela inca"},
        headers={"Authorization": f"Bearer {token_admin}"}
    )
    sitio_id = sitio.json()["id"]

    response = client.post(
        f"/sitios/{sitio_id}/zonas",
        json={"nombre": "Zona entrada", "orden": 1}
    )
    assert response.status_code in [401, 403]


def test_generar_qr_retorna_codigo_unico(client, token_admin):
    sitio = client.post(
        "/sitios",
        json={"nombre": "Sacsayhuaman", "descripcion": "Fortaleza inca"},
        headers={"Authorization": f"Bearer {token_admin}"}
    )
    sitio_id = sitio.json()["id"]

    zona = client.post(
        f"/sitios/{sitio_id}/zonas",
        json={"nombre": "Zona principal", "orden": 1},
        headers={"Authorization": f"Bearer {token_admin}"}
    )
    zona_id = zona.json()["id"]

    qr1 = client.post(
        f"/zonas/{zona_id}/qr",
        headers={"Authorization": f"Bearer {token_admin}"}
    )
    qr2 = client.post(
        f"/zonas/{zona_id}/qr",
        headers={"Authorization": f"Bearer {token_admin}"}
    )

    assert qr1.status_code == 201
    assert qr2.status_code == 201
    assert qr1.json()["codigo"] == qr2.json()["codigo"]

    qr_forzado = client.post(
        f"/zonas/{zona_id}/qr?forzar=true",
        headers={"Authorization": f"Bearer {token_admin}"}
    )
    assert qr_forzado.status_code == 201
    assert qr_forzado.json()["codigo"] != qr1.json()["codigo"]


def test_subir_archivo_contenido_imagen_valida(client, token_admin):
    response = client.post(
        "/contenido/upload",
        data={"tipo": "imagen"},
        files={"archivo": ("foto.png", b"contenido-falso-png", "image/png")},
        headers={"Authorization": f"Bearer {token_admin}"}
    )
    assert response.status_code == 201
    data = response.json()
    assert data["url_recurso"].startswith("/static/imagenes/")
    assert data["url_recurso"].endswith(".png")

    ruta_generada = os.path.join(os.path.dirname(__file__), "..", "app", data["url_recurso"].lstrip("/"))
    if os.path.exists(ruta_generada):
        os.remove(ruta_generada)


def test_subir_archivo_extension_no_permitida_retorna_400(client, token_admin):
    response = client.post(
        "/contenido/upload",
        data={"tipo": "imagen"},
        files={"archivo": ("malicioso.exe", b"contenido", "application/octet-stream")},
        headers={"Authorization": f"Bearer {token_admin}"}
    )
    assert response.status_code == 400


def test_subir_archivo_sin_admin_retorna_403(client, token_turista):
    response = client.post(
        "/contenido/upload",
        data={"tipo": "imagen"},
        files={"archivo": ("foto.png", b"contenido", "image/png")},
        headers={"Authorization": f"Bearer {token_turista}"}
    )
    assert response.status_code == 403


def test_crear_editar_y_eliminar_contenido_de_zona(client, token_admin):
    sitio = client.post(
        "/sitios",
        json={"nombre": "Choquequirao", "descripcion": "Sitio arqueológico"},
        headers={"Authorization": f"Bearer {token_admin}"}
    )
    sitio_id = sitio.json()["id"]

    zona = client.post(
        f"/sitios/{sitio_id}/zonas",
        json={"nombre": "Plaza principal", "orden": 1},
        headers={"Authorization": f"Bearer {token_admin}"}
    )
    zona_id = zona.json()["id"]

    creado = client.post(
        f"/zonas/{zona_id}/contenido",
        json={"tipo": "texto", "idioma": "es", "titulo": "Historia", "texto": "Reseña histórica"},
        headers={"Authorization": f"Bearer {token_admin}"}
    )
    assert creado.status_code == 201
    contenido_id = creado.json()["id"]

    editado = client.put(
        f"/contenido/{contenido_id}",
        json={"texto": "Reseña histórica actualizada"},
        headers={"Authorization": f"Bearer {token_admin}"}
    )
    assert editado.status_code == 200
    assert editado.json()["texto"] == "Reseña histórica actualizada"

    listado = client.get(
        f"/zonas/{zona_id}/contenido",
        headers={"Authorization": f"Bearer {token_admin}"}
    )
    assert len(listado.json()) == 1

    eliminado = client.delete(
        f"/contenido/{contenido_id}",
        headers={"Authorization": f"Bearer {token_admin}"}
    )
    assert eliminado.status_code == 204