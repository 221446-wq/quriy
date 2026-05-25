import { useState } from "react";
import { useNavigate } from "react-router-dom";
import clienteHttp from "../services/api";

function LoginPage() {
  const [email, setEmail] = useState("");
  const [password, setPassword] = useState("");
  const [recordar, setRecordar] = useState(false);
  const [error, setError] = useState("");
  const [cargando, setCargando] = useState(false);
  const navegar = useNavigate();

  const manejarLogin = async () => {
    setCargando(true);
    setError("");
    try {
      const respuesta = await clienteHttp.post("/auth/login", {
        email,
        password,
      });
      localStorage.setItem("token", respuesta.data.access_token);
      navegar("/sitios");
    } catch {
      setError("Credenciales incorrectas. Intenta de nuevo.");
    } finally {
      setCargando(false);
    }
  };

  return (
    <div style={estilos.contenedor}>
      <div style={estilos.tarjeta}>

        {/* Encabezado con ícono */}
        <div style={estilos.encabezado}>
          <div style={estilos.iconoContenedor}>
            🏛️
          </div>
          <div>
            <h1 style={estilos.titulo}>Cusco Arqueológico Digital</h1>
            <p style={estilos.subtitulo}>Panel de administración</p>
          </div>
        </div>

        <hr style={estilos.separador} />

        {/* Campos */}
        <label style={estilos.label}>Correo institucional</label>
        <input
          style={estilos.input}
          type="email"
          placeholder="admin@mincul.gob.pe"
          value={email}
          onChange={(e) => setEmail(e.target.value)}
        />

        <label style={estilos.label}>Contraseña</label>
        <input
          style={estilos.input}
          type="password"
          placeholder="••••••••••"
          value={password}
          onChange={(e) => setPassword(e.target.value)}
        />

        {/* Recordar sesión y olvidé contraseña */}
        <div style={estilos.filaOpciones}>
          <label style={estilos.checkboxLabel}>
            <input
              type="checkbox"
              checked={recordar}
              onChange={(e) => setRecordar(e.target.checked)}
              style={{ accentColor: "#2e8b57", marginRight: "6px" }}
            />
            Recordar sesión
          </label>
          <span style={estilos.linkOlvide}>¿Olvidaste tu contraseña?</span>
        </div>

        {error && <p style={estilos.error}>{error}</p>}

        {/* Botón */}
        <button
          style={{
            ...estilos.boton,
            opacity: cargando ? 0.7 : 1,
          }}
          onClick={manejarLogin}
          disabled={cargando}
        >
          {cargando ? "Ingresando..." : "Iniciar sesión →"}
        </button>

        {/* Pie */}
        <p style={estilos.pie}>
          Solo para administradores autorizados · Ministerio de Cultura
        </p>
      </div>
    </div>
  );
}

const estilos = {
  contenedor: {
    display: "flex",
    justifyContent: "center",
    alignItems: "center",
    height: "100vh",
    backgroundColor: "#1a6645",
  },
  tarjeta: {
    backgroundColor: "white",
    padding: "40px",
    borderRadius: "16px",
    boxShadow: "0 8px 24px rgba(0,0,0,0.2)",
    display: "flex",
    flexDirection: "column",
    width: "380px",
  },
  encabezado: {
    display: "flex",
    alignItems: "center",
    gap: "14px",
    marginBottom: "20px",
  },
  iconoContenedor: {
    backgroundColor: "#e8f5e9",
    borderRadius: "10px",
    width: "48px",
    height: "48px",
    display: "flex",
    alignItems: "center",
    justifyContent: "center",
    fontSize: "24px",
    flexShrink: 0,
  },
  titulo: {
    margin: 0,
    fontSize: "16px",
    fontWeight: "700",
    color: "#1a1a1a",
  },
  subtitulo: {
    margin: 0,
    fontSize: "13px",
    color: "#7f8c8d",
  },
  separador: {
    border: "none",
    borderTop: "1px solid #eee",
    marginBottom: "20px",
  },
  label: {
    fontSize: "13px",
    color: "#444",
    marginBottom: "6px",
    fontWeight: "500",
  },
  input: {
    padding: "10px 14px",
    marginBottom: "16px",
    borderRadius: "8px",
    border: "1.5px solid #2e8b57",
    fontSize: "14px",
    outline: "none",
    color: "#333",
  },
  filaOpciones: {
    display: "flex",
    justifyContent: "space-between",
    alignItems: "center",
    marginBottom: "20px",
  },
  checkboxLabel: {
    fontSize: "13px",
    color: "#444",
    display: "flex",
    alignItems: "center",
    cursor: "pointer",
  },
  linkOlvide: {
    fontSize: "13px",
    color: "#2e8b57",
    cursor: "pointer",
  },
  boton: {
    padding: "12px",
    backgroundColor: "#2e8b57",
    color: "white",
    border: "none",
    borderRadius: "8px",
    cursor: "pointer",
    fontSize: "15px",
    fontWeight: "600",
    marginBottom: "16px",
  },
  pie: {
    textAlign: "center",
    fontSize: "11px",
    color: "#aaa",
    margin: 0,
  },
  error: {
    color: "#e74c3c",
    fontSize: "13px",
    marginBottom: "8px",
  },
};

export default LoginPage;