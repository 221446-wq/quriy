import { render, screen } from '@testing-library/react'
import { MemoryRouter, Route, Routes } from 'react-router-dom'
import { describe, it, expect, vi, beforeEach } from 'vitest'
import DashboardPage from '../pages/DashboardPage'

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

const renderDashboardPage = () =>
  render(
    <MemoryRouter initialEntries={['/dashboard']}>
      <Routes>
        <Route path="/dashboard" element={<DashboardPage />} />
      </Routes>
    </MemoryRouter>
  )

describe('DashboardPage', () => {
  beforeEach(() => {
    vi.clearAllMocks()
  })

  it('consume GET /estadisticas/resumen y muestra las tarjetas de totales', async () => {
    const clienteHttp = (await import('../services/api')).default
    clienteHttp.get.mockResolvedValueOnce({
      data: {
        total_sitios: 4,
        total_zonas: 12,
        total_usuarios: 8,
        total_visitas: 150,
        total_qrs: 12,
      },
    })

    renderDashboardPage()

    expect(clienteHttp.get).toHaveBeenCalledWith('/estadisticas/resumen')
    expect(await screen.findByText('Sitios activos')).toBeInTheDocument()
    expect(screen.getByText('4')).toBeInTheDocument()
    expect(screen.getByText('150')).toBeInTheDocument()
    expect(screen.getByText('Usuarios activos')).toBeInTheDocument()
  })

  it('muestra un mensaje de error si la API falla', async () => {
    const clienteHttp = (await import('../services/api')).default
    clienteHttp.get.mockRejectedValueOnce(new Error('fallo de red'))

    renderDashboardPage()

    expect(
      await screen.findByText('No se pudo cargar el resumen del sistema.')
    ).toBeInTheDocument()
  })
})
