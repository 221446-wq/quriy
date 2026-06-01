import { render, screen, fireEvent, waitFor } from '@testing-library/react'
import { MemoryRouter } from 'react-router-dom'
import { describe, it, expect, vi, beforeEach } from 'vitest'
import SitiosPage from '../pages/SitiosPage'

// Simulamos react-router-dom para controlar la navegación
const mockNavegar = vi.fn()
vi.mock('react-router-dom', async () => {
  const real = await vi.importActual('react-router-dom')
  return {
    ...real,
    useNavigate: () => mockNavegar,
  }
})

// Simulamos el clienteHttp
vi.mock('../services/api', () => ({
  default: {
    get: vi.fn(),
    post: vi.fn(),
    interceptors: {
      request: { use: vi.fn() },
    },
  },
}))

const renderSitiosPage = () =>
  render(
    <MemoryRouter>
      <SitiosPage />
    </MemoryRouter>
  )

describe('SitiosPage', () => {
  beforeEach(() => {
    vi.clearAllMocks()
  })

  it('renderiza tabla con sitios cuando la API retorna datos', async () => {
    const clienteHttp = (await import('../services/api')).default
    clienteHttp.get.mockResolvedValueOnce({
      data: [
        { id: 1, nombre: 'Sacsayhuamán', ubicacion: 'Cusco', descripcion: 'Fortaleza inca', activo: true },
        { id: 2, nombre: 'Qorikancha', ubicacion: 'Cusco', descripcion: 'Templo del Sol', activo: true },
      ],
    })

    renderSitiosPage()

    // Esperar que carguen los sitios
    const sitio1 = await screen.findByText('Sacsayhuamán')
    const sitio2 = await screen.findByText('Qorikancha')

    expect(sitio1).toBeInTheDocument()
    expect(sitio2).toBeInTheDocument()
  })

  it('muestra mensaje cuando no hay sitios disponibles', async () => {
    const clienteHttp = (await import('../services/api')).default
    clienteHttp.get.mockResolvedValueOnce({ data: [] })

    renderSitiosPage()

    const mensaje = await screen.findByText('No hay sitios registrados aún.')
    expect(mensaje).toBeInTheDocument()
  })

  it('muestra el botón de agregar sitio', async () => {
    const clienteHttp = (await import('../services/api')).default
    clienteHttp.get.mockResolvedValueOnce({ data: [] })

    renderSitiosPage()

    await waitFor(() => {
      const boton = screen.getByText('+ Nuevo sitio')
      expect(boton).toBeInTheDocument()
    })
  })

  it('abre el formulario al hacer click en nuevo sitio', async () => {
    const clienteHttp = (await import('../services/api')).default
    clienteHttp.get.mockResolvedValueOnce({ data: [] })

    renderSitiosPage()

    await waitFor(() => screen.getByText('+ Nuevo sitio'))
    fireEvent.click(screen.getByText('+ Nuevo sitio'))

    const tituloModal = screen.getByText('Nuevo Sitio')
    expect(tituloModal).toBeInTheDocument()
  })
})