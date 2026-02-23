---
name: error-handling-patterns
description: "Patterns robustes de gestion d'erreurs : Result type, error boundaries, error codes structurés, retry logic et propagation d'erreurs. Activer pour concevoir un système de gestion d'erreurs, debugging ou améliorer la résilience d'une application."
license: MIT
sources: "wshobson/agents (error-handling-patterns, debugging-strategies, error-detective)"
---

# Error Handling Patterns

## Quand utiliser cette skill

- Concevoir un système de gestion d'erreurs cohérent
- Débugger des erreurs complexes ou intermittentes
- Améliorer la résilience d'une application
- Standardiser les codes d'erreur d'une API
- Implémenter des retry et circuit breakers

## 1. Result Type — Erreurs explicites sans exceptions

```typescript
// lib/result.ts
export type Result<T, E = AppError> =
  | { ok: true; value: T }
  | { ok: false; error: E }

export const ok = <T>(value: T): Result<T, never> => ({ ok: true, value })
export const err = <E>(error: E): Result<never, E> => ({ ok: false, error })

// Usage — force la gestion d'erreurs explicite
const getUser = async (id: string): Promise<Result<User, AppError>> => {
  try {
    const user = await db.user.findUnique({ where: { id } })
    if (!user) return err(new NotFoundError(`User ${id} not found`))
    return ok(user)
  } catch (error) {
    return err(new DatabaseError('Failed to fetch user', { cause: error }))
  }
}

// L'appelant est forcé de vérifier
const result = await getUser(userId)
if (!result.ok) {
  logger.error({ error: result.error }, 'Failed to get user')
  return Response.json({ error: result.error.toJSON() }, { status: result.error.statusCode })
}
const user = result.value  // TypeScript sait que c'est un User ici
```

## 2. Hiérarchie d'erreurs structurée

```typescript
// lib/errors.ts
export abstract class AppError extends Error {
  abstract readonly statusCode: number
  abstract readonly code: string

  constructor(
    message: string,
    public readonly context?: Record<string, unknown>,
    options?: ErrorOptions
  ) {
    super(message, options)
    this.name = this.constructor.name
    Error.captureStackTrace(this, this.constructor)
  }

  toJSON() {
    return {
      error: {
        code: this.code,
        message: this.message,
        ...(process.env.NODE_ENV !== 'production' && { context: this.context }),
      },
    }
  }
}

export class ValidationError extends AppError {
  readonly statusCode = 422
  readonly code = 'VALIDATION_FAILED'
  constructor(message: string, public readonly fields?: Record<string, string[]>) {
    super(message)
  }
}

export class NotFoundError extends AppError {
  readonly statusCode = 404
  readonly code = 'NOT_FOUND'
}

export class UnauthorizedError extends AppError {
  readonly statusCode = 401
  readonly code = 'UNAUTHORIZED'
}

export class ForbiddenError extends AppError {
  readonly statusCode = 403
  readonly code = 'FORBIDDEN'
}

export class DatabaseError extends AppError {
  readonly statusCode = 500
  readonly code = 'DATABASE_ERROR'
}

export class ExternalServiceError extends AppError {
  readonly statusCode = 502
  readonly code = 'EXTERNAL_SERVICE_ERROR'
  constructor(service: string, message: string, options?: ErrorOptions) {
    super(`${service}: ${message}`, { service }, options)
  }
}
```

## 3. Error Boundary Next.js

```typescript
// app/error.tsx — Error Boundary pour les routes
'use client'

import { useEffect } from 'react'

interface ErrorBoundaryProps {
  error: Error & { digest?: string }
  reset: () => void
}

export default function ErrorBoundary({ error, reset }: ErrorBoundaryProps) {
  useEffect(() => {
    // Logger l'erreur côté client
    console.error(error)
    // Optionnel: envoyer à Sentry
    // Sentry.captureException(error)
  }, [error])

  return (
    <div className="flex flex-col items-center justify-center min-h-[400px] gap-4">
      <h2 className="text-xl font-semibold">Une erreur est survenue</h2>
      <p className="text-sm text-gray-500">
        {error.digest ? `Référence: ${error.digest}` : error.message}
      </p>
      <button onClick={reset} className="btn-primary">
        Réessayer
      </button>
    </div>
  )
}

// app/not-found.tsx — 404 global
export default function NotFound() {
  return (
    <div>
      <h1>404 — Page introuvable</h1>
      <a href="/">Retour à l'accueil</a>
    </div>
  )
}
```

## 4. Gestionnaire d'erreurs global (API)

```typescript
// middleware/error-handler.ts
import { NextRequest, NextResponse } from 'next/server'
import { ZodError } from 'zod'
import { AppError, ValidationError } from '@/lib/errors'

export const withErrorHandler = (
  handler: (req: NextRequest) => Promise<NextResponse>
) => async (req: NextRequest): Promise<NextResponse> => {
  try {
    return await handler(req)
  } catch (error) {
    // Erreurs applicatives connues
    if (error instanceof AppError) {
      return NextResponse.json(error.toJSON(), { status: error.statusCode })
    }

    // Erreurs de validation Zod
    if (error instanceof ZodError) {
      const validationError = new ValidationError('Validation failed', error.flatten().fieldErrors as any)
      return NextResponse.json(validationError.toJSON(), { status: 422 })
    }

    // Erreurs inconnues — logger et masquer les détails en prod
    logger.error({ err: error, url: req.url, method: req.method }, 'Unhandled error')

    return NextResponse.json(
      { error: { code: 'INTERNAL_ERROR', message: 'An unexpected error occurred' } },
      { status: 500 }
    )
  }
}
```

## 5. Retry avec backoff exponentiel + Jitter

```typescript
interface RetryOptions {
  maxAttempts?: number
  baseDelayMs?: number
  maxDelayMs?: number
  retryOn?: (error: unknown) => boolean
}

const withRetry = async <T>(
  fn: () => Promise<T>,
  options: RetryOptions = {}
): Promise<T> => {
  const {
    maxAttempts = 3,
    baseDelayMs = 500,
    maxDelayMs = 10_000,
    retryOn = (error) => !(error instanceof ValidationError || error instanceof UnauthorizedError),
  } = options

  let lastError: unknown

  for (let attempt = 1; attempt <= maxAttempts; attempt++) {
    try {
      return await fn()
    } catch (error) {
      lastError = error
      if (attempt === maxAttempts || !retryOn(error)) throw error

      // Backoff exponentiel avec jitter (évite les thundering herds)
      const exponential = Math.min(baseDelayMs * 2 ** (attempt - 1), maxDelayMs)
      const jitter = Math.random() * exponential * 0.2  // ±20% jitter
      await new Promise(r => setTimeout(r, exponential + jitter))

      logger.warn({ attempt, maxAttempts, error }, 'Retrying operation')
    }
  }

  throw lastError
}

// Usage
const user = await withRetry(
  () => externalApi.getUser(userId),
  { maxAttempts: 3, retryOn: (e) => e instanceof ExternalServiceError }
)
```

## 6. Debugging — Stratégie en 5 étapes

```typescript
// 1. Reproduire de façon déterministe
const reproduceWith = {
  input: { userId: 'test-123', action: 'checkout' },
  timestamp: '2024-01-15T10:30:00Z',
  environment: 'staging',
}

// 2. Ajouter du contexte aux erreurs
try {
  await processOrder(orderId)
} catch (error) {
  throw new Error(`processOrder failed for orderId=${orderId}`, { cause: error })
}

// 3. Logger avec contexte structuré
logger.error({
  err: error,
  orderId,
  userId,
  step: 'payment_processing',
  attempt: 1,
}, 'Order processing failed')

// 4. Inspecter la stack trace complète
if (error instanceof Error && error.cause) {
  console.error('Root cause:', error.cause)
}

// 5. Bisect temporel (git bisect)
// git bisect start
// git bisect bad HEAD
// git bisect good v1.2.0
```

## Anti-patterns à éviter

```typescript
// ❌ Avaler les erreurs silencieusement
try {
  await riskyOperation()
} catch (_error) {
  // Rien — le problème est masqué !
}

// ❌ throw new Error(JSON.stringify(error)) — perd la stack trace
// ✅ throw new Error('msg', { cause: originalError })

// ❌ Messages d'erreur trop génériques
throw new Error('Something went wrong')

// ✅ Messages contextuels et actionnables
throw new Error(`Failed to process order ${orderId}: payment declined`)

// ❌ Exposer les détails techniques en production
res.status(500).json({ stack: error.stack, sql: failedQuery })

// ✅ Masquer en prod, logger en interne
res.status(500).json({ error: { code: 'INTERNAL_ERROR', message: 'An error occurred' } })
```
