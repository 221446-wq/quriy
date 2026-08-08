import { useEffect, useState } from "react";
import { useParams, useNavigate } from "react-router-dom";
import clienteHttp from "../services/api";
import QRCode from "qrcode";
function ZonasPage() {
  const { idSitio } = useParams();
  const navegar = useNavigate();
  const [zonas, setZonas] = useState([]);
  const [cargando, setCargando] = useState(true);
  const [error, setError] = useState("");
  const [mostrarFormulario, setMostrarFormulario] = useState(false);
  const [nuevaZona, setNuevaZona] = useState({
    nombre: "",
    descripcion: "",
    latitud: "",
    longitud: "",
  });
  const [qrGenerado, setQrGenerado] = useState({});

  useEffect(() => {
    let activo = true;
    const precargarCodigosQR = async (listaZonas) => {
      const resultados = await Promise.allSettled(
        listaZonas.map((zona) => clienteHttp.get(`/zonas/${zona.id}/qr`))
      );
      const nuevosQR = {};
      for (let i = 0; i < listaZonas.length; i++) {
        const resultado = resultados[i];
        if (resultado.status === "fulfilled") {
          nuevosQR[listaZonas[i].id] = await QRCode.toDataURL(
            resultado.value.data.url_destino,
            { width: 200, margin: 2 }
          );
        }
        // 404 = la zona aún no tiene QR generado, se ignora sin mostrar error
      }
      if (activo && Object.keys(nuevosQR).length > 0) {
        setQrGenerado((prev) => ({ ...prev, ...nuevosQR }));
      }
    };

    const cargarZonas = async () => {
      setCargando(true);
      try {
        const respuesta = await clienteHttp.get(`/sitios/${idSitio}/zonas`);
        if (activo) {
          setZonas(respuesta.data);
          precargarCodigosQR(respuesta.data);
        }
      } catch {
        if (activo) setError("No se pudieron cargar las zonas.");
      } finally {
        if (activo) setCargando(false);
      }
    };
    cargarZonas();
    return () => { activo = false; };
  }, [idSitio]);

  const crearZona = async () => {
    try {
      await clienteHttp.post(`/sitios/${idSitio}/zonas`, {
        ...nuevaZona,
        latitud: parseFloat(nuevaZona.latitud),
        longitud: parseFloat(nuevaZona.longitud),
      });
      setMostrarFormulario(false);
      setNuevaZona({ nombre: "", descripcion: "", latitud: "", longitud: "" });
      window.location.reload();
    } catch {
      setError("No se pudo crear la zona.");
    }
  };

  const generarCodigoQR = async (idZona) => {
    try {
      const respuesta = await clienteHttp.post(`/zonas/${idZona}/qr`);
      const imagenUrl = await QRCode.toDataURL(respuesta.data.url_destino, {
        width: 200,
        margin: 2,
      });
      setQrGenerado((prev) => ({ ...prev, [idZona]: imagenUrl }));
    } catch {
      setError("No se pudo generar el QR.");
    }
  };


  const cerrarSesion = () => {
    localStorage.removeItem("token");
    navegar("/");
  };

  const menuItems = [
    { icono: "⊞", label: "Dashboard" },
    { icono: "🏛️", label: "Sitios y Zonas", activo: true },
    { icono: "🎧", label: "Contenido" },
    { icono: "⬛", label: "Códigos QR" },
    { icono: "📊", label: "Estadísticas" },
    { icono: "⭐", label: "Valoraciones" },
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
        {menuItems.slice(0, 2).map((item) => {
          const ruta = item.label === "Dashboard" ? "/dashboard" : item.label === "Sitios y Zonas" ? "/sitios" : null;
          return (
            <div
              key={item.label}
              style={{
                ...estilos.menuItem,
                ...(item.activo ? estilos.menuItemActivo : {}),
              }}
              onClick={ruta ? () => navegar(ruta) : undefined}
            >
              <span>{item.icono}</span>
              <span>{item.label}</span>
            </div>
          );
        })}

        <p style={estilos.menuSeccion}>HERRAMIENTAS</p>
        {menuItems.slice(2).map((item) => {
          const ruta =
            item.label === "Valoraciones" ? "/valoraciones" :
            item.label === "Estadísticas" ? "/estadisticas" :
            item.label === "Contenido" ? "/audios" :
            item.label === "Códigos QR" ? "/qrs" : null;
          return (
            <div
              key={item.label}
              style={estilos.menuItem}
              onClick={ruta ? () => navegar(ruta) : undefined}
            >
              <span>{item.icono}</span>
              <span>{item.label}</span>
            </div>
          );
        })}

        <div style={estilos.sidebarPie} onClick={cerrarSesion}>
          🚪 Cerrar sesión
        </div>
      </aside>

      {/* CONTENIDO PRINCIPAL */}
      <main style={estilos.main}>
        {/* Header */}
        <div style={estilos.header}>
          <div style={{ display: "flex", alignItems: "center", gap: "14px" }}>
            <button
              style={estilos.botonVolver}
              onClick={() => navegar("/sitios")}
            >
              ← Volver
            </button>
            <h1 style={estilos.tituloPagina}>Zonas del Sitio</h1>
          </div>
          <div style={estilos.headerDerecha}>
            <button
              style={estilos.botonNuevo}
              onClick={() => setMostrarFormulario(true)}
            >
              + Nueva Zona
            </button>
            <div style={estilos.avatar}>AM</div>
          </div>
        </div>

        {error && <p style={estilos.error}>{error}</p>}

        {/* Modal formulario */}
        {mostrarFormulario && (
          <div style={estilos.modalOverlay}>
            <div style={estilos.modal}>
              <h3 style={{ marginTop: 0, color: "#1a6645" }}>Nueva Zona</h3>
              <label style={estilos.label}>Nombre</label>
              <input
                style={estilos.input}
                placeholder="Ej. Templo del Sol"
                value={nuevaZona.nombre}
                onChange={(e) =>
                  setNuevaZona({ ...nuevaZona, nombre: e.target.value })
                }
              />
              <label style={estilos.label}>Descripción</label>
              <input
                style={estilos.input}
                placeholder="Breve descripción de la zona"
                value={nuevaZona.descripcion}
                onChange={(e) =>
                  setNuevaZona({ ...nuevaZona, descripcion: e.target.value })
                }
              />
              <label style={estilos.label}>Latitud</label>
              <input
                style={estilos.input}
                placeholder="Ej. -13.5170"
                value={nuevaZona.latitud}
                onChange={(e) =>
                  setNuevaZona({ ...nuevaZona, latitud: e.target.value })
                }
              />
              <label style={estilos.label}>Longitud</label>
              <input
                style={estilos.input}
                placeholder="Ej. -71.9785"
                value={nuevaZona.longitud}
                onChange={(e) =>
                  setNuevaZona({ ...nuevaZona, longitud: e.target.value })
                }
              />
              <div style={{ display: "flex", gap: "10px", marginTop: "8px" }}>
                <button style={estilos.botonNuevo} onClick={crearZona}>
                  Guardar
                </button>
                <button
                  style={estilos.botonCancelar}
                  onClick={() => setMostrarFormulario(false)}
                >
                  Cancelar
                </button>
              </div>
            </div>
          </div>
        )}

        {/* Tabla de zonas */}
        {cargando ? (
          <p style={{ color: "#666" }}>Cargando zonas...</p>
        ) : (
          <div style={estilos.tablaContenedor}>
            <table style={estilos.tabla}>
              <thead>
                <tr>
                  <th style={estilos.th}>ZONA</th>
                  <th style={estilos.th}>DESCRIPCIÓN</th>
                  <th style={estilos.th}>LATITUD</th>
                  <th style={estilos.th}>LONGITUD</th>
                  <th style={estilos.th}>CÓDIGO QR</th>
                  <th style={estilos.th}>CONTENIDO</th>
                </tr>
              </thead>
              <tbody>
                {zonas.length === 0 ? (
                  <tr>
                    <td
                      colSpan={6}
                      style={{ ...estilos.td, color: "#aaa", textAlign: "center" }}
                    >
                      Sin zonas registradas
                    </td>
                  </tr>
                ) : (
                  zonas.map((zona) => (
                    <tr key={zona.id}>
                      <td style={estilos.td}>{zona.nombre}</td>
                      <td style={estilos.td}>{zona.descripcion}</td>
                      <td style={estilos.td}>{zona.latitud}</td>
                      <td style={estilos.td}>{zona.longitud}</td>
                      <td style={estilos.td}>
                        {qrGenerado[zona.id] ? (
                          <div>
                            <img
                              src={qrGenerado[zona.id]}
                              alt="Código QR"
                              style={{ width: "70px", height: "70px" }}
                            />
                            <a
                              href={qrGenerado[zona.id]}
                              download={`qr-zona-${zona.id}.png`}
                              style={estilos.linkDescarga}
                            >
                              Descargar
                            </a>
                          </div>
                        ) : (
                          <button
                            style={estilos.botonQR}
                            onClick={() => generarCodigoQR(zona.id)}
                          >
                            ⬛ Generar QR
                          </button>
                        )}
                      </td>
                      <td style={estilos.td}>
                        <button
                          style={estilos.botonQR}
                          onClick={() =>
                            navegar(`/contenido/${zona.id}`, {
                              state: { nombreZona: zona.nombre, idSitio },
                            })
                          }
                        >
                          🎧 Contenido
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
  headerDerecha: {
    display: "flex",
    alignItems: "center",
    gap: "12px",
  },
  botonNuevo: {
    backgroundColor: "#2e8b57",
    color: "white",
    border: "none",
    padding: "8px 16px",
    borderRadius: "20px",
    cursor: "pointer",
    fontSize: "13px",
    fontWeight: "600",
  },
  botonCancelar: {
    backgroundColor: "#e74c3c",
    color: "white",
    border: "none",
    padding: "8px 16px",
    borderRadius: "20px",
    cursor: "pointer",
    fontSize: "13px",
  },
  botonVolver: {
    backgroundColor: "white",
    color: "#1a6645",
    border: "1.5px solid #1a6645",
    padding: "7px 14px",
    borderRadius: "20px",
    cursor: "pointer",
    fontSize: "13px",
    fontWeight: "600",
  },
  botonQR: {
    backgroundColor: "#1a6645",
    color: "white",
    border: "none",
    padding: "6px 12px",
    borderRadius: "6px",
    cursor: "pointer",
    fontSize: "12px",
  },
  linkDescarga: {
    display: "block",
    marginTop: "4px",
    fontSize: "11px",
    color: "#2e8b57",
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
  modalOverlay: {
    position: "fixed",
    inset: 0,
    backgroundColor: "rgba(0,0,0,0.4)",
    display: "flex",
    alignItems: "center",
    justifyContent: "center",
    zIndex: 100,
  },
  modal: {
    backgroundColor: "white",
    padding: "28px",
    borderRadius: "12px",
    width: "360px",
    boxShadow: "0 8px 24px rgba(0,0,0,0.15)",
    display: "flex",
    flexDirection: "column",
    gap: "8px",
  },
  label: {
    fontSize: "12px",
    color: "#555",
    fontWeight: "600",
    marginBottom: "2px",
  },
  input: {
    padding: "9px 12px",
    borderRadius: "6px",
    border: "1.5px solid #2e8b57",
    fontSize: "13px",
    outline: "none",
  },
  error: { color: "#e74c3c", fontSize: "13px" },
};

export default ZonasPage;