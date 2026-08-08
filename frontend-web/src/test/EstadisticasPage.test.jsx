import { render, screen } from '@testing-library/react'
import { MemoryRouter, Route, Routes } from 'react-router-dom'
import { describe, it, expect, vi, beforeEach } from 'vitest'
import EstadisticasPage from '../pages/EstadisticasPage'

const mockNavegar = vi.fn()
vi.mock('react-router-dom', async () => {
  const real = await vi.importActual('react-router-dom')
  return {
    ...real,
    useNavigate: () => mockNavegar,
  }
})

vi.mock('../services/api', () => ({
  default: {
    get: vi.fn(),
    interceptors: {
      request: { use: vi.fn() },
    },
  },
}))

// Recharts depende de ResizeObserver/medidas de layout que jsdom no provee.
// Se simulan sus componentes como contenedores simples para poder probar
// la lógica de datos/estados vacíos de la pantalla sin renderizar SVG real.
vi.mock('recharts', () => {
  const Passthrough = ({ children }) => <div>{children}</div>
  const Nulo = () => null
  return {
    ResponsiveContainer: Passthrough,
    BarChart: Passthrough,
    LineChart: Passthrough,
    PieChart: Passthrough,
    Bar: Nulo,
    Line: Nulo,
    Pie: Nulo,
    Cell: Nulo,
    XAxis: Nulo,
    YAxis: Nulo,
    CartesianGrid: Nulo,
    Tooltip: Nulo,
    Legend: Nulo,
  }
})

const renderEstadisticasPage = () =>
  render(
    <MemoryRouter initialEntries={['/estadisticas']}>
      <Routes>
        <Route path="/estadisticas" element={<EstadisticasPage />} />
      </Routes>
    </MemoryRouter>
  )

describe('EstadisticasPage', () => {
  beforeEach(() => {
    vi.clearAllMocks()
  })

  it('consume los 5 endpoints de estadísticas y renderiza los gráficos con datos', async () => {
    const clienteHttp = (await import('../services/api')).default
    clienteHttp.get.mockImplementation((url) => {
      const respuestas = {
        '/estadisticas/sitios-mas-visitados': [
          { sitio_id: 1, nombre_sitio: 'Machu Picchu', total_visitas: 40 },
        ],
        '/estadisticas/escaneos-por-dia': [
          { fecha: '2026-08-01', total: 5 },
        ],
        '/estadisticas/escaneos-por-mes': [
          { mes: '2026-08', total: 20 },
        ],
        '/estadisticas/idioma-mas-usado': [],
        '/estadisticas/calificacion-promedio': [
          { zona_id: 1, nombre_zona: 'Templo del Sol', promedio: 4.5, total_valoraciones: 10 },
        ],
      }
      return Promise.resolve({ data: respuestas[url] })
    })

    renderEstadisticasPage()

    expect(await screen.findByText('Sitios más visitados')).toBeInTheDocument()
    expect(clienteHttp.get).toHaveBeenCalledWith('/estadisticas/sitios-mas-visitados')
    expect(clienteHttp.get).toHaveBeenCalledWith('/estadisticas/escaneos-por-dia')
    expect(clienteHttp.get).toHaveBeenCalledWith('/estadisticas/escaneos-por-mes')
    expect(clienteHttp.get).toHaveBeenCalledWith('/estadisticas/idioma-mas-usado')
    expect(clienteHttp.get).toHaveBeenCalledWith('/estadisticas/calificacion-promedio')

    expect(screen.getByText('Escaneos por día')).toBeInTheDocument()
    expect(screen.getByText('Calificación promedio por zona')).toBeInTheDocument()

    // El gráfico de idioma no tiene datos, así que muestra el estado vacío
    expect(screen.getAllByText('Sin datos suficientes.').length).toBe(1)
  })

  it('muestra un mensaje de error si todos los endpoints fallan', async () => {
    const clienteHttp = (await import('../services/api')).default
    clienteHttp.get.mockRejectedValue(new Error('fallo de red'))

    renderEstadisticasPage()

    expect(
      await screen.findByText('No se pudieron cargar las estadísticas.')
    ).toBeInTheDocument()
  })
})
