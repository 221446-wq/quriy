import { render, screen, fireEvent, waitFor } from '@testing-library/react'
import { MemoryRouter, Route, Routes } from 'react-router-dom'
import { describe, it, expect, vi, beforeEach } from 'vitest'
import AudiosPage from '../pages/AudiosPage'

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
    interceptors: {
      request: { use: vi.fn() },
    },
  },
  BASE_URL: 'http://localhost:8000',
}))

const respuestasPorDefecto = (clienteHttp) => {
  clienteHttp.get.mockImplementation((url) => {
    if (url === '/sitios') {
      return Promise.resolve({ data: [{ id: 1, nombre: 'Machu Picchu' }] })
    }
    if (url === '/sitios/1/zonas') {
      return Promise.resolve({ data: [{ id: 5, nombre: 'Templo del Sol' }] })
    }
    if (url === '/contenido/audios') {
      return Promise.resolve({
        data: [
          {
            id: 10,
            zona_id: 5,
            tipo: 'audio',
            idioma: 'es',
            titulo: 'Historia del templo',
            url_recurso: '/static/audio/historia.mp3',
          },
        ],
      })
    }
    return Promise.reject(new Error(`URL no mockeada: ${url}`))
  })
}

const renderAudiosPage = () =>
  render(
    <MemoryRouter initialEntries={['/audios']}>
      <Routes>
        <Route path="/audios" element={<AudiosPage />} />
      </Routes>
    </MemoryRouter>
  )

describe('AudiosPage', () => {
  beforeEach(() => {
    vi.clearAllMocks()
  })

  it('carga la biblioteca cruzando /contenido/audios con los nombres de sitio y zona', async () => {
    const clienteHttp = (await import('../services/api')).default
    respuestasPorDefecto(clienteHttp)

    renderAudiosPage()

    expect(await screen.findByText('Historia del templo')).toBeInTheDocument()
    expect(screen.getByText('Machu Picchu')).toBeInTheDocument()
    expect(screen.getByText('Templo del Sol')).toBeInTheDocument()
    expect(clienteHttp.get).toHaveBeenCalledWith('/contenido/audios')
  })

  it('muestra mensaje cuando no hay audios registrados', async () => {
    const clienteHttp = (await import('../services/api')).default
    clienteHttp.get.mockImplementation((url) => {
      if (url === '/sitios') return Promise.resolve({ data: [] })
      if (url === '/contenido/audios') return Promise.resolve({ data: [] })
      return Promise.reject(new Error(`URL no mockeada: ${url}`))
    })

    renderAudiosPage()

    expect(await screen.findByText('Sin audios registrados')).toBeInTheDocument()
  })

  it('el botón "Descargar" enlaza al recurso del audio', async () => {
    const clienteHttp = (await import('../services/api')).default
    respuestasPorDefecto(clienteHttp)

    renderAudiosPage()

    const enlace = await screen.findByText('⬇️ Descargar')
    expect(enlace.closest('a')).toHaveAttribute(
      'href',
      'http://localhost:8000/static/audio/historia.mp3'
    )
  })

  it('"Regenerar" sube el nuevo archivo y actualiza el contenido', async () => {
    const clienteHttp = (await import('../services/api')).default
    respuestasPorDefecto(clienteHttp)
    clienteHttp.post.mockResolvedValueOnce({
      data: { url_recurso: '/static/audio/nuevo.mp3' },
    })
    clienteHttp.put.mockResolvedValueOnce({ data: {} })

    const { container } = renderAudiosPage()

    await screen.findByText('Historia del templo')

    const inputArchivo = container.querySelector('input[type="file"]')
    const archivo = new File(['contenido'], 'nuevo.mp3', { type: 'audio/mpeg' })
    fireEvent.change(inputArchivo, { target: { files: [archivo] } })

    await waitFor(() => {
      expect(clienteHttp.post).toHaveBeenCalledWith(
        '/contenido/upload',
        expect.any(FormData),
        expect.objectContaining({ headers: { 'Content-Type': undefined } })
      )
    })
    expect(clienteHttp.put).toHaveBeenCalledWith('/contenido/10', {
      url_recurso: '/static/audio/nuevo.mp3',
    })
  })
})
