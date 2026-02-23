---
description: "Initialisation complète d'un nouveau projet. Scaffold architecture, tech stack, CI/CD, observabilité, sécurité de base et documentation. Produit un projet prêt pour le développement feature."
allowed-tools: Bash, Read, Write, Edit, Grep, Glob, Task
---

# New Project Setup

Initialisation du projet : **$ARGUMENTS**

`$ARGUMENTS` doit décrire le projet : type (API, webapp, CLI, service...), domaine métier, contraintes.
Exemple : "SaaS B2B de gestion de factures — Next.js + Prisma + Auth" ou "API REST de notifications — Node.js microservice"

## Phase 0 — Qualification du projet

Identifier :**
- **Type** : Webapp full-stack / API REST / CLI / Microservice / Mobile / LLM app
- **Stack** : Frontend ? (Next.js / React / Vue) + Backend ? (Node/Python/Go) + DB ? (Postgres/MongoDB/Redis)
- **Audience** : B2B / B2C / Internal tool — impact sur auth et compliance
- **Scale attendu** : MVP / Startup / Enterprise — impact sur l'architecture

## Phase 1 — Architecture (lancer avec Task)

### `architect agent`
**Skills activées : api-design, database-patterns, docker-k8s, architecture-diagrams, observability-patterns, auth-patterns, async-patterns**

Concevoir l'architecture de `$ARGUMENTS` :
1. **Diagramme C4** (Context + Container) en Mermaid
2. **Schéma de données** initial avec les entités core
3. **Stratégie d'authentification** selon le type de projet
4. **Endpoints API** core (spec OpenAPI simplifiée)
5. **Structure de répertoires** recommandée
6. **ADR #001** : choix tech stack (créer dans `/docs/decisions/001-tech-stack.md`)

### `product-manager agent`
**Skills activées : architecture-diagrams, prompt-engineering**

- Identifier les fonctionnalités core (MVP scope)
- Définir les 3 user stories fondamentales
- Établir les critères d'acceptation

### `security-auditor agent`
**Skills activées : security-scanning, auth-patterns, error-handling-patterns, api-design**

Définir les exigences de sécurité dès le départ :
- Niveau de conformité requis (GDPR / SOC2 / HIPAA ?)
- Surface d'attaque initiale
- Secrets management strategy (Vault / AWS SSM / .env strict)
- Headers de sécurité requis

## Phase 2 — Scaffold du projet

```bash
# Vérifier si un projet existe déjà
ls -la 2>/dev/null | head -20

# Dépendances système disponibles
which node npm npx git gh 2>/dev/null
node --version && npm --version 2>/dev/null
```

### `developer agent`
**Skills activées : async-patterns, testing-patterns, api-design, database-patterns, error-handling-patterns, auth-patterns**

Créer la structure du projet selon le type identifié :

**Si Next.js full-stack :**
```bash
npx create-next-app@latest . --typescript --tailwind --eslint --app --src-dir --import-alias "@/*"
npm install prisma @prisma/client next-auth@beta @auth/prisma-adapter
npm install -D vitest @vitejs/plugin-react @testing-library/react
npx prisma init
```

**Si API Node.js pure :**
```bash
npm init -y
npm install express typescript @types/node @types/express ts-node
npm install prisma @prisma/client zod
npm install -D vitest tsx nodemon
npx tsc --init
```

**Structure de répertoires à créer :**
```
src/
├── app/              # Next.js App Router (ou routes/ pour Express)
│   ├── api/          # API routes
│   └── (auth)/       # Route groups
├── lib/              # Utilitaires partagés
│   ├── auth.ts       # Configuration auth
│   ├── db.ts         # Instance Prisma singleton
│   └── errors.ts     # Result<T,E> + hiérarchie d'erreurs
├── components/       # Composants React (si UI)
│   ├── ui/           # Atomiques (Button, Input...)
│   └── features/     # Composants métier
└── types/            # Types TypeScript partagés
```

## Phase 3 — Configuration de base

### `devops-engineer agent`
**Skills activées : docker-k8s, observability-patterns, security-scanning, incident-response**

Configurer l'infrastructure de développement :

**Docker Compose (développement) :**
```yaml
# docker-compose.yml
services:
  db:
    image: postgres:16-alpine
    environment:
      POSTGRES_DB: ${DB_NAME:-app_dev}
      POSTGRES_PASSWORD: ${DB_PASSWORD:-dev_password}
    ports: ["5432:5432"]
    volumes: [postgres_data:/var/lib/postgresql/data]

  redis:
    image: redis:7-alpine
    ports: ["6379:6379"]

volumes:
  postgres_data:
```

**GitHub Actions CI/CD :**
```yaml
# .github/workflows/ci.yml
name: CI
on: [push, pull_request]
jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-node@v4
        with: { node-version: '20', cache: 'npm' }
      - run: npm ci
      - run: npm run type-check
      - run: npm run lint
      - run: npm test -- --coverage
      - run: npm run build
```

**Variables d'environnement (.env.example) :**
```bash
# Database
DATABASE_URL="postgresql://user:password@localhost:5432/app_dev"

# Auth
NEXTAUTH_SECRET="generate-with-openssl-rand-base64-32"
NEXTAUTH_URL="http://localhost:3000"

# App
NODE_ENV="development"
```

## Phase 4 — Patterns fondamentaux

### `developer agent`
**Skills activées : error-handling-patterns, auth-patterns, database-patterns, async-patterns**

Créer les fichiers fondamentaux :

**`src/lib/errors.ts`** — Result type + hiérarchie d'erreurs (skill: error-handling-patterns)
**`src/lib/db.ts`** — Singleton Prisma avec connection pooling
**`src/lib/auth.ts`** — Configuration Auth.js avec strategy choisie (skill: auth-patterns)
**`src/lib/logger.ts`** — Logger structuré pino avec redaction PII

## Phase 5 — Tests et qualité

### `qa-engineer agent`
**Skills activées : testing-patterns, error-handling-patterns, async-patterns**

Configurer le framework de tests :

```typescript
// vitest.config.ts
import { defineConfig } from 'vitest/config'
export default defineConfig({
  test: {
    environment: 'node',
    coverage: {
      provider: 'v8',
      thresholds: { lines: 80, functions: 80, branches: 70 }
    }
  }
})
```

Créer les premiers tests :
- Test de la connexion DB (smoke test)
- Test du module auth (mocked)
- Test d'un endpoint API core

## Phase 6 — Documentation initiale

### `doc-writer agent`
**Skills activées : architecture-diagrams, api-design, document-processing**

Générer :
- `README.md` — Setup local, variables d'env, commandes disponibles
- `CLAUDE.md` — Stack, conventions, routing des agents (adapter le template de ce repo)
- `docs/architecture.md` — Diagramme C4 généré par l'architect
- `docs/decisions/001-tech-stack.md` — ADR du choix de stack
- `.env.example` — Toutes les variables documentées

## Rapport de livraison

```markdown
## Projet Initialisé : $ARGUMENTS

### Stack retenue
- **Runtime** : Node.js X / Next.js X
- **Base de données** : PostgreSQL X + Prisma X
- **Auth** : Auth.js vX avec stratégie [OAuth/credentials]
- **Tests** : Vitest + Testing Library
- **CI/CD** : GitHub Actions

### Architecture
[Lien vers docs/architecture.md]

### Décisions clés
- ADR #001 : [docs/decisions/001-tech-stack.md]

### Checklist de démarrage
- [x] Structure de répertoires créée
- [x] Dépendances installées
- [x] Docker Compose configuré
- [x] CI/CD configuré
- [x] Patterns fondamentaux (errors, auth, db, logger)
- [x] Tests de smoke passent
- [x] Documentation initiale rédigée

### Prochaines étapes
1. Configurer les secrets dans GitHub Actions
2. Déployer l'environnement de staging
3. Implémenter la première feature : `/workflows/feature-dev [feature-name]`

### Agents à utiliser pour la suite
- Features : `/workflows/feature-dev`
- Code review : `/workflows/code-review`
- Sécurité : `/workflows/security-audit`
```
