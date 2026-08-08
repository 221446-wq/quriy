import { useEffect, useState } from "react";
import { useNavigate } from "react-router-dom";
import clienteHttp from "../services/api";

function ValoracionesPage() {
  const navegar = useNavigate();
  const [valoraciones, setValoraciones] = useState([]);
  const [cargando, setCargando] = useState(true);
  const [error, setError] = useState("");

  useEffect(() => {
    let activo = true;
    const cargarValoraciones = async () => {
      setCargando(true);
      try {
        const respuesta = await clienteHttp.get("/valoraciones");
        if (activo) setValoraciones(respuesta.data);
      } catch {
        if (activo) setError("No se pudieron cargar las valoraciones.");
      } finally {
        if (activo) setCargando(false);
      }
    };
    cargarValoraciones();
    return () => { activo = false; };
  }, []);

  const cerrarSesion = () => {
    localStorage.removeItem("token");
    navegar("/");
  };

  const formatearFecha = (timestamp) => {
    if (!timestamp) return "—";
    return new Date(timestamp).toLocaleDateString("es-PE", {
      year: "numeric",
      month: "short",
      day: "numeric",
    });
  };

  const menuItems = [
    { icono: "⊞", label: "Dashboard", ruta: "/dashboard" },
    { icono: "🏛️", label: "Sitios y Zonas", ruta: "/sitios" },
    { icono: "🎧", label: "Contenido", ruta: null },
    { icono: "⬛", label: "Códigos QR", ruta: null },
    { icono: "📊", label: "Estadísticas", ruta: "/estadisticas" },
    { icono: "⭐", label: "Valoraciones", ruta: "/valoraciones", activo: true },
  ];

  return (
    <div style={estilos.app}>
      {/* SIDEBAR */}
      <aside style={estilos.sidebar}>
        <div style={estilos.sidebarLogo}>
          <span style={estilos.logoTexto}>Cusco Arqueológico</span>
          <span style={estilos.logoSub}>Panel de Administración</span>
        </div>

        <p style={estilos.menuSeccion}>PRINCIPAL</p>
        {menuItems.slice(0, 2).map((item) => (
          <div
            key={item.label}
            style={{
              ...estilos.menuItem,
              ...(item.activo ? estilos.menuItemActivo : {}),
            }}
            onClick={item.ruta ? () => navegar(item.ruta) : undefined}
          >
            <span>{item.icono}</span>
            <span>{item.label}</span>
          </div>
        ))}

        <p style={estilos.menuSeccion}>HERRAMIENTAS</p>
        {menuItems.slice(2).map((item) => (
          <div
            key={item.label}
            style={{
              ...estilos.menuItem,
              ...(item.activo ? estilos.menuItemActivo : {}),
            }}
            onClick={item.ruta ? () => navegar(item.ruta) : undefined}
          >
            <span>{item.icono}</span>
            <span>{item.label}</span>
          </div>
        ))}

        <div style={estilos.sidebarPie} onClick={cerrarSesion}>
          🚪 Cerrar sesión
        </div>
      </aside>

      {/* CONTENIDO PRINCIPAL */}
      <main style={estilos.main}>
        <div style={estilos.header}>
          <h1 style={estilos.tituloPagina}>Valoraciones</h1>
          <div style={estilos.avatar}>AM</div>
        </div>

        {error && <p style={estilos.error}>{error}</p>}

        {cargando ? (
          <p style={{ color: "#666" }}>Cargando valoraciones...</p>
        ) : (
          <div style={estilos.tablaContenedor}>
            <table style={estilos.tabla}>
              <thead>
                <tr>
                  <th style={estilos.th}>CALIFICACIÓN</th>
                  <th style={estilos.th}>COMENTARIO</th>
                  <th style={estilos.th}>FECHA</th>
                  <th style={estilos.th}>SITIO</th>
                  <th style={estilos.th}>ZONA</th>
                </tr>
              </thead>
              <tbody>
                {valoraciones.length === 0 ? (
                  <tr>
                    <td
                      colSpan={5}
                      style={{ ...estilos.td, color: "#aaa", textAlign: "center" }}
                    >
                      Sin valoraciones registradas
                    </td>
                  </tr>
                ) : (
                  valoraciones.map((valoracion) => (
                    <tr key={valoracion.id}>
                      <td style={estilos.td}>
                        <span style={estilos.badgeCalificacion}>
                          ⭐ {valoracion.calificacion ?? "—"}
                        </span>
                      </td>
                      <td style={estilos.td}>
                        {valoracion.comentario || "—"}
                      </td>
                      <td style={estilos.td}>
                        {formatearFecha(valoracion.timestamp)}
                      </td>
                      <td style={estilos.td}>
                        {valoracion.nombre_sitio || "—"}
                      </td>
                      <td style={estilos.td}>
                        {valoracion.nombre_zona || "—"}
                      </td>
                    </tr>
                  ))
                )}
              </tbody>
            </table>
          </div>
        )}
      </main>
    </div>
  );
}

const estilos = {
  app: {
    display: "flex",
    height: "100vh",
    fontFamily: "Georgia, serif",
    backgroundColor: "#f5f5f5",
  },
  sidebar: {
    width: "180px",
    backgroundColor: "#1a6645",
    color: "white",
    display: "flex",
    flexDirection: "column",
    padding: "20px 0",
    flexShrink: 0,
  },
  sidebarLogo: {
    padding: "0 16px 20px",
    borderBottom: "1px solid rgba(255,255,255,0.15)",
    marginBottom: "12px",
  },
  logoTexto: {
    display: "block",
    fontWeight: "700",
    fontSize: "13px",
    lineHeight: "1.3",
  },
  logoSub: {
    display: "block",
    fontSize: "10px",
    opacity: 0.7,
    marginTop: "2px",
  },
  menuSeccion: {
    fontSize: "9px",
    opacity: 0.5,
    letterSpacing: "1px",
    padding: "12px 16px 4px",
    margin: 0,
  },
  menuItem: {
    display: "flex",
    alignItems: "center",
    gap: "8px",
    padding: "8px 16px",
    fontSize: "13px",
    cursor: "pointer",
    opacity: 0.75,
  },
  menuItemActivo: {
    backgroundColor: "rgba(255,255,255,0.15)",
    opacity: 1,
    fontWeight: "600",
    borderLeft: "3px solid white",
  },
  sidebarPie: {
    marginTop: "auto",
    padding: "16px",
    fontSize: "12px",
    opacity: 0.6,
    cursor: "pointer",
  },
  main: {
    flex: 1,
    padding: "28px 32px",
    overflowY: "auto",
  },
  header: {
    display: "flex",
    justifyContent: "space-between",
    alignItems: "center",
    marginBottom: "24px",
  },
  tituloPagina: {
    margin: 0,
    fontSize: "22px",
    color: "#1a1a1a",
    fontWeight: "700",
  },
  avatar: {
    width: "34px",
    height: "34px",
    borderRadius: "50%",
    backgroundColor: "#2e8b57",
    color: "white",
    display: "flex",
    alignItems: "center",
    justifyContent: "center",
    fontSize: "12px",
    fontWeight: "700",
  },
  tablaContenedor: {
    backgroundColor: "white",
    borderRadius: "10px",
    overflow: "hidden",
    boxShadow: "0 2px 6px rgba(0,0,0,0.06)",
  },
  tabla: {
    width: "100%",
    borderCollapse: "collapse",
  },
  th: {
    padding: "10px 16px",
    textAlign: "left",
    fontSize: "11px",
    color: "#999",
    letterSpacing: "0.5px",
    borderBottom: "1px solid #eee",
  },
  td: {
    padding: "12px 16px",
    fontSize: "13px",
    borderBottom: "1px solid #f5f5f5",
    color: "#333",
  },
  badgeCalificacion: {
    backgroundColor: "#fef9c3",
    color: "#b59a00",
    padding: "2px 8px",
    borderRadius: "10px",
    fontSize: "12px",
    fontWeight: "600",
  },
  error: { color: "#e74c3c", fontSize: "13px" },
};

export default ValoracionesPage;
