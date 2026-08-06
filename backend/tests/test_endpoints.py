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