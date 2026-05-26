// middleware.ts — en la RAÍZ del proyecto
// ─────────────────────────────────────────────────────────────
// Este archivo corre ANTES de cada request.
// Hace dos cosas:
//   1. Refresca la sesión de Supabase (mantiene al usuario logueado)
//   2. Protege rutas según el rol del usuario
// ─────────────────────────────────────────────────────────────
import { createServerClient, type CookieOptions } from '@supabase/ssr'
import { NextResponse, type NextRequest } from 'next/server'

export async function middleware(request: NextRequest) {
  let response = NextResponse.next({
    request: {
      headers: request.headers,
    },
  })

  // Creamos el cliente Supabase usando las cookies del request
  const supabase = createServerClient(
    process.env.NEXT_PUBLIC_SUPABASE_URL!,
    process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY!,
    {
      cookies: {
        get(name: string) {
          return request.cookies.get(name)?.value
        },
        set(name: string, value: string, options: CookieOptions) {
          request.cookies.set({ name, value, ...options })
          response = NextResponse.next({
            request: { headers: request.headers },
          })
          response.cookies.set({ name, value, ...options })
        },
        remove(name: string, options: CookieOptions) {
          request.cookies.set({ name, value: '', ...options })
          response = NextResponse.next({
            request: { headers: request.headers },
          })
          response.cookies.set({ name, value: '', ...options })
        },
      },
    }
  )

  // Refresca la sesión (importante para tokens que expiran)
  const { data: { user } } = await supabase.auth.getUser()

  const { pathname } = request.nextUrl

  // ── Rutas públicas (no requieren login) ──────────────────
  const publicRoutes = ['/auth/login', '/auth/register', '/']
  if (publicRoutes.includes(pathname)) {
    // Si ya está logueado y va al login, redirigir a su dashboard
    if (user && pathname.startsWith('/auth')) {
      const profile = await supabase
        .from('profiles')
        .select('role')
        .eq('id', user.id)
        .single()

      const role = profile.data?.role
      const redirectUrl = role === 'supplier'
        ? '/supplier/dashboard'
        : '/buyer/suppliers'

      return NextResponse.redirect(new URL(redirectUrl, request.url))
    }
    return response
  }

  // ── Rutas protegidas — redirigir al login si no hay sesión ──
  if (!user) {
    return NextResponse.redirect(new URL('/auth/login', request.url))
  }

  // ── Protección por rol ────────────────────────────────────
  const profile = await supabase
    .from('profiles')
    .select('role')
    .eq('id', user.id)
    .single()

  const role = profile.data?.role

  // Un buyer no puede acceder a rutas de supplier y viceversa
  if (pathname.startsWith('/supplier') && role !== 'supplier') {
    return NextResponse.redirect(new URL('/buyer/suppliers', request.url))
  }

  if (pathname.startsWith('/buyer') && role !== 'buyer') {
    return NextResponse.redirect(new URL('/supplier/dashboard', request.url))
  }

  return response
}

// El middleware corre en TODAS estas rutas
export const config = {
  matcher: [
    '/((?!_next/static|_next/image|favicon.ico|.*\\.(?:svg|png|jpg|jpeg|gif|webp)$).*)',
  ],
}
