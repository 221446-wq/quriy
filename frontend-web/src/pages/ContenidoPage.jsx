import { useEffect, useState } from "react";
import { useParams, useNavigate, useLocation } from "react-router-dom";
import clienteHttp, { BASE_URL } from "../services/api";

const IDIOMAS = [
  { valor: "es", label: "Español" },
  { valor: "en", label: "English" },
];

const TIPOS = [
  { valor: "texto", label: "Texto", icono: "📝" },
  { valor: "imagen", label: "Imagen", icono: "🖼️" },
  { valor: "audio", label: "Audio", icono: "🎧" },
];

const FORMULARIO_VACIO = {
  id: null,
  tipo: "texto",
  idioma: "es",
  titulo: "",
  texto: "",
  archivo: null,
  urlRecursoExistente: "",
};

function ContenidoPage() {
  const { idZona } = useParams();
  const navegar = useNavigate();
  const location = useLocation();
  const nombreZona = location.state?.nombreZona;
  const idSitio = location.state?.idSitio;

  const [contenidos, setContenidos] = useState([]);
  const [cargando, setCargando] = useState(true);
  const [error, setError] = useState("");
  const [guardando, setGuardando] = useState(false);
  const [idiomaActivo, setIdiomaActivo] = useState("es");
  const [mostrarFormulario, setMostrarFormulario] = useState(false);
  const [formulario, setFormulario] = useState(FORMULARIO_VACIO);

  const cargarContenidos = async () => {
    setCargando(true);
    try {
      const respuesta = await clienteHttp.get(`/zonas/${idZona}/contenido`);
      setContenidos(respuesta.data);
    } catch {
      setError("No se pudo cargar el contenido de la zona.");
    } finally {
      setCargando(false);
    }
  };

  useEffect(() => {
    cargarContenidos();
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [idZona]);

  const abrirNuevo = () => {
    setFormulario({ ...FORMULARIO_VACIO, idioma: idiomaActivo });
    setError("");
    setMostrarFormulario(true);
  };

  const abrirEdicion = (item) => {
    setFormulario({
      id: item.id,
      tipo: item.tipo,
      idioma: item.idioma,
      titulo: item.titulo || "",
      texto: item.texto || "",
      archivo: null,
      urlRecursoExistente: item.url_recurso || "",
    });
    setError("");
    setMostrarFormulario(true);
  };

  const cerrarFormulario = () => {
    setMostrarFormulario(false);
    setFormulario(FORMULARIO_VACIO);
  };

  const guardarContenido = async () => {
    if (formulario.tipo === "texto" && !formulario.texto.trim()) {
      setError("El contenido de texto no puede estar vacío.");
      return;
    }
    if (formulario.tipo !== "texto" && !formulario.archivo && !formulario.urlRecursoExistente) {
      setError("Debes seleccionar un archivo.");
      return;
    }

    setGuardando(true);
    setError("");
    try {
      let urlRecurso = formulario.urlRecursoExistente || null;

      if (formulario.archivo) {
        const datosArchivo = new FormData();
        datosArchivo.append("archivo", formulario.archivo);
        datosArchivo.append("tipo", formulario.tipo);
        const subida = await clienteHttp.post("/contenido/upload", datosArchivo, {
          headers: { "Content-Type": undefined },
        });
        urlRecurso = subida.data.url_recurso;
      }

      const payload = {
        tipo: formulario.tipo,
        idioma: formulario.idioma,
        titulo: formulario.titulo || null,
        texto: formulario.texto || null,
        url_recurso: urlRecurso,
      };

      if (formulario.id) {
        await clienteHttp.put(`/contenido/${formulario.id}`, payload);
      } else {
        await clienteHttp.post(`/zonas/${idZona}/contenido`, payload);
      }

      cerrarFormulario();
      await cargarContenidos();
    } catch {
      setError("No se pudo guardar el contenido.");
    } finally {
      setGuardando(false);
    }
  };

  const eliminarContenido = async (id) => {
    try {
      await clienteHttp.delete(`/contenido/${id}`);
      await cargarContenidos();
    } catch {
      setError("No se pudo eliminar el contenido.");
    }
  };

  const cerrarSesion = () => {
    localStorage.removeItem("token");
    navegar("/");
  };

  const menuItems = [
    { icono: "⊞", label: "Dashboard" },
    { icono: "🏛️", label: "Sitios y Zonas" },
    { icono: "🎧", label: "Contenido", activo: true },
    { icono: "⬛", label: "Códigos QR" },
    { icono: "📊", label: "Estadísticas" },
    { icono: "⭐", label: "Valoraciones" },
  ];

  const contenidosDelIdioma = contenidos.filter((c) => c.idioma === idiomaActivo);

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
          const ruta = item.label === "Valoraciones" ? "/valoraciones" : item.label === "Estadísticas" ? "/estadisticas" : null;
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

        <div style={estilos.sidebarPie} onClick={cerrarSesion}>
          🚪 Cerrar sesión
        </div>
      </aside>

      {/* CONTENIDO PRINCIPAL */}
      <main style={estilos.main}>
        <div style={estilos.header}>
          <div style={{ display: "flex", alignItems: "center", gap: "14px" }}>
            <button
              style={estilos.botonVolver}
              onClick={() => navegar(idSitio ? `/zonas/${idSitio}` : -1)}
            >
              ← Volver
            </button>
            <h1 style={estilos.tituloPagina}>
              Contenido {nombreZona ? `— ${nombreZona}` : `— Zona #${idZona}`}
            </h1>
          </div>
          <button style={estilos.botonNuevo} onClick={abrirNuevo}>
            + Agregar contenido
          </button>
        </div>

        {error && <p style={estilos.error}>{error}</p>}

        {/* Tabs de idioma */}
        <div style={estilos.tabs}>
          {IDIOMAS.map((idioma) => (
            <div
              key={idioma.valor}
              style={{
                ...estilos.tab,
                ...(idiomaActivo === idioma.valor ? estilos.tabActivo : {}),
              }}
              onClick={() => setIdiomaActivo(idioma.valor)}
            >
              {idioma.label}
            </div>
          ))}
        </div>

        {/* Modal formulario */}
        {mostrarFormulario && (
          <div style={estilos.modalOverlay}>
            <div style={estilos.modal}>
              <h3 style={{ marginTop: 0, color: "#1a6645" }}>
                {formulario.id ? "Editar contenido" : "Nuevo contenido"}
              </h3>

              <label style={estilos.label}>Tipo</label>
              <select
                style={estilos.input}
                value={formulario.tipo}
                onChange={(e) => setFormulario({ ...formulario, tipo: e.target.value, archivo: null })}
              >
                {TIPOS.map((tipo) => (
                  <option key={tipo.valor} value={tipo.valor}>
                    {tipo.icono} {tipo.label}
                  </option>
                ))}
              </select>

              <label style={estilos.label}>Idioma</label>
              <select
                style={estilos.input}
                value={formulario.idioma}
                onChange={(e) => setFormulario({ ...formulario, idioma: e.target.value })}
              >
                {IDIOMAS.map((idioma) => (
                  <option key={idioma.valor} value={idioma.valor}>
                    {idioma.label}
                  </option>
                ))}
              </select>

              <label style={estilos.label}>Título</label>
              <input
                style={estilos.input}
                placeholder="Ej. Historia de la zona"
                value={formulario.titulo}
                onChange={(e) => setFormulario({ ...formulario, titulo: e.target.value })}
              />

              {formulario.tipo === "texto" ? (
                <>
                  <label style={estilos.label}>Texto</label>
                  <textarea
                    style={{ ...estilos.input, minHeight: "100px", resize: "vertical" }}
                    placeholder="Contenido histórico de la zona"
                    value={formulario.texto}
                    onChange={(e) => setFormulario({ ...formulario, texto: e.target.value })}
                  />
                </>
              ) : (
                <>
                  <label style={estilos.label}>
                    Archivo {formulario.tipo === "imagen" ? "de imagen" : "de audio"}
                  </label>
                  <input
                    style={estilos.input}
                    type="file"
                    accept={formulario.tipo === "imagen" ? "image/*" : "audio/*"}
                    onChange={(e) =>
                      setFormulario({ ...formulario, archivo: e.target.files[0] || null })
                    }
                  />
                  {formulario.urlRecursoExistente && !formulario.archivo && (
                    <p style={estilos.archivoActual}>
                      Archivo actual: {formulario.urlRecursoExistente.split("/").pop()}
                    </p>
                  )}
                  <label style={estilos.label}>Descripción / transcripción (opcional)</label>
                  <textarea
                    style={{ ...estilos.input, minHeight: "70px", resize: "vertical" }}
                    placeholder="Texto complementario"
                    value={formulario.texto}
                    onChange={(e) => setFormulario({ ...formulario, texto: e.target.value })}
                  />
                </>
              )}

              <div style={{ display: "flex", gap: "10px", marginTop: "8px" }}>
                <button style={estilos.botonNuevo} onClick={guardarContenido} disabled={guardando}>
                  {guardando ? "Guardando..." : "Guardar"}
                </button>
                <button style={estilos.botonCancelar} onClick={cerrarFormulario}>
                  Cancelar
                </button>
              </div>
            </div>
          </div>
        )}

        {/* Lista de contenido */}
        {cargando ? (
          <p style={{ color: "#666" }}>Cargando contenido...</p>
        ) : contenidosDelIdioma.length === 0 ? (
          <p style={{ color: "#aaa", textAlign: "center", padding: "40px 0" }}>
            Sin contenido registrado en este idioma.
          </p>
        ) : (
          <div style={estilos.gridCards}>
            {contenidosDelIdioma.map((item) => {
              const tipoInfo = TIPOS.find((t) => t.valor === item.tipo) || TIPOS[0];
              return (
                <div key={item.id} style={estilos.card}>
                  <div style={estilos.cardHeader}>
                    <span>{tipoInfo.icono} {tipoInfo.label}</span>
                    <div>
                      <button style={estilos.botonIcono} onClick={() => abrirEdicion(item)}>
                        ✏️
                      </button>
                      <button
                        style={{ ...estilos.botonIcono, color: "#e74c3c" }}
                        onClick={() => eliminarContenido(item.id)}
                      >
                        🗑
                      </button>
                    </div>
                  </div>
                  {item.titulo && <p style={estilos.cardTitulo}>{item.titulo}</p>}

                  {item.tipo === "texto" && <p style={estilos.cardTexto}>{item.texto}</p>}

                  {item.tipo === "imagen" && item.url_recurso && (
                    <img
                      src={`${BASE_URL}${item.url_recurso}`}
                      alt={item.titulo || "Imagen de contenido"}
                      style={estilos.cardImagen}
                    />
                  )}

                  {item.tipo === "audio" && item.url_recurso && (
                    <audio controls style={{ width: "100%" }}>
                      <source src={`${BASE_URL}${item.url_recurso}`} />
                    </audio>
                  )}

                  {item.tipo !== "texto" && item.texto && (
                    <p style={estilos.cardTexto}>{item.texto}</p>
                  )}
                </div>
              );
            })}
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
    marginBottom: "20px",
  },
  tituloPagina: {
    margin: 0,
    fontSize: "22px",
    color: "#1a1a1a",
    fontWeight: "700",
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
  botonIcono: {
    background: "none",
    border: "none",
    cursor: "pointer",
    fontSize: "14px",
    marginLeft: "6px",
  },
  tabs: {
    display: "flex",
    gap: "8px",
    marginBottom: "20px",
  },
  tab: {
    padding: "6px 16px",
    borderRadius: "20px",
    fontSize: "13px",
    fontWeight: "600",
    color: "#666",
    backgroundColor: "white",
    cursor: "pointer",
    border: "1.5px solid #eee",
  },
  tabActivo: {
    backgroundColor: "#1a6645",
    color: "white",
    border: "1.5px solid #1a6645",
  },
  gridCards: {
    display: "grid",
    gridTemplateColumns: "repeat(auto-fill, minmax(260px, 1fr))",
    gap: "16px",
  },
  card: {
    backgroundColor: "white",
    borderRadius: "10px",
    padding: "14px 16px",
    boxShadow: "0 2px 6px rgba(0,0,0,0.06)",
  },
  cardHeader: {
    display: "flex",
    justifyContent: "space-between",
    alignItems: "center",
    fontSize: "12px",
    fontWeight: "600",
    color: "#1a6645",
    marginBottom: "8px",
  },
  cardTitulo: {
    margin: "0 0 6px",
    fontWeight: "700",
    fontSize: "14px",
    color: "#1a1a1a",
  },
  cardTexto: {
    margin: 0,
    fontSize: "13px",
    color: "#555",
    lineHeight: 1.4,
  },
  cardImagen: {
    width: "100%",
    maxHeight: "160px",
    objectFit: "cover",
    borderRadius: "6px",
  },
  archivoActual: {
    fontSize: "11px",
    color: "#888",
    margin: "-4px 0 8px",
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
    width: "380px",
    maxHeight: "85vh",
    overflowY: "auto",
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
    fontFamily: "inherit",
  },
  error: { color: "#e74c3c", fontSize: "13px", marginBottom: "12px" },
};

export default ContenidoPage;
