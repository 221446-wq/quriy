"""
Pruebas de integración de flujos completos (Issue #89).

Objetivo: cubrir con pruebas el flujo completo entre entidades del
backend, no solo endpoints aislados.
"""


def test_flujo_admin_crear_sitio_zona_qr_contenido_y_verificar_con_get(
    client, token_admin
):
    """
    Flujo completo de administrador:
    crear sitio -> crear zona con lat/long -> generar QR -> crear
    contenido -> verificar TODO nuevamente con peticiones GET.
    """
    headers_admin = {"Authorization": f"Bearer {token_admin}"}

    # 1) Crear sitio
    respuesta_sitio = client.post(
        "/sitios",
        json={
            "nombre": "Qorikancha",
            "descripcion": "Templo del Sol",
            "ubicacion": "Av. El Sol, Cusco",
            "horario": "8:30 - 17:30",
        },
        headers=headers_admin,
    )
    assert respuesta_sitio.status_code == 201
    sitio = respuesta_sitio.json()
    sitio_id = sitio["id"]
    assert sitio["nombre"] == "Qorikancha"

    # 2) Crear zona con latitud/longitud dentro del sitio
    respuesta_zona = client.post(
        f"/sitios/{sitio_id}/zonas",
        json={
            "nombre": "Recinto del Sol",
            "descripcion": "Recinto principal dedicado a Inti",
            "orden": 1,
            "latitud": -13.5183,
            "longitud": -71.9785,
        },
        headers=headers_admin,
    )
    assert respuesta_zona.status_code == 201
    zona = respuesta_zona.json()
    zona_id = zona["id"]
    assert zona["sitio_id"] == sitio_id
    assert zona["latitud"] == -13.5183
    assert zona["longitud"] == -71.9785

    # 3) Generar código QR para la zona
    respuesta_qr = client.post(
        f"/zonas/{zona_id}/qr",
        headers=headers_admin,
    )
    assert respuesta_qr.status_code == 201
    qr = respuesta_qr.json()
    assert qr["zona_id"] == zona_id
    assert qr["codigo"]
    assert qr["url_destino"]

    # 4) Crear contenido (audioguía en texto) para la zona
    respuesta_contenido = client.post(
        f"/zonas/{zona_id}/contenido",
        json={
            "tipo": "texto",
            "idioma": "es",
            "titulo": "Audioguía: Recinto del Sol",
            "texto": "Te encuentras en el corazón espiritual del Imperio Inca...",
        },
        headers=headers_admin,
    )
    assert respuesta_contenido.status_code == 201
    contenido = respuesta_contenido.json()
    contenido_id = contenido["id"]
    assert contenido["zona_id"] == zona_id
    assert contenido["tipo"] == "texto"

    # 5) Verificar TODO nuevamente con GET, de punta a punta

    # 5.1 El sitio aparece en el listado general
    respuesta_get_sitios = client.get("/sitios")
    assert respuesta_get_sitios.status_code == 200
    ids_sitios = [s["id"] for s in respuesta_get_sitios.json()]
    assert sitio_id in ids_sitios

    # 5.2 La zona aparece dentro del sitio, con las coordenadas correctas
    respuesta_get_zonas = client.get(
        f"/sitios/{sitio_id}/zonas",
        headers=headers_admin,
    )
    assert respuesta_get_zonas.status_code == 200
    zonas = respuesta_get_zonas.json()
    zona_encontrada = next(z for z in zonas if z["id"] == zona_id)
    assert zona_encontrada["latitud"] == -13.5183
    assert zona_encontrada["longitud"] == -71.9785

    # 5.3 El QR de la zona sigue siendo el mismo que se generó
    respuesta_get_qr = client.get(
        f"/zonas/{zona_id}/qr",
        headers=headers_admin,
    )
    assert respuesta_get_qr.status_code == 200
    assert respuesta_get_qr.json()["codigo"] == qr["codigo"]

    # 5.4 El contenido aparece en el listado de contenido de la zona
    respuesta_get_contenido = client.get(
        f"/zonas/{zona_id}/contenido",
        headers=headers_admin,
    )
    assert respuesta_get_contenido.status_code == 200
    ids_contenido = [c["id"] for c in respuesta_get_contenido.json()]
    assert contenido_id in ids_contenido


def test_flujo_turista_login_sitios_zonas_contenido_y_registrar_visita(
    client, token_admin, token_turista, turista_id
):
    """
    Flujo completo de turista:
    login -> listar sitios -> listar zonas -> listar contenido ->
    registrar visita con calificación.
    """
    headers_admin = {"Authorization": f"Bearer {token_admin}"}
    headers_turista = {"Authorization": f"Bearer {token_turista}"}

    # Datos previos creados por un admin (setup necesario para el flujo)
    sitio = client.post(
        "/sitios",
        json={"nombre": "Sacsayhuamán", "descripcion": "Fortaleza inca"},
        headers=headers_admin,
    ).json()
    zona = client.post(
        f"/sitios/{sitio['id']}/zonas",
        json={
            "nombre": "Muralla Principal",
            "orden": 1,
            "latitud": -13.5090,
            "longitud": -71.9820,
        },
        headers=headers_admin,
    ).json()
    client.post(
        f"/zonas/{zona['id']}/contenido",
        json={
            "tipo": "texto",
            "idioma": "es",
            "titulo": "Audioguía de la muralla",
            "texto": "Observa los enormes bloques de piedra...",
        },
        headers=headers_admin,
    )

    # 1) El turista inicia sesión (login ya validado por la fixture
    # token_turista, aquí se reafirma que el token es utilizable)
    assert token_turista
    assert len(token_turista) > 10

    # 2) El turista lista los sitios disponibles
    respuesta_sitios = client.get("/sitios")
    assert respuesta_sitios.status_code == 200
    ids_sitios = [s["id"] for s in respuesta_sitios.json()]
    assert sitio["id"] in ids_sitios

    # 3) El turista lista las zonas del sitio elegido
    respuesta_zonas = client.get(
        f"/sitios/{sitio['id']}/zonas",
        headers=headers_turista,
    )
    assert respuesta_zonas.status_code == 200
    ids_zonas = [z["id"] for z in respuesta_zonas.json()]
    assert zona["id"] in ids_zonas

    # 4) El turista consulta el contenido (audioguía) de la zona
    respuesta_contenido = client.get(
        f"/zonas/{zona['id']}/contenido",
        headers=headers_turista,
    )
    assert respuesta_contenido.status_code == 200
    assert len(respuesta_contenido.json()) >= 1

    # 5) El turista registra su visita con una calificación
    respuesta_visita = client.post(
        "/visitas-zona",
        json={
            "turista_id": turista_id,
            "zona_id": zona["id"],
            "idioma": "es",
            "metodo_acceso": "qr",
            "calificacion": 4.5,
            "comentario": "Excelente experiencia, muy recomendable.",
        },
        headers=headers_turista,
    )
    assert respuesta_visita.status_code == 201
    visita = respuesta_visita.json()
    assert visita["turista_id"] == turista_id
    assert visita["zona_id"] == zona["id"]
    assert visita["calificacion"] == 4.5
    assert visita["comentario"] == "Excelente experiencia, muy recomendable."


def test_idempotencia_qr_dos_post_devuelven_el_mismo_codigo(
    client, token_admin
):
    """
    Idempotencia del QR: llamar dos veces a POST /zonas/{id}/qr para la
    misma zona debe devolver siempre el mismo código, sin crear
    duplicados. Solo con ?forzar=true debe generarse uno nuevo.
    """
    headers_admin = {"Authorization": f"Bearer {token_admin}"}

    sitio = client.post(
        "/sitios",
        json={"nombre": "Qenqo", "descripcion": "Centro ceremonial"},
        headers=headers_admin,
    ).json()
    zona = client.post(
        f"/sitios/{sitio['id']}/zonas",
        json={"nombre": "Anfiteatro Semicircular", "orden": 1},
        headers=headers_admin,
    ).json()

    # Primera llamada: crea el QR
    primera_respuesta = client.post(
        f"/zonas/{zona['id']}/qr",
        headers=headers_admin,
    )
    assert primera_respuesta.status_code == 201
    primer_codigo = primera_respuesta.json()["codigo"]

    # Segunda llamada (sin forzar): debe devolver el MISMO código,
    # no crear uno nuevo
    segunda_respuesta = client.post(
        f"/zonas/{zona['id']}/qr",
        headers=headers_admin,
    )
    assert segunda_respuesta.status_code == 201
    segundo_codigo = segunda_respuesta.json()["codigo"]
    assert segundo_codigo == primer_codigo

    # Confirmación adicional: el listado de todos los QR solo tiene
    # UNA entrada para esta zona (no se duplicó en la base de datos)
    respuesta_todos = client.get("/qr/todos", headers=headers_admin)
    assert respuesta_todos.status_code == 200
    qrs_de_la_zona = [
        qr for qr in respuesta_todos.json() if qr["zona_id"] == zona["id"]
    ]
    assert len(qrs_de_la_zona) == 1

    # Con forzar=true SÍ debe generarse un código distinto
    respuesta_forzada = client.post(
        f"/zonas/{zona['id']}/qr?forzar=true",
        headers=headers_admin,
    )
    assert respuesta_forzada.status_code == 201
    codigo_forzado = respuesta_forzada.json()["codigo"]
    assert codigo_forzado != primer_codigo