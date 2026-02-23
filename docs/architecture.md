# Architecture Technique

## Vue d'ensemble

Ce document décrit l'architecture technique du projet, les choix technologiques et les patterns utilisés.

> **Note** : Ce fichier est un template. Mettez-le à jour avec l'architecture réelle de votre projet.

## Stack technique

| Couche | Technologie | Justification |
|--------|-------------|---------------|
| Frontend | Next.js 15 (App Router) | SSR, RSC, performance |
| Language | TypeScript strict | Sécurité des types |
| Base de données | PostgreSQL + Prisma | Relationnel, ORM typé |
| Tests | Vitest + Testing Library | Rapide, DX excellent |
| Style | Tailwind CSS | Utility-first, cohérence |
| CI/CD | GitHub Actions | Intégration native GitHub |
| Hosting | Vercel / Railway | Déploiement simplifié |

## Architecture en couches

```
┌─────────────────────────────────────────────────┐
│                   Frontend (Next.js)             │
│  App Router │ Server Components │ Client Components│
├─────────────────────────────────────────────────┤
│               Server Actions / API Routes        │
├─────────────────────────────────────────────────┤
│                  Service Layer                   │
│         Business Logic │ Validation              │
├─────────────────────────────────────────────────┤
│               Repository Layer                   │
│              Prisma ORM │ Queries                │
├─────────────────────────────────────────────────┤
│                  PostgreSQL                      │
└─────────────────────────────────────────────────┘
```

## Flux de données

```
Client Request
    │
    ▼
Next.js Route Handler
    │
    ▼
Input Validation (Zod)
    │
    ▼
Authorization Check (RBAC)
    │
    ▼
Service Layer (Business Logic)
    │
    ▼
Repository (Prisma)
    │
    ▼
PostgreSQL Database
```

## Patterns architecturaux

### Result Type (Error Handling)

```typescript
type Result<T, E = Error> =
  | { ok: true; value: T }
  | { ok: false; error: E }

const ok = <T>(value: T): Result<T, never> => ({ ok: true, value })
const err = <E>(error: E): Result<never, E> => ({ ok: false, error })
```

### Repository Pattern

```typescript
interface UserRepository {
  findById(id: string): Promise<User | null>
  findByEmail(email: string): Promise<User | null>
  create(data: CreateUserInput): Promise<User>
  update(id: string, data: UpdateUserInput): Promise<User>
  delete(id: string): Promise<void>
}
```

## ADRs (Architecture Decision Records)

Les décisions d'architecture sont documentées dans `/docs/decisions/`.

Format : `NNN-[titre-en-kebab-case].md`

Exemple : `001-choice-of-database.md`
