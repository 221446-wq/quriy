import { useEffect, useState } from "react";
import { useNavigate } from "react-router-dom";
import {
  ResponsiveContainer,
  BarChart,
  Bar,
  LineChart,
  Line,
  PieChart,
  Pie,
  Cell,
  XAxis,
  YAxis,
  CartesianGrid,
  Tooltip,
  Legend,
} from "recharts";
import clienteHttp from "../services/api";

const COLORES = ["#1a6645", "#2e8b57", "#b59a00", "#2563eb", "#be185d", "#e74c3c"];

function EstadisticasPage() {
  const navegar = useNavigate();
  const [sitiosMasVisitados, setSitiosMasVisitados] = useState([]);
  const [escaneosPorDia, setEscaneosPorDia] = useState([]);
  const [escaneosPorMes, setEscaneosPorMes] = useState([]);
  const [idiomaMasUsado, setIdiomaMasUsado] = useState([]);
  const [calificacionPromedio, setCalificacionPromedio] = useState([]);
  const [cargando, setCargando] = useState(true);
  const [error, setError] = useState("");

  useEffect(() => {
    let activo = true;
    const cargarEstadisticas = async () => {
      setCargando(true);
      const resultados = await Promise.allSettled([
        clienteHttp.get("/estadisticas/sitios-mas-visitados"),
        clienteHttp.get("/estadisticas/escaneos-por-dia"),
        clienteHttp.get("/estadisticas/escaneos-por-mes"),
        clienteHttp.get("/estadisticas/idioma-mas-usado"),
        clienteHttp.get("/estadisticas/calificacion-promedio"),
      ]);
      if (!activo) return;

      const [sitios, porDia, porMes, idiomas, calificaciones] = resultados;

      if (sitios.status === "fulfilled") setSitiosMasVisitados(sitios.value.data);
      if (porDia.status === "fulfilled") setEscaneosPorDia([...porDia.value.data].reverse());
      if (porMes.status === "fulfilled") setEscaneosPorMes([...porMes.value.data].reverse());
      if (idiomas.status === "fulfilled") setIdiomaMasUsado(idiomas.value.data);
      if (calificaciones.status === "fulfilled") setCalificacionPromedio(calificaciones.value.data);

      if (resultados.every((r) => r.status === "rejected")) {
        setError("No se pudieron cargar las estadísticas.");
      }
      setCargando(false);
    };
    cargarEstadisticas();
    return () => { activo = false; };
  }, []);

  const cerrarSesion = () => {
    localStorage.removeItem("token");
    navegar("/");
  };

  const menuItems = [
    { icono: "⊞", label: "Dashboard", ruta: "/dashboard" },
    { icono: "🏛️", label: "Sitios y Zonas", ruta: "/sitios" },
    { icono: "🎧", label: "Contenido", ruta: null },
    { icono: "⬛", label: "Códigos QR", ruta: null },
    { icono: "📊", label: "Estadísticas", ruta: "/estadisticas", activo: true },
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
          <h1 style={estilos.tituloPagina}>Estadísticas</h1>
          <div style={estilos.avatar}>AM</div>
        </div>

        {error && <p style={estilos.error}>{error}</p>}

        {cargando ? (
          <p style={{ color: "#666" }}>Cargando estadísticas...</p>
        ) : (
          <div style={estilos.gridGraficos}>
            <section style={estilos.card}>
              <h3 style={estilos.cardTitulo}>Sitios más visitados</h3>
              {sitiosMasVisitados.length === 0 ? (
                <p style={estilos.sinDatos}>Sin datos suficientes.</p>
              ) : (
                <ResponsiveContainer width="100%" height={260}>
                  <BarChart data={sitiosMasVisitados}>
                    <CartesianGrid strokeDasharray="3 3" stroke="#eee" />
                    <XAxis dataKey="nombre_sitio" tick={{ fontSize: 11 }} />
                    <YAxis allowDecimals={false} tick={{ fontSize: 11 }} />
                    <Tooltip />
                    <Bar dataKey="total_visitas" name="Visitas" fill="#2e8b57" radius={[4, 4, 0, 0]} />
                  </BarChart>
                </ResponsiveContainer>
              )}
            </section>

            <section style={estilos.card}>
              <h3 style={estilos.cardTitulo}>Escaneos por día</h3>
              {escaneosPorDia.length === 0 ? (
                <p style={estilos.sinDatos}>Sin datos suficientes.</p>
              ) : (
                <ResponsiveContainer width="100%" height={260}>
                  <LineChart data={escaneosPorDia}>
                    <CartesianGrid strokeDasharray="3 3" stroke="#eee" />
                    <XAxis dataKey="fecha" tick={{ fontSize: 10 }} />
                    <YAxis allowDecimals={false} tick={{ fontSize: 11 }} />
                    <Tooltip />
                    <Line
                      type="monotone"
                      dataKey="total"
                      name="Escaneos"
                      stroke="#1a6645"
                      strokeWidth={2}
                      dot={false}
                    />
                  </LineChart>
                </ResponsiveContainer>
              )}
            </section>

            <section style={estilos.card}>
              <h3 style={estilos.cardTitulo}>Escaneos por mes</h3>
              {escaneosPorMes.length === 0 ? (
                <p style={estilos.sinDatos}>Sin datos suficientes.</p>
              ) : (
                <ResponsiveContainer width="100%" height={260}>
                  <BarChart data={escaneosPorMes}>
                    <CartesianGrid strokeDasharray="3 3" stroke="#eee" />
                    <XAxis dataKey="mes" tick={{ fontSize: 11 }} />
                    <YAxis allowDecimals={false} tick={{ fontSize: 11 }} />
                    <Tooltip />
                    <Bar dataKey="total" name="Escaneos" fill="#2563eb" radius={[4, 4, 0, 0]} />
                  </BarChart>
                </ResponsiveContainer>
              )}
            </section>

            <section style={estilos.card}>
              <h3 style={estilos.cardTitulo}>Idioma más usado</h3>
              {idiomaMasUsado.length === 0 ? (
                <p style={estilos.sinDatos}>Sin datos suficientes.</p>
              ) : (
                <ResponsiveContainer width="100%" height={260}>
                  <PieChart>
                    <Pie
                      data={idiomaMasUsado}
                      dataKey="total"
                      nameKey="idioma"
                      cx="50%"
                      cy="50%"
                      outerRadius={90}
                      label
                    >
                      {idiomaMasUsado.map((entrada, i) => (
                        <Cell key={entrada.idioma} fill={COLORES[i % COLORES.length]} />
                      ))}
                    </Pie>
                    <Tooltip />
                    <Legend />
                  </PieChart>
                </ResponsiveContainer>
              )}
            </section>

            <section style={{ ...estilos.card, gridColumn: "1 / -1" }}>
              <h3 style={estilos.cardTitulo}>Calificación promedio por zona</h3>
              {calificacionPromedio.length === 0 ? (
                <p style={estilos.sinDatos}>Sin datos suficientes.</p>
              ) : (
                <ResponsiveContainer width="100%" height={280}>
                  <BarChart data={calificacionPromedio}>
                    <CartesianGrid strokeDasharray="3 3" stroke="#eee" />
                    <XAxis dataKey="nombre_zona" tick={{ fontSize: 11 }} />
                    <YAxis domain={[0, 5]} tick={{ fontSize: 11 }} />
                    <Tooltip />
                    <Bar
                      dataKey="promedio"
                      name="Calificación promedio"
                      fill="#b59a00"
                      radius={[4, 4, 0, 0]}
                    />
                  </BarChart>
                </ResponsiveContainer>
              )}
            </section>
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
  gridGraficos: {
    display: "grid",
    gridTemplateColumns: "repeat(auto-fit, minmax(420px, 1fr))",
    gap: "20px",
  },
  card: {
    backgroundColor: "white",
    borderRadius: "10px",
    padding: "18px 20px",
    boxShadow: "0 2px 6px rgba(0,0,0,0.06)",
  },
  cardTitulo: {
    margin: "0 0 12px",
    fontSize: "14px",
    fontWeight: "700",
    color: "#1a1a1a",
  },
  sinDatos: {
    color: "#aaa",
    fontSize: "13px",
    textAlign: "center",
    padding: "40px 0",
    margin: 0,
  },
  error: { color: "#e74c3c", fontSize: "13px" },
};

export default EstadisticasPage;
