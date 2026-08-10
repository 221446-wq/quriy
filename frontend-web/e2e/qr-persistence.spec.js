import { test, expect } from "@playwright/test";
import { setupApiMock, ADMIN_EMAIL, ADMIN_PASSWORD } from "./mockApi.js";

test.describe("Flujo del administrador: zonas y códigos QR", () => {
  test("crear zona, generar QR y verificar que persiste tras refrescar la página", async ({
    page,
  }) => {
    await setupApiMock(page, {
      sitiosIniciales: [
        { id: 1, nombre: "Machu Picchu", ubicacion: "Cusco", descripcion: "Ciudadela inca" },
      ],
      zonasIniciales: { 1: [] },
    });

    // Login
    await page.goto("/");
    await page.getByPlaceholder("admin@mincul.gob.pe").fill(ADMIN_EMAIL);
    await page.getByPlaceholder("••••••••••").fill(ADMIN_PASSWORD);
    await page.getByRole("button", { name: /Iniciar sesión/ }).click();
    await expect(page).toHaveURL(/\/sitios$/);

    // Ir a las zonas del sitio
    await page.goto("/zonas/1");
    await expect(page.getByText("Sin zonas registradas")).toBeVisible();

    // Crear zona
    await page.getByRole("button", { name: "+ Nueva Zona" }).click();
    await page.getByPlaceholder("Ej. Templo del Sol").fill("Templo de la Luna");
    await page
      .getByPlaceholder("Breve descripción de la zona")
      .fill("Zona ceremonial");
    await page.getByPlaceholder("Ej. -13.5170").fill("-13.1631");
    await page.getByPlaceholder("Ej. -71.9785").fill("-72.5450");
    await page.getByRole("button", { name: "Guardar" }).click();

    await expect(page.getByText("Templo de la Luna")).toBeVisible();

    // Generar el código QR de la zona
    await page.getByRole("button", { name: "⬛ Generar QR" }).click();
    await expect(page.getByAltText("Código QR")).toBeVisible();

    // Refrescar la página y verificar que el QR persiste (se recupera del backend)
    await page.reload();

    await expect(page.getByText("Templo de la Luna")).toBeVisible();
    await expect(page.getByAltText("Código QR")).toBeVisible();
    await expect(
      page.getByRole("button", { name: "⬛ Generar QR" })
    ).toHaveCount(0);
  });
});
