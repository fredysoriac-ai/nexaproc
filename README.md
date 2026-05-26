# NEXAPROC — Marketplace B2B Industrial

Marketplace para conectar proveedores industriales con empresas de minería y construcción en Perú.

---

## Stack tecnológico

| Capa | Tecnología | Para qué sirve |
|---|---|---|
| Frontend | Next.js 14 (App Router) | Páginas y componentes React |
| Estilos | Tailwind CSS | Diseño rápido y consistente |
| Backend / DB | Supabase | Base de datos, auth, storage |
| Fetching | TanStack Query | Cache y lazy loading de datos |
| Formularios | React Hook Form + Zod | Validación de inputs |
| Deploy | Vercel + Supabase Cloud | Hosting gratuito |

---

## Guía de instalación paso a paso

### Paso 0 — Requisitos previos

Necesitas tener instalado:
- **Node.js 18+** → descargar en https://nodejs.org
- **Git** → descargar en https://git-scm.com

Verificar en tu terminal:
```bash
node --version   # debe mostrar v18 o superior
npm --version    # debe mostrar 9 o superior
```

---

### Paso 1 — Crear proyecto en Supabase (gratis)

1. Ve a https://app.supabase.com y crea una cuenta
2. Haz click en **"New project"**
3. Pon nombre: `nexaproc`, selecciona región **São Paulo** (más cercana a Perú)
4. Pon una contraseña para la DB (guárdala)
5. Espera ~2 minutos mientras se crea

6. Ve a **Settings > API** y copia:
   - `Project URL` → esto es tu `SUPABASE_URL`
   - `anon public` key → esto es tu `ANON_KEY`

7. Ve a **SQL Editor > New query** y pega todo el contenido del archivo `supabase-schema.sql`, luego haz click en **Run**

---

### Paso 2 — Instalar el proyecto localmente

```bash
# 1. Entrar a la carpeta del proyecto
cd nexaproc

# 2. Instalar dependencias (puede tomar 1-2 minutos)
npm install

# 3. Crear el archivo de variables de entorno
cp .env.example .env.local

# 4. Editar .env.local con tus claves de Supabase
# Abre el archivo y reemplaza los valores de ejemplo
```

---

### Paso 3 — Correr en desarrollo

```bash
npm run dev
```

Abre tu navegador en: **http://localhost:3000**

---

### Paso 4 — Deploy en Vercel (gratis)

1. Sube tu código a GitHub (nuevo repositorio)
2. Ve a https://vercel.com y conecta tu cuenta de GitHub
3. Importa el repositorio `nexaproc`
4. En **Environment Variables**, agrega:
   - `NEXT_PUBLIC_SUPABASE_URL`
   - `NEXT_PUBLIC_SUPABASE_ANON_KEY`
   - `SUPABASE_SERVICE_ROLE_KEY`
5. Click en **Deploy**

Tu app estará en: `https://nexaproc.vercel.app`

---

## Estructura de carpetas

```
nexaproc/
├── app/                     # Páginas (Next.js App Router)
│   ├── auth/
│   │   ├── login/           # Página de login
│   │   └── register/        # Página de registro
│   ├── buyer/
│   │   ├── suppliers/       # Catálogo de proveedores
│   │   ├── rfq/             # Gestión de RFQs
│   │   └── quotes/          # Cotizaciones recibidas
│   └── supplier/
│       ├── dashboard/       # Panel del proveedor
│       ├── catalog/         # Gestión de productos
│       └── rfqs/            # RFQs disponibles
│
├── components/
│   ├── shared/              # Componentes usados en toda la app
│   ├── buyer/               # Componentes solo para compradores
│   └── supplier/            # Componentes solo para proveedores
│
├── lib/
│   └── supabase/            # Clientes de Supabase (browser + server)
│
├── types/
│   └── database.ts          # Tipos TypeScript de toda la app
│
├── middleware.ts             # Protección de rutas por rol
├── supabase-schema.sql      # Schema completo de la base de datos
└── .env.example             # Template de variables de entorno
```

---

## Módulos incluidos

| Módulo | Estado | Archivos |
|---|---|---|
| Auth (login/registro/roles) | ✅ Completo | `app/auth/` |
| Catálogo con lazy loading | ✅ Completo | `app/buyer/suppliers/` |
| Sistema RFQ | ✅ Completo | `app/buyer/rfq/` |
| Cotizaciones + PO | ✅ Completo | `app/buyer/quotes/` |
| Dashboard proveedor | ✅ Completo | `app/supplier/` |
| Subida de imágenes | ✅ Completo | `components/supplier/` |

---

## Costos (referencia)

| Servicio | Tier gratuito | Límite |
|---|---|---|
| Supabase | Free forever | 500MB DB, 1GB storage, 50k usuarios |
| Vercel | Free forever | 100GB bandwidth, builds ilimitados |
| **Total** | **$0/mes** | Suficiente para MVP |
