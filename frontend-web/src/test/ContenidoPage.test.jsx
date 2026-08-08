import { render, screen, fireEvent, waitFor } from '@testing-library/react'
import { MemoryRouter, Route, Routes } from 'react-router-dom'
import { describe, it, expect, vi, beforeEach } from 'vitest'
import ContenidoPage from '../pages/ContenidoPage'

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
    put: vi.fn(),
    delete: vi.fn(),
    interceptors: {
      request: { use: vi.fn() },
    },
  },
  BASE_URL: 'http://localhost:8000',
}))

const renderContenidoPage = () =>
  render(
    <MemoryRouter initialEntries={['/contenido/5']}>
      <Routes>
        <Route path="/contenido/:idZona" element={<ContenidoPage />} />
      </Routes>
    </MemoryRouter>
  )

describe('ContenidoPage', () => {
  beforeEach(() => {
    vi.clearAllMocks()
  })

  it('renderiza el contenido en español cuando la API retorna datos', async () => {
    const clienteHttp = (await import('../services/api')).default
    clienteHttp.get.mockResolvedValueOnce({
      data: [
        { id: 1, zona_id: 5, tipo: 'texto', idioma: 'es', titulo: 'Historia', texto: 'Reseña histórica' },
      ],
    })

    renderContenidoPage()

    expect(await screen.findByText('Historia')).toBeInTheDocument()
    expect(screen.getByText('Reseña histórica')).toBeInTheDocument()
  })

  it('muestra mensaje cuando no hay contenido en el idioma activo', async () => {
    const clienteHttp = (await import('../services/api')).default
    clienteHttp.get.mockResolvedValueOnce({ data: [] })

    renderContenidoPage()

    expect(await screen.findByText('Sin contenido registrado en este idioma.')).toBeInTheDocument()
  })

  it('crea contenido de texto llamando al endpoint correcto', async () => {
    const clienteHttp = (await import('../services/api')).default
    clienteHttp.get.mockResolvedValueOnce({ data: [] })
    clienteHttp.post.mockResolvedValueOnce({
      data: { id: 2, zona_id: 5, tipo: 'texto', idioma: 'es', texto: 'Nuevo texto' },
    })
    clienteHttp.get.mockResolvedValueOnce({
      data: [{ id: 2, zona_id: 5, tipo: 'texto', idioma: 'es', texto: 'Nuevo texto' }],
    })

    renderContenidoPage()

    await screen.findByText('Sin contenido registrado en este idioma.')
    fireEvent.click(screen.getByText('+ Agregar contenido'))
    fireEvent.change(screen.getByPlaceholderText('Contenido histórico de la zona'), {
      target: { value: 'Nuevo texto' },
    })
    fireEvent.click(screen.getByText('Guardar'))

    await waitFor(() => {
      expect(clienteHttp.post).toHaveBeenCalledWith('/zonas/5/contenido', {
        tipo: 'texto',
        idioma: 'es',
        titulo: null,
        texto: 'Nuevo texto',
        url_recurso: null,
      })
    })
  })

  it('sube la imagen antes de crear el contenido cuando se adjunta un archivo', async () => {
    const clienteHttp = (await import('../services/api')).default
    clienteHttp.get.mockResolvedValueOnce({ data: [] })
    clienteHttp.post
      .mockResolvedValueOnce({ data: { url_recurso: '/static/imagenes/abc.png' } })
      .mockResolvedValueOnce({ data: { id: 3, zona_id: 5, tipo: 'imagen', idioma: 'es' } })
    clienteHttp.get.mockResolvedValueOnce({ data: [] })

    renderContenidoPage()

    await screen.findByText('Sin contenido registrado en este idioma.')
    fireEvent.click(screen.getByText('+ Agregar contenido'))
    fireEvent.change(screen.getByDisplayValue('📝 Texto'), { target: { value: 'imagen' } })

    const archivo = new File(['contenido'], 'foto.png', { type: 'image/png' })
    const inputArchivo = document.querySelector('input[type="file"]')
    fireEvent.change(inputArchivo, { target: { files: [archivo] } })

    fireEvent.click(screen.getByText('Guardar'))

    await waitFor(() => {
      expect(clienteHttp.post).toHaveBeenNthCalledWith(
        1,
        '/contenido/upload',
        expect.any(FormData),
        { headers: { 'Content-Type': undefined } }
      )
      expect(clienteHttp.post).toHaveBeenNthCalledWith(
        2,
        '/zonas/5/contenido',
        expect.objectContaining({ url_recurso: '/static/imagenes/abc.png' })
      )
    })
  })
})
