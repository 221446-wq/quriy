import { test, expect } from "@playwright/test";
import { setupApiMock, ADMIN_EMAIL, ADMIN_PASSWORD } from "./mockApi.js";

test.describe("Flujo del administrador: login y navegación de sitios", () => {
  test("iniciar sesión, crear sitio, hacer clic en la tarjeta correcta y verificar la navegación", async ({
    page,
  }) => {
    await setupApiMock(page, {
      sitiosIniciales: [
        { id: 1, nombre: "Machu Picchu", ubicacion: "Cusco", descripcion: "Ciudadela inca" },
        { id: 2, nombre: "Sacsayhuamán", ubicacion: "Cusco", descripcion: "Fortaleza inca" },
      ],
    });

    // Login
    await page.goto("/");
    await page.getByPlaceholder("admin@mincul.gob.pe").fill(ADMIN_EMAIL);
    await page.getByPlaceholder("••••••••••").fill(ADMIN_PASSWORD);
    await page.getByRole("button", { name: /Iniciar sesión/ }).click();

    await expect(page).toHaveURL(/\/sitios$/);
    await expect(page.getByText("Machu Picchu")).toBeVisible();
    await expect(page.getByText("Sacsayhuamán")).toBeVisible();

    // Crear sitio
    await page.getByRole("button", { name: "+ Nuevo sitio" }).click();
    await page.getByPlaceholder("Ej. Ollantaytambo").fill("Ollantaytambo");
    await page.getByPlaceholder("Ej. Valle Sagrado").fill("Valle Sagrado");
    await page
      .getByPlaceholder("Breve descripción del sitio")
      .fill("Fortaleza y andenes incas");
    await page.getByRole("button", { name: "Guardar" }).click();

    await expect(page.getByText("Ollantaytambo")).toBeVisible();

    // Clic en la tarjeta correcta (la del sitio recién creado) y verificar
    // que navega a las zonas de ESE sitio y no de otro
    await page.getByText("Ollantaytambo").click();

    await expect(page).toHaveURL(/\/zonas\/3$/);
    await expect(
      page.getByRole("heading", { name: "Zonas del Sitio" })
    ).toBeVisible();
  });
});
