import { useEffect, useState } from "react";
import { useNavigate } from "react-router-dom";
import QRCode from "qrcode";
import clienteHttp from "../services/api";

function QrsPage() {
  const navegar = useNavigate();
  const [qrs, setQrs] = useState([]);
  const [imagenesQR, setImagenesQR] = useState({});
  const [cargando, setCargando] = useState(true);
  const [error, setError] = useState("");
  const [regenerandoId, setRegenerandoId] = useState(null);

  const cargarQrs = async () => {
    const respuesta = await clienteHttp.get("/qr/todos");
    const lista = respuesta.data;
    const imagenes = await Promise.all(
      lista.map((qr) => QRCode.toDataURL(qr.url_destino, { width: 200, margin: 2 }))
    );
    const mapaImagenes = {};
    lista.forEach((qr, i) => {
      mapaImagenes[qr.zona_id] = imagenes[i];
    });
    setQrs(lista);
    setImagenesQR(mapaImagenes);
  };

  useEffect(() => {
    let activo = true;
    const inicializar = async () => {
      setCargando(true);
      try {
        await cargarQrs();
      } catch {
        if (activo) setError("No se pudo cargar la biblioteca de códigos QR.");
      } finally {
        if (activo) setCargando(false);
      }
    };
    inicializar();
    return () => { activo = false; };
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, []);

  const regenerarQR = async (zonaId) => {
    setRegenerandoId(zonaId);
    setError("");
    try {
      await clienteHttp.post(`/zonas/${zonaId}/qr?forzar=true`);
      await cargarQrs();
    } catch {
      setError("No se pudo regenerar el código QR.");
    } finally {
      setRegenerandoId(null);
    }
  };

  const imprimirQR = (zonaId) => {
    const imagenUrl = imagenesQR[zonaId];
    if (!imagenUrl) return;
    const ventana = window.open("", "_blank", "width=400,height=500");
    if (!ventana) return;
    ventana.document.write(`
      <html>
        <head><title>Código QR</title></head>
        <body style="display:flex;align-items:center;justify-content:center;height:100vh;margin:0;">
          <img src="${imagenUrl}" style="width:300px;height:300px;" onload="window.print(); window.close();" />
        </body>
      </html>
    `);
    ventana.document.close();
  };

  const formatearFecha = (timestamp) => {
    if (!timestamp) return "—";
    return new Date(timestamp).toLocaleDateString("es-PE", {
      year: "numeric",
      month: "short",
      day: "numeric",
    });
  };

  const cerrarSesion = () => {
    localStorage.removeItem("token");
    navegar("/");
  };

  const menuItems = [
    { icono: "⊞", label: "Dashboard", ruta: "/dashboard" },
    { icono: "🏛️", label: "Sitios y Zonas", ruta: "/sitios" },
    { icono: "🎧", label: "Contenido", ruta: "/audios" },
    { icono: "⬛", label: "Códigos QR", ruta: "/qrs", activo: true },
    { icono: "📊", label: "Estadísticas", ruta: "/estadisticas" },
    { icono: "⭐", label: "Valoraciones", ruta: "/valoraciones" },
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
          <h1 style={estilos.tituloPagina}>Códigos QR</h1>
          <div style={estilos.avatar}>AM</div>
        </div>

        {error && <p style={estilos.error}>{error}</p>}

        {cargando ? (
          <p style={{ color: "#666" }}>Cargando códigos QR...</p>
        ) : (
          <div style={estilos.tablaContenedor}>
            <table style={estilos.tabla}>
              <thead>
                <tr>
                  <th style={estilos.th}>QR</th>
                  <th style={estilos.th}>SITIO</th>
                  <th style={estilos.th}>ZONA</th>
                  <th style={estilos.th}>CÓDIGO</th>
                  <th style={estilos.th}>ESTADO</th>
                  <th style={estilos.th}>CREADO</th>
                  <th style={estilos.th}>ACCIONES</th>
                </tr>
              </thead>
              <tbody>
                {qrs.length === 0 ? (
                  <tr>
                    <td
                      colSpan={7}
                      style={{ ...estilos.td, color: "#aaa", textAlign: "center" }}
                    >
                      Sin códigos QR registrados
                    </td>
                  </tr>
                ) : (
                  qrs.map((qr) => (
                    <tr key={qr.id}>
                      <td style={estilos.td}>
                        {imagenesQR[qr.zona_id] ? (
                          <img
                            src={imagenesQR[qr.zona_id]}
                            alt="Código QR"
                            style={{ width: "60px", height: "60px" }}
                          />
                        ) : (
                          "—"
                        )}
                      </td>
                      <td style={estilos.td}>{qr.nombre_sitio || "—"}</td>
                      <td style={estilos.td}>{qr.nombre_zona || "—"}</td>
                      <td style={estilos.td}>{qr.codigo}</td>
                      <td style={estilos.td}>
                        <span
                          style={{
                            ...estilos.badgeEstado,
                            ...(qr.activo ? {} : estilos.badgeInactivo),
                          }}
                        >
                          {qr.activo ? "Activo" : "Inactivo"}
                        </span>
                      </td>
                      <td style={estilos.td}>{formatearFecha(qr.creado_en)}</td>
                      <td style={estilos.td}>
                        {imagenesQR[qr.zona_id] && (
                          <a
                            href={imagenesQR[qr.zona_id]}
                            download={`qr-zona-${qr.zona_id}.png`}
                            style={estilos.botonIcono}
                          >
                            ⬇️ Descargar
                          </a>
                        )}
                        <button
                          style={{ ...estilos.botonIcono, ...estilos.botonSinFondo }}
                          onClick={() => imprimirQR(qr.zona_id)}
                        >
                          🖨️ Imprimir
                        </button>
                        <button
                          style={{ ...estilos.botonIcono, ...estilos.botonSinFondo }}
                          onClick={() => regenerarQR(qr.zona_id)}
                          disabled={regenerandoId === qr.zona_id}
                        >
                          {regenerandoId === qr.zona_id ? "Regenerando..." : "🔁 Regenerar"}
                        </button>
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
  badgeEstado: {
    backgroundColor: "#d4f5e2",
    color: "#1a6645",
    padding: "2px 8px",
    borderRadius: "10px",
    fontSize: "11px",
    fontWeight: "600",
  },
  badgeInactivo: {
    backgroundColor: "#f0f0f0",
    color: "#888",
  },
  botonIcono: {
    display: "inline-block",
    fontSize: "12px",
    color: "#1a6645",
    marginRight: "12px",
    textDecoration: "none",
  },
  botonSinFondo: {
    border: "none",
    background: "none",
    cursor: "pointer",
    fontFamily: "inherit",
  },
  error: { color: "#e74c3c", fontSize: "13px" },
};

export default QrsPage;
