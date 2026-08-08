import { render, screen, fireEvent, waitFor } from '@testing-library/react'
import { MemoryRouter, Route, Routes } from 'react-router-dom'
import { describe, it, expect, vi, beforeEach } from 'vitest'
import ZonasPage from '../pages/ZonasPage'

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
    post: vi.fn(),
    interceptors: {
      request: { use: vi.fn() },
    },
  },
}))

// Simulamos qrcode para no generar imagen real en los tests
vi.mock('qrcode', () => ({
  default: {
    toDataURL: vi.fn().mockResolvedValue('data:image/png;base64,mockQR'),
  },
}))

const renderZonasPage = () =>
  render(
    <MemoryRouter initialEntries={['/zonas/1']}>
      <Routes>
        <Route path="/zonas/:idSitio" element={<ZonasPage />} />
      </Routes>
    </MemoryRouter>
  )

describe('ZonasPage', () => {
  beforeEach(() => {
    vi.clearAllMocks()
  })

  it('renderiza la tabla de zonas cuando la API retorna datos', async () => {
    const clienteHttp = (await import('../services/api')).default
    clienteHttp.get.mockResolvedValueOnce({
      data: [
        { id: 1, nombre: 'Murallas Principales', descripcion: 'Zona norte', orden: 1 },
        { id: 2, nombre: 'Trono del Inca', descripcion: 'Zona central', orden: 2 },
      ],
    })
    clienteHttp.get.mockRejectedValueOnce({ response: { status: 404 } })
    clienteHttp.get.mockRejectedValueOnce({ response: { status: 404 } })

    renderZonasPage()

    expect(await screen.findByText('Murallas Principales')).toBeInTheDocument()
    expect(await screen.findByText('Trono del Inca')).toBeInTheDocument()
  })

  it('muestra mensaje cuando no hay zonas', async () => {
    const clienteHttp = (await import('../services/api')).default
    clienteHttp.get.mockResolvedValueOnce({ data: [] })

    renderZonasPage()

    expect(await screen.findByText('Sin zonas registradas')).toBeInTheDocument()
  })

  it('botón "Generar QR" llama a la función correcta con el id de la zona', async () => {
    const clienteHttp = (await import('../services/api')).default
    clienteHttp.get.mockResolvedValueOnce({
      data: [{ id: 5, nombre: 'Templo del Sol', descripcion: 'Zona principal', orden: 1 }],
    })
    clienteHttp.get.mockRejectedValueOnce({ response: { status: 404 } })
    clienteHttp.post.mockResolvedValueOnce({
      data: { id: 1, zona_id: 5, codigo: 'abc-123', url_destino: 'https://quriy.app/zonas/5' },
    })

    renderZonasPage()

    await screen.findByText('Templo del Sol')
    fireEvent.click(screen.getByText('⬛ Generar QR'))

    await waitFor(() => {
      expect(clienteHttp.post).toHaveBeenCalledWith('/zonas/5/qr')
    })
  })

  it('muestra imagen del QR después de generarlo', async () => {
    const clienteHttp = (await import('../services/api')).default
    clienteHttp.get.mockResolvedValueOnce({
      data: [{ id: 5, nombre: 'Templo del Sol', descripcion: 'Zona principal', orden: 1 }],
    })
    clienteHttp.get.mockRejectedValueOnce({ response: { status: 404 } })
    clienteHttp.post.mockResolvedValueOnce({
      data: { id: 1, zona_id: 5, codigo: 'abc-123', url_destino: 'https://quriy.app/zonas/5' },
    })

    renderZonasPage()

    await screen.findByText('Templo del Sol')
    fireEvent.click(screen.getByText('⬛ Generar QR'))

    const imagenQR = await screen.findByAltText('Código QR')
    expect(imagenQR).toBeInTheDocument()
  })

  it('precarga el QR existente al montar la página sin mostrar error si no existe', async () => {
    const clienteHttp = (await import('../services/api')).default
    clienteHttp.get.mockResolvedValueOnce({
      data: [
        { id: 5, nombre: 'Templo del Sol', descripcion: 'Zona principal', orden: 1 },
        { id: 6, nombre: 'Plaza Mayor', descripcion: 'Zona secundaria', orden: 2 },
      ],
    })
    clienteHttp.get.mockResolvedValueOnce({
      data: { id: 1, zona_id: 5, codigo: 'abc-123', url_destino: 'https://quriy.app/zonas/5' },
    })
    clienteHttp.get.mockRejectedValueOnce({ response: { status: 404 } })

    renderZonasPage()

    await screen.findByText('Templo del Sol')

    expect(await screen.findByAltText('Código QR')).toBeInTheDocument()
    expect(clienteHttp.get).toHaveBeenCalledWith('/zonas/5/qr')
    expect(clienteHttp.get).toHaveBeenCalledWith('/zonas/6/qr')
    expect(screen.getByText('⬛ Generar QR')).toBeInTheDocument()
    expect(screen.queryByText('No se pudo generar el QR.')).not.toBeInTheDocument()
  })
})