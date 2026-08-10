import { useEffect, useState } from "react";
import { useNavigate } from "react-router-dom";
import clienteHttp from "../services/api";

const TARJETAS = [
  { clave: "total_sitios", icono: "🏛️", label: "Sitios activos", color: "#2e8b57" },
  { clave: "total_zonas", icono: "📍", label: "Zonas", color: "#2563eb" },
  { clave: "total_usuarios", icono: "👥", label: "Usuarios activos", color: "#b59a00" },
  { clave: "total_visitas", icono: "👣", label: "Visitas registradas", color: "#be185d" },
  { clave: "total_qrs", icono: "⬛", label: "Códigos QR", color: "#555" },
];

function DashboardPage() {
  const navegar = useNavigate();
  const [resumen, setResumen] = useState(null);
  const [cargando, setCargando] = useState(true);
  const [error, setError] = useState("");
  const [generandoMasivo, setGenerandoMasivo] = useState(false);
  const [progreso, setProgreso] = useState({ actual: 0, total: 0, zonaActual: "" });
  const [logResultados, setLogResultados] = useState([]);

  useEffect(() => {
    let activo = true;
    const cargarResumen = async () => {
      setCargando(true);
      try {
        const respuesta = await clienteHttp.get("/estadisticas/resumen");
        if (activo) setResumen(respuesta.data);
      } catch {
        if (activo) setError("No se pudo cargar el resumen del sistema.");
      } finally {
        if (activo) setCargando(false);
      }
    };
    cargarResumen();
    return () => { activo = false; };
  }, []);

  const cerrarSesion = () => {
    localStorage.removeItem("token");
    navegar("/");
  };

  const generarTodasLasAudioguias = async () => {
    setGenerandoMasivo(true);
    setLogResultados([]);
    setProgreso({ actual: 0, total: 0, zonaActual: "" });

    try {
      const respuestaSitios = await clienteHttp.get("/sitios");
      const sitios = respuestaSitios.data;

      // Reunir todas las zonas de todos los sitios en una sola lista
      let todasLasZonas = [];
      for (const sitio of sitios) {
        const respuestaZonas = await clienteHttp.get(`/sitios/${sitio.id}/zonas`);
        todasLasZonas = todasLasZonas.concat(
          respuestaZonas.data.map((z) => ({ ...z, nombreSitio: sitio.nombre }))
        );
      }

      setProgreso({ actual: 0, total: todasLasZonas.length, zonaActual: "" });

      for (let i = 0; i < todasLasZonas.length; i++) {
        const zona = todasLasZonas[i];
        setProgreso({
          actual: i + 1,
          total: todasLasZonas.length,
          zonaActual: `${zona.nombreSitio} — ${zona.nombre}`,
        });
        try {
          await clienteHttp.post(`/zonas/${zona.id}/generar-audioguia-completa`);
          setLogResultados((prev) => [
            ...prev,
            `✅ ${zona.nombreSitio} — ${zona.nombre}`,
          ]);
        } catch (err) {
          const detalle = err?.response?.data?.detail || "error desconocido";
          setLogResultados((prev) => [
            ...prev,
            `⚠️ ${zona.nombreSitio} — ${zona.nombre}: ${detalle}`,
          ]);
        }
      }
    } catch {
      setLogResultados((prev) => [
        ...prev,
        "❌ No se pudo obtener la lista de sitios y zonas.",
      ]);
    } finally {
      setGenerandoMasivo(false);
    }
  };

  const menuItems = [
    { icono: "⊞", label: "Dashboard", ruta: "/dashboard", activo: true },
    { icono: "🏛️", label: "Sitios y Zonas", ruta: "/sitios" },
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
          <h1 style={estilos.tituloPagina}>Dashboard</h1>
          <div style={estilos.avatar}>AM</div>
        </div>

        {error && <p style={estilos.error}>{error}</p>}

        {cargando ? (
          <p style={{ color: "#666" }}>Cargando resumen...</p>
        ) : (
          <div style={estilos.gridTarjetas}>
            {TARJETAS.map((tarjeta) => (
              <div key={tarjeta.clave} style={estilos.tarjeta}>
                <div
                  style={{
                    ...estilos.tarjetaIcono,
                    backgroundColor: `${tarjeta.color}1a`,
                    color: tarjeta.color,
                  }}
                >
                  {tarjeta.icono}
                </div>
                <div>
                  <p style={estilos.tarjetaTotal}>
                    {resumen?.[tarjeta.clave] ?? 0}
                  </p>
                  <p style={estilos.tarjetaLabel}>{tarjeta.label}</p>
                </div>
              </div>
            ))}
          </div>
        )}

        {/* Panel de generación masiva de audioguías con IA */}
        <div
          style={{
            marginTop: "28px",
            padding: "20px",
            backgroundColor: "#fff",
            borderRadius: "10px",
            border: "1px solid #e5e5e5",
          }}
        >
          <h3 style={{ marginTop: 0, color: "#1a6645" }}>
            🪄 Generar todas las audioguías con IA
          </h3>
          <p style={{ color: "#555", fontSize: "14px", marginBottom: "14px" }}>
            Recorre automáticamente todos los sitios y zonas. Para cada zona
            que ya tenga un guion en español, genera su audio, lo traduce al
            inglés y genera también el audio en inglés. No duplica lo que ya
            exista, así que puedes ejecutarlo varias veces sin problema.
          </p>

          <button
            style={{
              padding: "10px 18px",
              backgroundColor: "#1a6645",
              color: "#fff",
              border: "none",
              borderRadius: "6px",
              cursor: generandoMasivo ? "not-allowed" : "pointer",
              opacity: generandoMasivo ? 0.7 : 1,
              fontWeight: "bold",
            }}
            onClick={generarTodasLasAudioguias}
            disabled={generandoMasivo}
          >
            {generandoMasivo
              ? `Generando... (${progreso.actual}/${progreso.total})`
              : "Generar todas las audioguías"}
          </button>

          {generandoMasivo && progreso.total > 0 && (
            <div style={{ marginTop: "14px" }}>
              <div
                style={{
                  height: "8px",
                  backgroundColor: "#eee",
                  borderRadius: "4px",
                  overflow: "hidden",
                }}
              >
                <div
                  style={{
                    height: "100%",
                    width: `${(progreso.actual / progreso.total) * 100}%`,
                    backgroundColor: "#1a6645",
                    transition: "width 0.3s ease",
                  }}
                />
              </div>
              <p style={{ fontSize: "13px", color: "#666", marginTop: "6px" }}>
                Procesando: {progreso.zonaActual}
              </p>
            </div>
          )}

          {logResultados.length > 0 && (
            <div
              style={{
                marginTop: "14px",
                maxHeight: "220px",
                overflowY: "auto",
                fontSize: "13px",
                backgroundColor: "#fafafa",
                border: "1px solid #eee",
                borderRadius: "6px",
                padding: "10px",
              }}
            >
              {logResultados.map((linea, indice) => (
                <div key={indice} style={{ padding: "2px 0" }}>
                  {linea}
                </div>
              ))}
            </div>
          )}
        </div>
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
  gridTarjetas: {
    display: "grid",
    gridTemplateColumns: "repeat(auto-fill, minmax(200px, 1fr))",
    gap: "16px",
  },
  tarjeta: {
    backgroundColor: "white",
    borderRadius: "10px",
    padding: "18px",
    boxShadow: "0 2px 6px rgba(0,0,0,0.06)",
    display: "flex",
    alignItems: "center",
    gap: "14px",
  },
  tarjetaIcono: {
    width: "44px",
    height: "44px",
    borderRadius: "10px",
    display: "flex",
    alignItems: "center",
    justifyContent: "center",
    fontSize: "20px",
    flexShrink: 0,
  },
  tarjetaTotal: {
    margin: 0,
    fontSize: "24px",
    fontWeight: "700",
    color: "#1a1a1a",
  },
  tarjetaLabel: {
    margin: 0,
    fontSize: "12px",
    color: "#888",
  },
  error: { color: "#e74c3c", fontSize: "13px" },
};

export default DashboardPage;