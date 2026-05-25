import axios from "axios";

const BASE_URL = import.meta.env.VITE_API_URL || "http://localhost:8000";

const clienteHttp = axios.create({
  baseURL: BASE_URL,
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

export default clienteHttp;