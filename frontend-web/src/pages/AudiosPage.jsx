import { useEffect, useRef, useState } from "react";
import { useNavigate } from "react-router-dom";
import clienteHttp, { BASE_URL } from "../services/api";

const IDIOMAS = [
  { valor: "todos", label: "Todos" },
  { valor: "es", label: "Español" },
  { valor: "en", label: "English" },
];

function AudiosPage() {
  const navegar = useNavigate();
  const inputsArchivo = useRef({});

  const [audios, setAudios] = useState([]);
  const [mapaZonas, setMapaZonas] = useState({});
  const [cargando, setCargando] = useState(true);
  const [error, setError] = useState("");
  const [idiomaFiltro, setIdiomaFiltro] = useState("todos");
  const [regenerandoId, setRegenerandoId] = useState(null);

  const cargarAudios = async () => {
    const respuesta = await clienteHttp.get("/contenido/audios");
    setAudios(respuesta.data);
  };

  useEffect(() => {
    let activo = true;
    const cargarBiblioteca = async () => {
      setCargando(true);
      try {
        const [respuestaSitios, respuestaAudios] = await Promise.all([
          clienteHttp.get("/sitios"),
          clienteHttp.get("/contenido/audios"),
        ]);
        const sitios = respuestaSitios.data;
        const respuestasZonas = await Promise.all(
          sitios.map((sitio) => clienteHttp.get(`/sitios/${sitio.id}/zonas`))
        );
        if (!activo) return;

        const mapa = {};
        sitios.forEach((sitio, i) => {
          respuestasZonas[i].data.forEach((zona) => {
            mapa[zona.id] = { nombreZona: zona.nombre, nombreSitio: sitio.nombre };
          });
        });

        setMapaZonas(mapa);
        setAudios(respuestaAudios.data);
      } catch {
        if (activo) setError("No se pudo cargar la biblioteca de audios.");
      } finally {
        if (activo) setCargando(false);
      }
    };
    cargarBiblioteca();
    return () => { activo = false; };
  }, []);

  const regenerarAudio = async (id, archivo) => {
    if (!archivo) return;
    setRegenerandoId(id);
    setError("");
    try {
      const datosArchivo = new FormData();
      datosArchivo.append("archivo", archivo);
      datosArchivo.append("tipo", "audio");
      const subida = await clienteHttp.post("/contenido/upload", datosArchivo, {
        headers: { "Content-Type": undefined },
      });
      await clienteHttp.put(`/contenido/${id}`, { url_recurso: subida.data.url_recurso });
      await cargarAudios();
    } catch {
      setError("No se pudo regenerar el audio.");
    } finally {
      setRegenerandoId(null);
    }
  };

  const cerrarSesion = () => {
    localStorage.removeItem("token");
    navegar("/");
  };

  const menuItems = [
    { icono: "⊞", label: "Dashboard", ruta: "/dashboard" },
    { icono: "🏛️", label: "Sitios y Zonas", ruta: "/sitios" },
    { icono: "🎧", label: "Contenido", ruta: "/audios", activo: true },
    { icono: "⬛", label: "Códigos QR", ruta: null },
    { icono: "📊", label: "Estadísticas", ruta: "/estadisticas" },
    { icono: "⭐", label: "Valoraciones", ruta: "/valoraciones" },
  ];

  const audiosFiltrados =
    idiomaFiltro === "todos" ? audios : audios.filter((a) => a.idioma === idiomaFiltro);

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
          <h1 style={estilos.tituloPagina}>Biblioteca de audios</h1>
          <div style={estilos.avatar}>AM</div>
        </div>

        {error && <p style={estilos.error}>{error}</p>}

        {/* Tabs de idioma */}
        <div style={estilos.tabs}>
          {IDIOMAS.map((idioma) => (
            <div
              key={idioma.valor}
              style={{
                ...estilos.tab,
                ...(idiomaFiltro === idioma.valor ? estilos.tabActivo : {}),
              }}
              onClick={() => setIdiomaFiltro(idioma.valor)}
            >
              {idioma.label}
            </div>
          ))}
        </div>

        {cargando ? (
          <p style={{ color: "#666" }}>Cargando biblioteca de audios...</p>
        ) : (
          <div style={estilos.tablaContenedor}>
            <table style={estilos.tabla}>
              <thead>
                <tr>
                  <th style={estilos.th}>TÍTULO</th>
                  <th style={estilos.th}>SITIO</th>
                  <th style={estilos.th}>ZONA</th>
                  <th style={estilos.th}>IDIOMA</th>
                  <th style={estilos.th}>REPRODUCIR</th>
                  <th style={estilos.th}>ACCIONES</th>
                </tr>
              </thead>
              <tbody>
                {audiosFiltrados.length === 0 ? (
                  <tr>
                    <td
                      colSpan={6}
                      style={{ ...estilos.td, color: "#aaa", textAlign: "center" }}
                    >
                      Sin audios registrados
                    </td>
                  </tr>
                ) : (
                  audiosFiltrados.map((audio) => {
                    const zona = mapaZonas[audio.zona_id];
                    return (
                      <tr key={audio.id}>
                        <td style={estilos.td}>{audio.titulo || "Sin título"}</td>
                        <td style={estilos.td}>{zona?.nombreSitio || "—"}</td>
                        <td style={estilos.td}>{zona?.nombreZona || "—"}</td>
                        <td style={estilos.td}>
                          <span style={estilos.badgeIdioma}>
                            {audio.idioma === "en" ? "EN" : "ES"}
                          </span>
                        </td>
                        <td style={estilos.td}>
                          {audio.url_recurso ? (
                            <audio controls style={estilos.reproductor}>
                              <source src={`${BASE_URL}${audio.url_recurso}`} />
                            </audio>
                          ) : (
                            "—"
                          )}
                        </td>
                        <td style={estilos.td}>
                          {audio.url_recurso && (
                            <a
                              href={`${BASE_URL}${audio.url_recurso}`}
                              download
                              style={estilos.botonIcono}
                            >
                              ⬇️ Descargar
                            </a>
                          )}
                          <button
                            style={{ ...estilos.botonIcono, border: "none", background: "none", cursor: "pointer" }}
                            onClick={() => inputsArchivo.current[audio.id]?.click()}
                            disabled={regenerandoId === audio.id}
                          >
                            {regenerandoId === audio.id ? "Regenerando..." : "🔁 Regenerar"}
                          </button>
                          <input
                            ref={(el) => (inputsArchivo.current[audio.id] = el)}
                            type="file"
                            accept="audio/*"
                            style={{ display: "none" }}
                            onChange={(e) => regenerarAudio(audio.id, e.target.files[0])}
                          />
                        </td>
                      </tr>
                    );
                  })
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
    marginBottom: "20px",
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
  badgeIdioma: {
    backgroundColor: "#d4f5e2",
    color: "#1a6645",
    padding: "2px 8px",
    borderRadius: "10px",
    fontSize: "11px",
    fontWeight: "600",
  },
  reproductor: {
    height: "32px",
    maxWidth: "220px",
  },
  botonIcono: {
    display: "inline-block",
    fontSize: "12px",
    color: "#1a6645",
    marginRight: "12px",
    textDecoration: "none",
  },
  error: { color: "#e74c3c", fontSize: "13px", marginBottom: "12px" },
};

export default AudiosPage;
