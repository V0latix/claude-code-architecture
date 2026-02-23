---
name: auth-patterns
description: "Patterns d'authentification et d'autorisation : JWT, sessions, OAuth/OIDC, RBAC, MFA et middleware Next.js. Activer pour implémenter l'authentification, sécuriser des routes ou concevoir un système d'autorisation."
license: MIT
sources: "wshobson/agents (auth-implementation-patterns, security-requirement-extraction, backend-security-coder)"
---

# Auth Patterns

## Quand utiliser cette skill

- Implémenter un système d'authentification
- Protéger des routes ou des API endpoints
- Concevoir un système de permissions (RBAC)
- Intégrer OAuth/OIDC (Google, GitHub, etc.)
- Implémenter MFA ou passwordless

## 1. Auth.js (Next-Auth v5) — Setup recommandé

```typescript
// auth.ts — Configuration Auth.js
import NextAuth from 'next-auth'
import { PrismaAdapter } from '@auth/prisma-adapter'
import Google from 'next-auth/providers/google'
import Credentials from 'next-auth/providers/credentials'
import { db } from '@/server/db'
import bcrypt from 'bcryptjs'

export const { handlers, signIn, signOut, auth } = NextAuth({
  adapter: PrismaAdapter(db),
  session: { strategy: 'jwt', maxAge: 30 * 24 * 60 * 60 },  // 30 jours
  providers: [
    Google({
      clientId: process.env.GOOGLE_CLIENT_ID!,
      clientSecret: process.env.GOOGLE_CLIENT_SECRET!,
    }),
    Credentials({
      async authorize(credentials) {
        const { email, password } = credentialsSchema.parse(credentials)
        const user = await db.user.findUnique({ where: { email } })
        if (!user?.password) return null
        const valid = await bcrypt.compare(password, user.password)
        return valid ? user : null
      },
    }),
  ],
  callbacks: {
    jwt({ token, user }) {
      if (user) token.role = (user as any).role
      return token
    },
    session({ session, token }) {
      session.user.id = token.sub!
      session.user.role = token.role as string
      return session
    },
  },
  pages: { signIn: '/login', error: '/login' },
})
```

## 2. Middleware Next.js pour la protection de routes

```typescript
// middleware.ts
import { auth } from '@/auth'
import { NextResponse } from 'next/server'

export default auth((req) => {
  const { pathname } = req.nextUrl
  const isLoggedIn = !!req.auth

  // Routes publiques
  const publicRoutes = ['/', '/login', '/register', '/api/auth']
  if (publicRoutes.some(r => pathname.startsWith(r))) {
    return NextResponse.next()
  }

  // Pas connecté → rediriger vers login
  if (!isLoggedIn) {
    return NextResponse.redirect(new URL(`/login?callbackUrl=${pathname}`, req.url))
  }

  // Routes admin
  if (pathname.startsWith('/admin') && req.auth?.user?.role !== 'ADMIN') {
    return NextResponse.redirect(new URL('/unauthorized', req.url))
  }

  return NextResponse.next()
})

export const config = {
  matcher: ['/((?!_next/static|_next/image|favicon.ico).*)'],
}
```

## 3. RBAC — Role-Based Access Control

```typescript
// lib/permissions.ts
type Action = 'create' | 'read' | 'update' | 'delete'
type Resource = 'post' | 'user' | 'order' | 'product'

type Permission = `${Resource}:${Action}`

const rolePermissions: Record<string, Permission[]> = {
  ADMIN: [
    'user:create', 'user:read', 'user:update', 'user:delete',
    'post:create', 'post:read', 'post:update', 'post:delete',
    'order:read', 'order:update',
    'product:create', 'product:read', 'product:update', 'product:delete',
  ],
  MODERATOR: ['post:read', 'post:update', 'post:delete', 'user:read'],
  USER: ['post:create', 'post:read', 'order:read', 'product:read'],
}

export const hasPermission = (role: string, permission: Permission): boolean =>
  rolePermissions[role]?.includes(permission) ?? false

// Vérification dans les Server Actions
export const requirePermission = async (permission: Permission) => {
  const session = await auth()
  if (!session) throw new Error('Unauthorized')
  if (!hasPermission(session.user.role, permission)) throw new Error('Forbidden')
  return session
}

// Usage
export async function deletePost(postId: string) {
  await requirePermission('post:delete')
  // ...
}
```

## 4. JWT sécurisé (API standalone)

```typescript
import jwt from 'jsonwebtoken'
import { z } from 'zod'

const JwtPayloadSchema = z.object({
  sub: z.string(),   // userId
  role: z.string(),
  iat: z.number(),
  exp: z.number(),
})

type JwtPayload = z.infer<typeof JwtPayloadSchema>

const JWT_SECRET = process.env.JWT_SECRET
if (!JWT_SECRET || JWT_SECRET.length < 32) throw new Error('JWT_SECRET is missing or too short')

export const createTokens = (userId: string, role: string) => ({
  accessToken: jwt.sign({ sub: userId, role }, JWT_SECRET, { expiresIn: '15m' }),
  refreshToken: jwt.sign({ sub: userId, role }, JWT_SECRET, { expiresIn: '7d' }),
})

export const verifyToken = (token: string): JwtPayload => {
  const payload = jwt.verify(token, JWT_SECRET)
  return JwtPayloadSchema.parse(payload)
}

// Rotation des refresh tokens (sécurité)
export const refreshAccessToken = async (refreshToken: string) => {
  const payload = verifyToken(refreshToken)

  // Vérifier que le refresh token est en base (révocation possible)
  const stored = await db.refreshToken.findUnique({ where: { token: refreshToken } })
  if (!stored || stored.revokedAt) throw new Error('Invalid refresh token')

  // Révoquer l'ancien et créer un nouveau (token rotation)
  await db.refreshToken.update({ where: { id: stored.id }, data: { revokedAt: new Date() } })

  const { accessToken, refreshToken: newRefreshToken } = createTokens(payload.sub, payload.role)
  await db.refreshToken.create({ data: { token: newRefreshToken, userId: payload.sub } })

  return { accessToken, refreshToken: newRefreshToken }
}
```

## 5. Hachage sécurisé des mots de passe

```typescript
import bcrypt from 'bcryptjs'

const SALT_ROUNDS = 12  // Augmenter si CPU disponible

// Enregistrement
export const hashPassword = (plaintext: string): Promise<string> =>
  bcrypt.hash(plaintext, SALT_ROUNDS)

// Vérification (timing-safe)
export const verifyPassword = (plaintext: string, hash: string): Promise<boolean> =>
  bcrypt.compare(plaintext, hash)

// Validation robustesse
const PasswordSchema = z
  .string()
  .min(8, 'Minimum 8 caractères')
  .regex(/[A-Z]/, 'Au moins une majuscule')
  .regex(/[0-9]/, 'Au moins un chiffre')
  .regex(/[^A-Za-z0-9]/, 'Au moins un caractère spécial')
```

## 6. Protection CSRF + Rate Limiting

```typescript
// Rate limiting sur les routes d'auth (Upstash Redis)
import { Ratelimit } from '@upstash/ratelimit'
import { Redis } from '@upstash/redis'

const ratelimit = new Ratelimit({
  redis: Redis.fromEnv(),
  limiter: Ratelimit.slidingWindow(5, '15 m'),  // 5 tentatives par 15 min
  analytics: true,
})

// Dans le handler de login
const identifier = req.ip ?? 'anonymous'
const { success, reset } = await ratelimit.limit(`login:${identifier}`)

if (!success) {
  const retryAfter = Math.ceil((reset - Date.now()) / 1000)
  return Response.json(
    { error: 'Too many login attempts' },
    { status: 429, headers: { 'Retry-After': String(retryAfter) } }
  )
}
```

## Anti-patterns critiques

```typescript
// ❌ Stocker le mot de passe en clair ou avec MD5/SHA1
const hash = md5(password)  // JAMAIS

// ✅ bcrypt/argon2 avec salt factor élevé

// ❌ JWT secret faible ou hardcodé
const secret = 'password123'

// ✅ Secret fort (32+ chars) depuis les variables d'environnement

// ❌ Refresh tokens sans révocation possible
// Si un refresh token est volé, il est valide jusqu'à expiration

// ✅ Stocker les refresh tokens en BDD avec possibilité de révocation

// ❌ Exposer le rôle dans les logs
logger.info(`User ${email} has role ${role} logged in`)

// ✅ Logger seulement le userId
logger.info({ userId }, 'User logged in')
```
