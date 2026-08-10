export const ADMIN_EMAIL = "admin@quriy.com";
export const ADMIN_PASSWORD = "admin123";

// Debe coincidir con VITE_API_URL definido en playwright.config.js.
// Importante: las rutas se anclan a este origen (no a "**/ruta") para no
// interceptar también la navegación del propio frontend (p. ej. cuando la
// app hace window.location.reload() hacia http://localhost:5173/sitios).
const API_URL = "http://localhost:8000";

/**
 * Intercepta las llamadas al backend (axios -> VITE_API_URL) y las responde
 * desde un estado en memoria, para que los tests E2E no dependan de un
 * backend real ni de una base de datos compartida.
 */
export async function setupApiMock(
  page,
  { sitiosIniciales = [], zonasIniciales = {} } = {}
) {
  const estado = {
    sitios: [...sitiosIniciales],
    zonas: { ...zonasIniciales },
    qrs: {},
    siguienteIdSitio:
      sitiosIniciales.reduce((max, s) => Math.max(max, s.id), 0) + 1,
    siguienteIdZona: 1000,
    siguienteIdQr: 1,
  };

  await page.route(`${API_URL}/auth/login`, async (route) => {
    const datos = route.request().postDataJSON();
    if (datos.email === ADMIN_EMAIL && datos.password === ADMIN_PASSWORD) {
      await route.fulfill({
        status: 200,
        json: { access_token: "token-e2e-fake", token_type: "bearer" },
      });
    } else {
      await route.fulfill({
        status: 401,
        json: { detail: "Credenciales incorrectas" },
      });
    }
  });

  await page.route(`${API_URL}/sitios`, async (route) => {
    const metodo = route.request().method();
    if (metodo === "GET") {
      await route.fulfill({ status: 200, json: estado.sitios });
    } else if (metodo === "POST") {
      const datos = route.request().postDataJSON();
      const sitio = { id: estado.siguienteIdSitio++, ...datos };
      estado.sitios.push(sitio);
      estado.zonas[sitio.id] = estado.zonas[sitio.id] || [];
      await route.fulfill({ status: 201, json: sitio });
    } else {
      await route.continue();
    }
  });

  await page.route(/^http:\/\/localhost:8000\/sitios\/(\d+)\/zonas/, async (route) => {
    const idSitio = Number(
      new URL(route.request().url()).pathname.match(/\/sitios\/(\d+)\/zonas/)[1]
    );
    const metodo = route.request().method();
    if (metodo === "GET") {
      await route.fulfill({ status: 200, json: estado.zonas[idSitio] || [] });
    } else if (metodo === "POST") {
      const datos = route.request().postDataJSON();
      const zona = {
        id: estado.siguienteIdZona++,
        sitio_id: idSitio,
        ...datos,
      };
      estado.zonas[idSitio] = [...(estado.zonas[idSitio] || []), zona];
      await route.fulfill({ status: 201, json: zona });
    } else {
      await route.continue();
    }
  });

  await page.route(/^http:\/\/localhost:8000\/zonas\/(\d+)\/qr/, async (route) => {
    const idZona = Number(
      new URL(route.request().url()).pathname.match(/\/zonas\/(\d+)\/qr/)[1]
    );
    const metodo = route.request().method();
    if (metodo === "GET") {
      const qr = estado.qrs[idZona];
      if (qr) {
        await route.fulfill({ status: 200, json: qr });
      } else {
        await route.fulfill({
          status: 404,
          json: { detail: "No existe QR para esta zona" },
        });
      }
    } else if (metodo === "POST") {
      const qr = estado.qrs[idZona] || {
        id: estado.siguienteIdQr++,
        zona_id: idZona,
        codigo: `codigo-${idZona}`,
        url_destino: `https://quriy.app/zonas/${idZona}`,
        activo: true,
      };
      estado.qrs[idZona] = qr;
      await route.fulfill({ status: 201, json: qr });
    } else {
      await route.continue();
    }
  });

  return estado;
}
