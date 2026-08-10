import axios from "axios";

const URL_ENTORNO = import.meta.env.VITE_API_URL;

// En producción la variable es obligatoria: evita compilar apuntando a localhost
if (!URL_ENTORNO && import.meta.env.PROD) {
  throw new Error(
    "VITE_API_URL no está definida. Configúrala en Vercel (Settings > Environment Variables) y vuelve a desplegar."
  );
}

// Quita la barra final para no generar URLs con doble slash
export const BASE_URL = (URL_ENTORNO || "http://localhost:8000").replace(/\/$/, "");

const clienteHttp = axios.create({
  baseURL: BASE_URL,
  timeout: 60000, // 60s: el plan gratuito de Render puede tardar en despertar
  headers: {
    "Content-Type": "application/json",
  },
});

// Agrega el JWT automáticamente a cada petición si existe
clienteHttp.interceptors.request.use((configuracion) => {
  const token = localStorage.getItem("token");
  if (token) {
    configuracion.headers.Authorization = `Bearer ${token}`;
  }
  return configuracion;
});

// Si el token expira o es inválido, limpia la sesión y regresa al login
clienteHttp.interceptors.response.use(
  (respuesta) => respuesta,
  (error) => {
    const esRutaLogin = error.config?.url?.includes("/login");

    if (error.response?.status === 401 && !esRutaLogin) {
      localStorage.removeItem("token");
      if (window.location.pathname !== "/login") {
        window.location.href = "/login";
      }
    }

    return Promise.reject(error);
  }
);

export default clienteHttp;