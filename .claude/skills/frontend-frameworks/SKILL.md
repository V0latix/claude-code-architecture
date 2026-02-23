---
name: frontend-frameworks
description: "Patterns React 18+, Next.js 15 App Router, gestion d'état, Server Components, Tailwind CSS et design de qualité professionnelle. Activer pour développer des interfaces, optimiser des composants React ou architecturer un frontend Next.js."
license: MIT
sources: "wshobson/agents (react-state-management, nextjs-app-router-patterns, tailwind-design-system) + anthropics/skills (frontend-design)"
---

# Frontend Frameworks

## Quand utiliser cette skill

- Développement de composants React ou pages Next.js
- Architecture d'un frontend Next.js App Router
- Gestion d'état complexe (Zustand, React Query)
- Design de composants de qualité professionnelle
- Optimisation des performances React

## 1. Next.js 15 — App Router Architecture

```typescript
// app/layout.tsx — Root Layout
import type { Metadata } from 'next'

export const metadata: Metadata = {
  title: { template: '%s | Mon App', default: 'Mon App' },
  description: 'Description du projet',
}

export default function RootLayout({ children }: { children: React.ReactNode }) {
  return (
    <html lang="fr">
      <body>
        <Providers>{children}</Providers>
      </body>
    </html>
  )
}

// app/dashboard/page.tsx — Server Component (défaut)
import { UserStats } from './_components/user-stats'
import { getUserStats } from '@/server/services/user.service'

// Pas de 'use client' = Server Component
export default async function DashboardPage() {
  const stats = await getUserStats()   // Accès direct à la BDD
  return <UserStats stats={stats} />   // Passer les données via props
}
```

## 2. React Server Components vs Client Components

```typescript
// ✅ Server Component — récupère les données, pas d'interactivité
// app/products/page.tsx
export default async function ProductsPage() {
  const products = await db.product.findMany({ take: 20 })
  return <ProductList products={products} />
}

// ✅ Client Component — état local, événements, animations
// app/products/_components/add-to-cart.tsx
'use client'

import { useState } from 'react'
import { addToCart } from '@/server/actions/cart'

export function AddToCartButton({ productId }: { productId: string }) {
  const [loading, setLoading] = useState(false)

  const handleClick = async () => {
    setLoading(true)
    await addToCart(productId)
    setLoading(false)
  }

  return (
    <button onClick={handleClick} disabled={loading}>
      {loading ? 'Ajout...' : 'Ajouter au panier'}
    </button>
  )
}
```

## 3. Server Actions

```typescript
// server/actions/product.ts
'use server'

import { revalidatePath } from 'next/cache'
import { z } from 'zod'

const CreateProductSchema = z.object({
  name: z.string().min(1).max(100),
  price: z.number().positive(),
  description: z.string().max(500),
})

export async function createProduct(formData: FormData) {
  const result = CreateProductSchema.safeParse({
    name: formData.get('name'),
    price: Number(formData.get('price')),
    description: formData.get('description'),
  })

  if (!result.success) {
    return { error: result.error.flatten() }
  }

  const product = await db.product.create({ data: result.data })
  revalidatePath('/products')
  return { success: true, product }
}
```

## 4. Gestion d'état — Zustand

```typescript
// stores/cart.store.ts
import { create } from 'zustand'
import { persist } from 'zustand/middleware'

interface CartItem { productId: string; quantity: number; price: number }

interface CartStore {
  items: CartItem[]
  total: number
  add: (item: CartItem) => void
  remove: (productId: string) => void
  clear: () => void
}

export const useCartStore = create<CartStore>()(
  persist(
    (set, get) => ({
      items: [],
      total: 0,
      add: (item) => set((state) => {
        const existing = state.items.find(i => i.productId === item.productId)
        const items = existing
          ? state.items.map(i => i.productId === item.productId
              ? { ...i, quantity: i.quantity + 1 } : i)
          : [...state.items, item]
        return { items, total: items.reduce((sum, i) => sum + i.price * i.quantity, 0) }
      }),
      remove: (productId) => set((state) => {
        const items = state.items.filter(i => i.productId !== productId)
        return { items, total: items.reduce((sum, i) => sum + i.price * i.quantity, 0) }
      }),
      clear: () => set({ items: [], total: 0 }),
    }),
    { name: 'cart-storage' }
  )
)
```

## 5. Data Fetching — TanStack Query (React Query)

```typescript
// hooks/useProducts.ts
import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query'

// Query
export const useProducts = (filters?: ProductFilters) =>
  useQuery({
    queryKey: ['products', filters],
    queryFn: () => fetchProducts(filters),
    staleTime: 5 * 60 * 1000,  // 5 minutes
  })

// Mutation avec optimistic update
export const useUpdateProduct = () => {
  const queryClient = useQueryClient()

  return useMutation({
    mutationFn: (product: UpdateProductInput) => updateProduct(product),
    onMutate: async (updated) => {
      await queryClient.cancelQueries({ queryKey: ['products'] })
      const previous = queryClient.getQueryData(['products'])
      queryClient.setQueryData(['products'], (old: Product[]) =>
        old.map(p => p.id === updated.id ? { ...p, ...updated } : p)
      )
      return { previous }
    },
    onError: (_err, _variables, context) => {
      queryClient.setQueryData(['products'], context?.previous)
    },
    onSettled: () => queryClient.invalidateQueries({ queryKey: ['products'] }),
  })
}
```

## 6. Design — Principes de qualité professionnelle

Inspiré de `anthropics/skills/frontend-design` :

```typescript
// ✅ Typographie distinctive (éviter Inter, Roboto, Arial)
// Utiliser des fonts avec caractère : Geist, Cal Sans, Satoshi, Sora, DM Sans

// ✅ Système de couleurs cohérent avec tokens CSS
// tailwind.config.ts
const config = {
  theme: {
    extend: {
      colors: {
        brand: {
          50: '#f0f9ff',
          500: '#0ea5e9',
          900: '#0c4a6e',
        },
      },
      fontFamily: {
        sans: ['var(--font-geist-sans)', 'sans-serif'],
        mono: ['var(--font-geist-mono)', 'monospace'],
      },
    },
  },
}

// ✅ Composant avec variants bien structurés
const buttonVariants = cva(
  'inline-flex items-center justify-center rounded-md text-sm font-medium transition-colors',
  {
    variants: {
      variant: {
        default: 'bg-brand-500 text-white hover:bg-brand-600',
        outline: 'border border-brand-500 text-brand-500 hover:bg-brand-50',
        ghost: 'hover:bg-gray-100',
      },
      size: {
        sm: 'h-8 px-3',
        md: 'h-10 px-4',
        lg: 'h-12 px-6 text-base',
      },
    },
    defaultVariants: { variant: 'default', size: 'md' },
  }
)
```

## 7. Performance — Patterns essentiels

```typescript
// ✅ Suspense + Streaming pour les données lentes
import { Suspense } from 'react'

export default function DashboardPage() {
  return (
    <div>
      <Suspense fallback={<StatsSkeleton />}>
        <SlowStats />   {/* Streamed indépendamment */}
      </Suspense>
      <QuickContent />  {/* Affiché immédiatement */}
    </div>
  )
}

// ✅ Dynamic import pour les composants lourds
const HeavyChart = dynamic(() => import('./heavy-chart'), {
  loading: () => <ChartSkeleton />,
  ssr: false,
})

// ✅ useMemo/useCallback pour éviter les recalculs
const sortedData = useMemo(
  () => data.sort((a, b) => b.date - a.date),
  [data]
)
```

## Anti-patterns à éviter

```typescript
// ❌ 'use client' sur des pages entières (perd le SSR)
'use client'
export default function ProductsPage() { ... }  // Toute la page devient client-side

// ✅ Extraire uniquement le bout interactif en Client Component

// ❌ Fetch dans useEffect (pattern obsolète Next.js)
useEffect(() => { fetch('/api/products').then(...) }, [])

// ✅ Server Component + props, ou React Query côté client

// ❌ State global Zustand pour les données serveur
// (doublon avec React Query, synchro difficile)

// ✅ React Query pour les données serveur, Zustand pour l'UI state

// ❌ Polices génériques
fontFamily: 'Inter, sans-serif'  // AI slop apparence

// ✅ Polices distinctives avec fallbacks
fontFamily: 'Geist, DM Sans, sans-serif'
```
