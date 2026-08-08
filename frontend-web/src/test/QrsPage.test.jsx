import { render, screen, fireEvent, waitFor } from '@testing-library/react'
import { MemoryRouter, Route, Routes } from 'react-router-dom'
import { describe, it, expect, vi, beforeEach } from 'vitest'
import QrsPage from '../pages/QrsPage'

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

const qrDeEjemplo = {
  id: 1,
  zona_id: 5,
  codigo: 'abc-123',
  url_destino: 'https://quriy.app/zonas/5',
  activo: true,
  creado_en: '2026-08-01T10:00:00',
  nombre_zona: 'Templo del Sol',
  nombre_sitio: 'Machu Picchu',
}

const renderQrsPage = () =>
  render(
    <MemoryRouter initialEntries={['/qrs']}>
      <Routes>
        <Route path="/qrs" element={<QrsPage />} />
      </Routes>
    </MemoryRouter>
  )

describe('QrsPage', () => {
  beforeEach(() => {
    vi.clearAllMocks()
  })

  it('consume GET /qr/todos y renderiza la tabla con los datos', async () => {
    const clienteHttp = (await import('../services/api')).default
    clienteHttp.get.mockResolvedValueOnce({ data: [qrDeEjemplo] })

    renderQrsPage()

    expect(clienteHttp.get).toHaveBeenCalledWith('/qr/todos')
    expect(await screen.findByText('Templo del Sol')).toBeInTheDocument()
    expect(screen.getByText('Machu Picchu')).toBeInTheDocument()
    expect(screen.getByText('abc-123')).toBeInTheDocument()
    expect(screen.getByText('Activo')).toBeInTheDocument()
    expect(await screen.findByAltText('Código QR')).toBeInTheDocument()
  })

  it('muestra mensaje cuando no hay códigos QR', async () => {
    const clienteHttp = (await import('../services/api')).default
    clienteHttp.get.mockResolvedValueOnce({ data: [] })

    renderQrsPage()

    expect(await screen.findByText('Sin códigos QR registrados')).toBeInTheDocument()
  })

  it('el botón "Descargar" enlaza a la imagen QR generada', async () => {
    const clienteHttp = (await import('../services/api')).default
    clienteHttp.get.mockResolvedValueOnce({ data: [qrDeEjemplo] })

    renderQrsPage()

    const enlace = await screen.findByText('⬇️ Descargar')
    expect(enlace.closest('a')).toHaveAttribute('href', 'data:image/png;base64,mockQR')
    expect(enlace.closest('a')).toHaveAttribute('download', 'qr-zona-5.png')
  })

  it('"Imprimir" abre una ventana nueva con la imagen del QR', async () => {
    const clienteHttp = (await import('../services/api')).default
    clienteHttp.get.mockResolvedValueOnce({ data: [qrDeEjemplo] })

    const documentoFalso = { write: vi.fn(), close: vi.fn() }
    const ventanaFalsa = { document: documentoFalso }
    const spyOpen = vi.spyOn(window, 'open').mockReturnValue(ventanaFalsa)

    renderQrsPage()

    await screen.findByText('Templo del Sol')
    fireEvent.click(screen.getByText('🖨️ Imprimir'))

    expect(spyOpen).toHaveBeenCalled()
    expect(documentoFalso.write).toHaveBeenCalledWith(
      expect.stringContaining('data:image/png;base64,mockQR')
    )
    expect(documentoFalso.close).toHaveBeenCalled()

    spyOpen.mockRestore()
  })

  it('"Regenerar" fuerza un nuevo QR y recarga la lista', async () => {
    const clienteHttp = (await import('../services/api')).default
    clienteHttp.get.mockResolvedValueOnce({ data: [qrDeEjemplo] })
    clienteHttp.post.mockResolvedValueOnce({
      data: { ...qrDeEjemplo, codigo: 'nuevo-456' },
    })
    clienteHttp.get.mockResolvedValueOnce({
      data: [{ ...qrDeEjemplo, codigo: 'nuevo-456' }],
    })

    renderQrsPage()

    await screen.findByText('Templo del Sol')
    fireEvent.click(screen.getByText('🔁 Regenerar'))

    await waitFor(() => {
      expect(clienteHttp.post).toHaveBeenCalledWith('/zonas/5/qr?forzar=true')
    })
    expect(await screen.findByText('nuevo-456')).toBeInTheDocument()
  })
})
