import { BrowserRouter, Routes, Route, Navigate } from "react-router-dom";
import LoginPage from "./pages/LoginPage";
import SitiosPage from "./pages/SitiosPage";
import ZonasPage from "./pages/ZonasPage";
import ContenidoPage from "./pages/ContenidoPage";
import ValoracionesPage from "./pages/ValoracionesPage";
import DashboardPage from "./pages/DashboardPage";
import EstadisticasPage from "./pages/EstadisticasPage";
import AudiosPage from "./pages/AudiosPage";
import QrsPage from "./pages/QrsPage";

function RutaProtegida({ children }) {
  const token = localStorage.getItem("token");
  if (!token) return <Navigate to="/" />;
  return children;
}

function App() {
  return (
    <BrowserRouter>
      <Routes>
        <Route path="/" element={<LoginPage />} />
        <Route
          path="/sitios"
          element={
            <RutaProtegida>
              <SitiosPage />
            </RutaProtegida>
          }
        />
        <Route
          path="/zonas/:idSitio"
          element={
            <RutaProtegida>
              <ZonasPage />
            </RutaProtegida>
          }
        />
        <Route
          path="/contenido/:idZona"
          element={
            <RutaProtegida>
              <ContenidoPage />
            </RutaProtegida>
          }
        />
        <Route
          path="/valoraciones"
          element={
            <RutaProtegida>
              <ValoracionesPage />
            </RutaProtegida>
          }
        />
        <Route
          path="/dashboard"
          element={
            <RutaProtegida>
              <DashboardPage />
            </RutaProtegida>
          }
        />
        <Route
          path="/estadisticas"
          element={
            <RutaProtegida>
              <EstadisticasPage />
            </RutaProtegida>
          }
        />
        <Route
          path="/audios"
          element={
            <RutaProtegida>
              <AudiosPage />
            </RutaProtegida>
          }
        />
        <Route
          path="/qrs"
          element={
            <RutaProtegida>
              <QrsPage />
            </RutaProtegida>
          }
        />
      </Routes>
    </BrowserRouter>
  );
}

export default App;