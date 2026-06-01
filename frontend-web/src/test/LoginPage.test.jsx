import { render, screen, fireEvent } from '@testing-library/react'
import { MemoryRouter } from 'react-router-dom'
import { describe, it, expect, vi } from 'vitest'
import LoginPage from '../pages/LoginPage'

// Simulamos el módulo de axios para que no haga llamadas reales
vi.mock('../services/api', () => ({
  default: {
    post: vi.fn(),
    interceptors: {
      request: { use: vi.fn() },
    },
  },
}))

const renderLoginPage = () =>
  render(
    <MemoryRouter>
      <LoginPage />
    </MemoryRouter>
  )

describe('LoginPage', () => {
  it('renderiza el campo de correo electrónico', () => {
    renderLoginPage()
    const campoEmail = screen.getByPlaceholderText('admin@mincul.gob.pe')
    expect(campoEmail).toBeInTheDocument()
  })

  it('renderiza el campo de contraseña', () => {
    renderLoginPage()
    const campoPassword = screen.getByPlaceholderText('••••••••••')
    expect(campoPassword).toBeInTheDocument()
  })

  it('renderiza el botón de iniciar sesión', () => {
    renderLoginPage()
    const boton = screen.getByText('Iniciar sesión →')
    expect(boton).toBeInTheDocument()
  })

  it('muestra error si se intenta ingresar con campos vacíos', async () => {
    // Simulamos que la API rechaza con error
    const clienteHttp = (await import('../services/api')).default
    clienteHttp.post.mockRejectedValueOnce(new Error('Credenciales incorrectas'))

    renderLoginPage()

    const boton = screen.getByText('Iniciar sesión →')
    fireEvent.click(boton)

    // El mensaje de error debe aparecer
    const mensajeError = await screen.findByText('Credenciales incorrectas. Intenta de nuevo.')
    expect(mensajeError).toBeInTheDocument()
  })
})