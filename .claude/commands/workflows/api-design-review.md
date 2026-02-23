---
description: "Design et review d'une API REST ou GraphQL. Couvre les conventions, la sécurité, les performances, la documentation OpenAPI, les tests de contrat et la compatibilité backward."
allowed-tools: Bash, Read, Grep, Glob, Task
---

# API Design & Review

API à concevoir ou reviewer : **$ARGUMENTS**

Si `$ARGUMENTS` est une description → **concevoir** l'API from scratch.
Si `$ARGUMENTS` est un fichier/module → **reviewer** l'API existante.

## Phase 0 — Reconnaissance

```bash
# Trouver les routes existantes
grep -r "router\.\|app\.\(get\|post\|put\|patch\|delete\)\|@Get\|@Post\|@Put\|@Delete" \
  --include="*.ts" -n | grep -v node_modules | grep -v "//.*" | head -40

# Schema OpenAPI existant ?
find . -name "openapi*.yaml" -o -name "swagger*.yaml" -o -name "openapi*.json" \
  2>/dev/null | grep -v node_modules

# Vérifier les middlewares d'auth
grep -r "middleware\|auth\|protect\|requireAuth\|withAuth\|Bearer" \
  --include="*.ts" -l | grep -v node_modules

# Types de réponse utilisés
grep -rn "res\.json\|return {" --include="*.ts" | grep -v node_modules | head -20
```

## Phase 1 — Analyses parallèles (lancer avec Task)

### `architect agent`
**Skills activées : api-design, database-patterns, architecture-diagrams, auth-patterns, async-patterns**

Analyser/concevoir `$ARGUMENTS` selon les principes REST :

**Conventions à vérifier :**
1. **Nommage des ressources** : pluriel, minuscules, pas de verbes dans les URLs
   - ✅ `GET /users/{id}/orders` — ❌ `GET /getOrdersForUser/{id}`
2. **Méthodes HTTP sémantiques** : GET (read) / POST (create) / PUT (full update) / PATCH (partial) / DELETE
3. **Codes de statut corrects** : 200/201/204/400/401/403/404/409/422/500
4. **Pagination** : cursor-based pour les grandes collections (éviter offset)
5. **Versioning** : `/v1/` dans le path ou header `Accept: application/vnd.api+v1+json`
6. **Filtering/sorting** : `?filter[status]=active&sort=-created_at`
7. **Idempotence** : PUT et DELETE doivent être idempotents
8. **Gestion des erreurs** : format uniforme `{ error: { code, message, details } }`

**Spec OpenAPI à produire :**
```yaml
openapi: 3.1.0
info:
  title: $ARGUMENTS API
  version: 1.0.0
paths:
  /resources:
    get:
      summary: List resources
      parameters:
        - in: query
          name: cursor
          schema: { type: string }
        - in: query
          name: limit
          schema: { type: integer, default: 20, maximum: 100 }
      responses:
        '200':
          description: Paginated list
          content:
            application/json:
              schema:
                type: object
                properties:
                  data: { type: array, items: { $ref: '#/components/schemas/Resource' } }
                  nextCursor: { type: string, nullable: true }
                  total: { type: integer }
```

### `security-auditor agent`
**Skills activées : security-scanning, auth-patterns, error-handling-patterns, api-design**

Auditer la sécurité de `$ARGUMENTS` — OWASP API Security Top 10 :

1. **API01 — BOLA (IDOR)** : Vérifier que chaque endpoint valide ownership (`userId === req.user.id`)
2. **API02 — Auth cassée** : Token validation, expiration, refresh, revocation
3. **API03 — Excessive Data Exposure** : Réponses filtrent-elles les champs sensibles ?
4. **API04 — Lack of Rate Limiting** : Rate limiting par IP et par user configuré ?
5. **API05 — BFLA** : Vérification des permissions au niveau fonction (pas seulement route)
6. **API06 — Mass Assignment** : `req.body` spreader sans whitelist ?
7. **API07 — Security Misconfiguration** : CORS restrictif ? Headers de sécurité ?
8. **API08 — Injection** : Inputs validés avec Zod avant usage ?
9. **API09 — Improper Asset Management** : Routes de debug exposées en prod ?
10. **API10 — Unsafe Consumption** : Les réponses d'API tierces sont-elles validées ?

### `qa-engineer agent`
**Skills activées : testing-patterns, error-handling-patterns, async-patterns**

Définir la stratégie de tests pour `$ARGUMENTS` :

**Tests de contrat :**
```typescript
// tests/api/contract/orders.contract.test.ts
describe('POST /api/orders', () => {
  it('returns 201 with order on valid payload', async () => {
    const res = await request(app)
      .post('/api/orders')
      .set('Authorization', `Bearer ${validToken}`)
      .send({ items: [{ productId: 'prod_1', quantity: 2 }] })

    expect(res.status).toBe(201)
    expect(res.body).toMatchObject({
      id: expect.stringMatching(/^ord_/),
      status: 'pending',
      total: expect.any(Number),
      createdAt: expect.any(String),
    })
    // Vérifier qu'il n'y a PAS de champs sensibles
    expect(res.body).not.toHaveProperty('internalCost')
    expect(res.body).not.toHaveProperty('userId')
  })

  it('returns 422 on invalid payload', async () => {
    const res = await request(app)
      .post('/api/orders')
      .set('Authorization', `Bearer ${validToken}`)
      .send({ items: [] })  // Panier vide

    expect(res.status).toBe(422)
    expect(res.body.error.code).toBe('VALIDATION_ERROR')
    expect(res.body.error.details).toBeInstanceOf(Array)
  })

  it('returns 401 without auth', async () => {
    const res = await request(app).post('/api/orders').send({...})
    expect(res.status).toBe(401)
  })
})
```

### `performance-engineer agent`
**Skills activées : async-patterns, database-patterns, observability-patterns**

Analyser les performances de `$ARGUMENTS` :
- Endpoints avec N+1 potentiel (relations non eager-loaded)
- Pagination offset sur grandes tables (> 10K lignes → cursor-based)
- Absence de cache sur les ressources stables (GET /products, GET /config)
- Compression gzip/brotli activée ?
- Response time SLOs définis et mesurés ?

## Phase 2 — Implémentation des corrections

### `developer agent`
**Skills activées : api-design, auth-patterns, error-handling-patterns, async-patterns, database-patterns**

Implémenter selon les recommandations :

**Format d'erreur uniforme :**
```typescript
// src/lib/api-response.ts
export function apiError(
  code: string,
  message: string,
  details?: unknown[],
  status = 400
) {
  return Response.json(
    { error: { code, message, details: details ?? [] } },
    { status }
  )
}

export function apiSuccess<T>(data: T, status = 200) {
  return Response.json({ data }, { status })
}

export function apiCreated<T>(data: T) {
  return Response.json({ data }, { status: 201 })
}
```

**Validation avec Zod + middleware :**
```typescript
// src/lib/validate.ts
import { z } from 'zod'
import { apiError } from './api-response'

export function withValidation<T extends z.ZodTypeAny>(
  schema: T,
  handler: (data: z.infer<T>, req: Request) => Promise<Response>
) {
  return async (req: Request) => {
    const body = await req.json().catch(() => ({}))
    const result = schema.safeParse(body)
    if (!result.success) {
      return apiError('VALIDATION_ERROR', 'Invalid request', result.error.errors, 422)
    }
    return handler(result.data, req)
  }
}
```

**Pagination cursor-based :**
```typescript
// src/lib/pagination.ts
export async function paginate<T>(
  findMany: (cursor?: string, limit?: number) => Promise<T[]>,
  cursor?: string,
  limit = 20
) {
  const items = await findMany(cursor, Math.min(limit, 100) + 1)
  const hasMore = items.length > limit
  return {
    data: hasMore ? items.slice(0, limit) : items,
    nextCursor: hasMore ? encodeCursor(items[limit - 1]) : null,
    hasMore,
  }
}
```

## Phase 3 — Documentation

### `doc-writer agent`
**Skills activées : api-design, architecture-diagrams**

Générer ou mettre à jour :
- **OpenAPI spec** complète (tous les endpoints, tous les schemas, tous les codes d'erreur)
- **README de l'API** avec exemples curl pour chaque endpoint
- **CHANGELOG** si modification d'une API existante (backward compatibility)
- **Migration guide** si breaking changes

## Rapport de Review

```markdown
# API Design Review — $ARGUMENTS
**Date** : $(date)
**Type** : Design / Review
**Reviewers** : architect + security-auditor + qa-engineer + performance-engineer

## Score global : X/10
| Dimension | Score | Points clés |
|-----------|-------|-------------|
| Conventions REST | X/10 | ... |
| Sécurité (OWASP API) | X/10 | ... |
| Tests | X/10 | ... |
| Performance | X/10 | ... |
| Documentation | X/10 | ... |

## ✅ Points forts
- ...

## 🔴 Bloquants — À corriger avant mise en production
| # | Endpoint | Problème | OWASP | Solution |
|---|---------|---------|-------|---------|
| 1 | GET /users | Pas de pagination → timeout sur grandes tables | API04 | Cursor-based pagination |
| 2 | POST /orders | Pas de rate limiting → DDoS possible | API04 | Upstash rate limiter |

## 🟡 Importants
| # | Endpoint | Problème | Solution |
|---|---------|---------|---------|

## 🟢 Suggestions
- ...

## Backward Compatibility
- [ ] Aucun breaking change
- [ ] Breaking changes documentés avec migration guide
- [ ] Version incrémentée (/v2/ ou nouveau header)

## Checklist avant déploiement
- [ ] Tous les endpoints protégés par auth
- [ ] Rate limiting configuré
- [ ] Inputs validés avec Zod
- [ ] Erreurs en format uniforme
- [ ] OpenAPI spec à jour
- [ ] Tests de contrat passent
- [ ] Logs structurés sur chaque requête

## Skills recommandées pour la correction
- [auth-patterns] : si auth/authz insuffisante
- [error-handling-patterns] : si format d'erreur incohérent
- [async-patterns] : si performances dégradées par appels séquentiels
- [database-patterns] : si N+1 ou pagination offset sur grandes tables
```
