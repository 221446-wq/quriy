import { useEffect, useState } from "react";
import { useNavigate } from "react-router-dom";
import clienteHttp from "../services/api";

const EMOJIS_SITIO = ["🏛️", "⛩️", "🗿", "🏺", "🌄", "🪆"];
const COLORES_CARD = [
  { fondo: "#d4f5e2", accent: "#2e8b57" },
  { fondo: "#fef9c3", accent: "#b59a00" },
  { fondo: "#f0f0f0", accent: "#888" },
  { fondo: "#dbeafe", accent: "#2563eb" },
  { fondo: "#fce7f3", accent: "#be185d" },
];

function SitiosPage() {
  const [sitios, setSitios] = useState([]);
  const [cargando, setCargando] = useState(true);
  const [error, setError] = useState("");
  const [sitioSeleccionado, setSitioSeleccionado] = useState(null);
  const [zonas, setZonas] = useState([]);
  const [mostrarFormulario, setMostrarFormulario] = useState(false);
  const [sitioEditando, setSitioEditando] = useState(null);
  const [nuevoSitio, setNuevoSitio] = useState({
    nombre: "",
    ubicacion: "",
    descripcion: "",
  });
  const [mostrarFormularioZona, setMostrarFormularioZona] = useState(false);
  const [zonaEditando, setZonaEditando] = useState(null);
  const [formZona, setFormZona] = useState({
    nombre: "",
    descripcion: "",
    latitud: "",
    longitud: "",
  });
  const navegar = useNavigate();

  useEffect(() => {
    let activo = true;
    const cargarSitios = async () => {
      setCargando(true);
      try {
        const respuesta = await clienteHttp.get("/sitios");
        if (activo) {
          setSitios(respuesta.data);
          if (respuesta.data.length > 0) {
            setSitioSeleccionado(respuesta.data[0]);
          }
        }
      } catch {
        if (activo) setError("No se pudieron cargar los sitios.");
      } finally {
        if (activo) setCargando(false);
      }
    };
    cargarSitios();
    return () => { activo = false; };
  }, []);

  useEffect(() => {
    if (!sitioSeleccionado) return;
    let activo = true;
    const cargarZonas = async () => {
      try {
        const respuesta = await clienteHttp.get(
          `/sitios/${sitioSeleccionado.id}/zonas`
        );
        if (activo) setZonas(respuesta.data);
      } catch {
        if (activo) setZonas([]);
      }
    };
    cargarZonas();
    return () => { activo = false; };
  }, [sitioSeleccionado]);

  const abrirNuevoSitio = () => {
    setSitioEditando(null);
    setNuevoSitio({ nombre: "", ubicacion: "", descripcion: "" });
    setMostrarFormulario(true);
  };

  const abrirEdicionSitio = (sitio, evento) => {
    evento.stopPropagation();
    setSitioEditando(sitio.id);
    setNuevoSitio({
      nombre: sitio.nombre,
      ubicacion: sitio.ubicacion || "",
      descripcion: sitio.descripcion || "",
    });
    setMostrarFormulario(true);
  };

  const cerrarFormularioSitio = () => {
    setMostrarFormulario(false);
    setSitioEditando(null);
    setNuevoSitio({ nombre: "", ubicacion: "", descripcion: "" });
  };

  const guardarSitio = async () => {
    try {
      if (sitioEditando) {
        await clienteHttp.put(`/sitios/${sitioEditando}`, nuevoSitio);
      } else {
        await clienteHttp.post("/sitios", nuevoSitio);
      }
      cerrarFormularioSitio();
      window.location.reload();
    } catch {
      setError(sitioEditando ? "No se pudo actualizar el sitio." : "No se pudo crear el sitio.");
    }
  };

  const eliminarSitio = async (id, evento) => {
    evento.stopPropagation();
    if (!window.confirm("¿Eliminar este sitio? Esta acción no se puede deshacer.")) return;
    try {
      await clienteHttp.delete(`/sitios/${id}`);
      window.location.reload();
    } catch {
      setError("No se pudo eliminar el sitio.");
    }
  };

  const abrirEdicionZona = (zona) => {
    setZonaEditando(zona.id);
    setFormZona({
      nombre: zona.nombre,
      descripcion: zona.descripcion || "",
      latitud: zona.latitud ?? "",
      longitud: zona.longitud ?? "",
    });
    setMostrarFormularioZona(true);
  };

  const cerrarFormularioZona = () => {
    setMostrarFormularioZona(false);
    setZonaEditando(null);
    setFormZona({ nombre: "", descripcion: "", latitud: "", longitud: "" });
  };

  const guardarZona = async () => {
    try {
      await clienteHttp.put(`/zonas/${zonaEditando}`, {
        ...formZona,
        latitud: formZona.latitud === "" ? null : parseFloat(formZona.latitud),
        longitud: formZona.longitud === "" ? null : parseFloat(formZona.longitud),
      });
      cerrarFormularioZona();
      window.location.reload();
    } catch {
      setError("No se pudo actualizar la zona.");
    }
  };

  const eliminarZona = async (id) => {
    if (!window.confirm("¿Eliminar esta zona? Esta acción no se puede deshacer.")) return;
    try {
      await clienteHttp.delete(`/zonas/${id}`);
      window.location.reload();
    } catch {
      setError("No se pudo eliminar la zona.");
    }
  };

  const cerrarSesion = () => {
    localStorage.removeItem("token");
    navegar("/");
  };

  const menuItems = [
    { icono: "⊞", label: "Dashboard", ruta: "/dashboard" },
    { icono: "🏛️", label: "Sitios y Zonas", ruta: null, activo: true },
    { icono: "🎧", label: "Contenido", ruta: "/audios" },
    { icono: "⬛", label: "Códigos QR", ruta: "/qrs" },
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
            style={estilos.menuItem}
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
        {/* Header */}
        <div style={estilos.header}>
          <h1 style={estilos.tituloPagina}>Sitios y Zonas</h1>
          <div style={estilos.headerDerecha}>
            <button
              style={estilos.botonNuevo}
              onClick={abrirNuevoSitio}
            >
              + Nuevo sitio
            </button>
            <div style={estilos.avatar}>AM</div>
          </div>
        </div>

        {error && <p style={estilos.error}>{error}</p>}

        {/* Modal formulario */}
        {mostrarFormulario && (
          <div style={estilos.modalOverlay}>
            <div style={estilos.modal}>
              <h3 style={{ marginTop: 0, color: "#1a6645" }}>
                {sitioEditando ? "Editar Sitio" : "Nuevo Sitio"}
              </h3>
              <label style={estilos.label}>Nombre</label>
              <input
                style={estilos.input}
                placeholder="Ej. Ollantaytambo"
                value={nuevoSitio.nombre}
                onChange={(e) =>
                  setNuevoSitio({ ...nuevoSitio, nombre: e.target.value })
                }
              />
              <label style={estilos.label}>Ubicación</label>
              <input
                style={estilos.input}
                placeholder="Ej. Valle Sagrado"
                value={nuevoSitio.ubicacion}
                onChange={(e) =>
                  setNuevoSitio({ ...nuevoSitio, ubicacion: e.target.value })
                }
              />
              <label style={estilos.label}>Descripción</label>
              <input
                style={estilos.input}
                placeholder="Breve descripción del sitio"
                value={nuevoSitio.descripcion}
                onChange={(e) =>
                  setNuevoSitio({ ...nuevoSitio, descripcion: e.target.value })
                }
              />
              <div style={{ display: "flex", gap: "10px", marginTop: "8px" }}>
                <button style={estilos.botonNuevo} onClick={guardarSitio}>
                  Guardar
                </button>
                <button
                  style={estilos.botonCancelar}
                  onClick={cerrarFormularioSitio}
                >
                  Cancelar
                </button>
              </div>
            </div>
          </div>
        )}

        {/* Modal edición de zona */}
        {mostrarFormularioZona && (
          <div style={estilos.modalOverlay}>
            <div style={estilos.modal}>
              <h3 style={{ marginTop: 0, color: "#1a6645" }}>Editar Zona</h3>
              <label style={estilos.label}>Nombre</label>
              <input
                style={estilos.input}
                placeholder="Ej. Templo del Sol"
                value={formZona.nombre}
                onChange={(e) =>
                  setFormZona({ ...formZona, nombre: e.target.value })
                }
              />
              <label style={estilos.label}>Descripción</label>
              <input
                style={estilos.input}
                placeholder="Breve descripción de la zona"
                value={formZona.descripcion}
                onChange={(e) =>
                  setFormZona({ ...formZona, descripcion: e.target.value })
                }
              />
              <label style={estilos.label}>Latitud</label>
              <input
                style={estilos.input}
                placeholder="Ej. -13.5170"
                value={formZona.latitud}
                onChange={(e) =>
                  setFormZona({ ...formZona, latitud: e.target.value })
                }
              />
              <label style={estilos.label}>Longitud</label>
              <input
                style={estilos.input}
                placeholder="Ej. -71.9785"
                value={formZona.longitud}
                onChange={(e) =>
                  setFormZona({ ...formZona, longitud: e.target.value })
                }
              />
              <div style={{ display: "flex", gap: "10px", marginTop: "8px" }}>
                <button style={estilos.botonNuevo} onClick={guardarZona}>
                  Guardar
                </button>
                <button
                  style={estilos.botonCancelar}
                  onClick={cerrarFormularioZona}
                >
                  Cancelar
                </button>
              </div>
            </div>
          </div>
        )}

        {/* Cards de sitios */}
        {cargando ? (
          <p style={{ color: "#666" }}>Cargando sitios...</p>
        ) : sitios.length === 0 ? (
          <p style={{ color: "#aaa", textAlign: "center", padding: "40px 0" }}>
            No hay sitios registrados aún.
          </p>
        ) : (
          <div style={estilos.gridCards}>
            {sitios.map((sitio, i) => {
              const color = COLORES_CARD[i % COLORES_CARD.length];
              const emoji = EMOJIS_SITIO[i % EMOJIS_SITIO.length];
              const esSeleccionado = sitioSeleccionado?.id === sitio.id;
              return (
                <div
                  key={sitio.id}
                  style={{
                    ...estilos.card,
                    outline: esSeleccionado
                      ? `2px solid ${color.accent}`
                      : "2px solid transparent",
                  }}
                  onClick={() => navegar(`/zonas/${sitio.id}`)}
                >
                  <div
                    style={{
                      ...estilos.cardImagen,
                      backgroundColor: color.fondo,
                    }}
                  >
                    <span style={{ fontSize: "36px" }}>{emoji}</span>
                    <div style={estilos.cardAcciones}>
                      <button
                        style={estilos.botonIconoCard}
                        onClick={(e) => abrirEdicionSitio(sitio, e)}
                      >
                        ✏️
                      </button>
                      <button
                        style={{ ...estilos.botonIconoCard, color: "#e74c3c" }}
                        onClick={(e) => eliminarSitio(sitio.id, e)}
                      >
                        🗑
                      </button>
                    </div>
                  </div>
                  <div style={estilos.cardInfo}>
                    <p style={estilos.cardNombre}>{sitio.nombre}</p>
                    <p style={estilos.cardUbicacion}>
                      {sitio.descripcion || sitio.ubicacion}
                    </p>
                    <div style={estilos.cardBarra}>
                      <div
                        style={{
                          ...estilos.cardBarraRelleno,
                          backgroundColor: color.accent,
                          width: `${30 + (i * 20) % 70}%`,
                        }}
                      />
                    </div>
                  </div>
                </div>
              );
            })}
          </div>
        )}

        {/* Tabla de zonas */}
        {sitioSeleccionado && (
          <div style={estilos.tablaContenedor}>
            <table style={estilos.tabla}>
              <thead>
                <tr>
                  <th style={estilos.th}>ZONA</th>
                  <th style={estilos.th}>LATITUD</th>
                  <th style={estilos.th}>LONGITUD</th>
                  <th style={estilos.th}>CONTENIDO</th>
                  <th style={estilos.th}>ACCIONES</th>
                </tr>
              </thead>
              <tbody>
                {zonas.length === 0 ? (
                  <tr>
                    <td colSpan={5} style={{ ...estilos.td, color: "#aaa", textAlign: "center" }}>
                      Sin zonas registradas
                    </td>
                  </tr>
                ) : (
                  zonas.map((zona) => (
                    <tr key={zona.id}>
                      <td style={estilos.td}>{zona.nombre}</td>
                      <td style={estilos.td}>{zona.latitud}</td>
                      <td style={estilos.td}>{zona.longitud}</td>
                      <td style={estilos.td}>
                        <span style={estilos.badgeES}>ES + EN</span>
                      </td>
                      <td style={estilos.td}>
                        <button
                          style={estilos.botonIcono}
                          onClick={() => abrirEdicionZona(zona)}
                        >
                          ✏️
                        </button>
                        <button
                          style={{ ...estilos.botonIcono, color: "#e74c3c" }}
                          onClick={() => eliminarZona(zona.id)}
                        >
                          🗑
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
    transition: "opacity 0.2s",
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
  gridCards: {
    display: "grid",
    gridTemplateColumns: "repeat(auto-fill, minmax(200px, 1fr))",
    gap: "16px",
    marginBottom: "28px",
  },
  card: {
    backgroundColor: "white",
    borderRadius: "10px",
    overflow: "hidden",
    cursor: "pointer",
    boxShadow: "0 2px 6px rgba(0,0,0,0.06)",
    transition: "transform 0.15s",
  },
  cardImagen: {
    position: "relative",
    height: "80px",
    display: "flex",
    alignItems: "center",
    justifyContent: "center",
  },
  cardAcciones: {
    position: "absolute",
    top: "4px",
    right: "4px",
    display: "flex",
    gap: "2px",
  },
  botonIconoCard: {
    background: "rgba(255,255,255,0.85)",
    border: "none",
    borderRadius: "4px",
    cursor: "pointer",
    fontSize: "12px",
    padding: "3px 5px",
    lineHeight: 1,
  },
  cardInfo: {
    padding: "10px 14px 12px",
  },
  cardNombre: {
    margin: "0 0 2px",
    fontWeight: "700",
    fontSize: "13px",
    color: "#1a1a1a",
  },
  cardUbicacion: {
    margin: "0 0 8px",
    fontSize: "11px",
    color: "#888",
  },
  cardBarra: {
    height: "3px",
    backgroundColor: "#eee",
    borderRadius: "2px",
    overflow: "hidden",
  },
  cardBarraRelleno: {
    height: "100%",
    borderRadius: "2px",
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
  badgeES: {
    backgroundColor: "#d4f5e2",
    color: "#1a6645",
    padding: "2px 8px",
    borderRadius: "10px",
    fontSize: "11px",
    fontWeight: "600",
  },
  botonIcono: {
    background: "none",
    border: "none",
    cursor: "pointer",
    fontSize: "14px",
    marginRight: "4px",
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

export default SitiosPage;