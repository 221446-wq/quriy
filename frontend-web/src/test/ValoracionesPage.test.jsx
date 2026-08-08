import { render, screen } from '@testing-library/react'
import { MemoryRouter, Route, Routes } from 'react-router-dom'
import { describe, it, expect, vi, beforeEach } from 'vitest'
import ValoracionesPage from '../pages/ValoracionesPage'

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

const renderValoracionesPage = () =>
  render(
    <MemoryRouter initialEntries={['/valoraciones']}>
      <Routes>
        <Route path="/valoraciones" element={<ValoracionesPage />} />
      </Routes>
    </MemoryRouter>
  )

describe('ValoracionesPage', () => {
  beforeEach(() => {
    vi.clearAllMocks()
  })

  it('consume GET /valoraciones y renderiza la tabla con los datos', async () => {
    const clienteHttp = (await import('../services/api')).default
    clienteHttp.get.mockResolvedValueOnce({
      data: [
        {
          id: 1,
          turista_id: 3,
          zona_id: 5,
          timestamp: '2026-08-01T10:00:00',
          calificacion: 4.5,
          comentario: 'Excelente recorrido',
          nombre_zona: 'Templo del Sol',
          nombre_sitio: 'Machu Picchu',
        },
      ],
    })

    renderValoracionesPage()

    expect(clienteHttp.get).toHaveBeenCalledWith('/valoraciones')
    expect(await screen.findByText('Excelente recorrido')).toBeInTheDocument()
    expect(screen.getByText('Templo del Sol')).toBeInTheDocument()
    expect(screen.getByText('Machu Picchu')).toBeInTheDocument()
    expect(screen.getByText(/4.5/)).toBeInTheDocument()
  })

  it('muestra mensaje cuando no hay valoraciones', async () => {
    const clienteHttp = (await import('../services/api')).default
    clienteHttp.get.mockResolvedValueOnce({ data: [] })

    renderValoracionesPage()

    expect(await screen.findByText('Sin valoraciones registradas')).toBeInTheDocument()
  })

  it('muestra un mensaje de error si la API falla', async () => {
    const clienteHttp = (await import('../services/api')).default
    clienteHttp.get.mockRejectedValueOnce(new Error('fallo de red'))

    renderValoracionesPage()

    expect(
      await screen.findByText('No se pudieron cargar las valoraciones.')
    ).toBeInTheDocument()
  })
})
