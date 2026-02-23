---
name: api-design
description: "Patterns de design d'API REST et GraphQL : conventions de nommage, versioning, pagination, gestion d'erreurs, authentification et documentation OpenAPI. Activer lors de la conception ou review d'une API."
license: MIT
---

# API Design

## Quand utiliser cette skill

- Conception d'une nouvelle API REST ou GraphQL
- Review d'une API existante
- Standardisation des conventions d'une équipe
- Documentation API avec OpenAPI/Swagger
- Gestion des erreurs et des codes HTTP

## Conventions REST

### Nommage des routes

```
# Ressources au pluriel, noms pas verbes
GET    /users              # Liste
GET    /users/:id          # Détail
POST   /users              # Créer
PUT    /users/:id          # Remplacer
PATCH  /users/:id          # Mettre à jour partiellement
DELETE /users/:id          # Supprimer

# Relations imbriquées (max 2 niveaux)
GET    /users/:id/orders
GET    /users/:id/orders/:orderId

# Actions non-CRUD → sous-ressource ou verbe
POST   /orders/:id/cancel
POST   /users/:id/password-reset
```

### Codes HTTP corrects

```
200 OK              → GET, PATCH, PUT réussis
201 Created         → POST réussi (+ Location header)
204 No Content      → DELETE réussi
400 Bad Request     → Données invalides (validation)
401 Unauthorized    → Non authentifié
403 Forbidden       → Authentifié mais pas autorisé
404 Not Found       → Ressource introuvable
409 Conflict        → Conflit d'état (ex: doublon)
422 Unprocessable   → Validation métier échouée
429 Too Many Req.   → Rate limit dépassé
500 Internal Error  → Erreur serveur non anticipée
```

### Format d'erreur standardisé

```typescript
// Format RFC 7807 (Problem Details)
interface ApiError {
  type: string       // URI identifiant le type d'erreur
  title: string      // Message court lisible
  status: number     // Code HTTP
  detail: string     // Description détaillée
  instance?: string  // URI de l'occurrence spécifique
  errors?: Record<string, string[]> // Erreurs de validation
}

// Exemple
{
  "type": "/errors/validation-failed",
  "title": "Validation Failed",
  "status": 422,
  "detail": "The request contains invalid data",
  "errors": {
    "email": ["Invalid email format"],
    "age": ["Must be at least 18"]
  }
}
```

### Pagination

```typescript
// Cursor-based (recommandé pour grandes collections)
GET /posts?cursor=eyJpZCI6MTAwfQ&limit=20

{
  "data": [...],
  "pagination": {
    "cursor": "eyJpZCI6MTIwfQ",
    "hasNextPage": true,
    "limit": 20
  }
}

// Offset-based (simple mais limité)
GET /posts?page=2&limit=20

{
  "data": [...],
  "meta": {
    "currentPage": 2,
    "totalPages": 15,
    "totalCount": 298,
    "limit": 20
  }
}
```

### Versioning

```
# Version dans l'URL (recommandé)
/api/v1/users
/api/v2/users

# Version dans le header (alternatif)
Accept: application/vnd.api+json;version=2
```

## OpenAPI 3.0 — Template

```yaml
openapi: 3.0.3
info:
  title: Project API
  version: 1.0.0

paths:
  /users/{id}:
    get:
      summary: Get user by ID
      operationId: getUserById
      parameters:
        - name: id
          in: path
          required: true
          schema: { type: string, format: uuid }
      responses:
        '200':
          description: User found
          content:
            application/json:
              schema: { $ref: '#/components/schemas/User' }
        '404':
          $ref: '#/components/responses/NotFound'

components:
  schemas:
    User:
      type: object
      required: [id, email, createdAt]
      properties:
        id: { type: string, format: uuid }
        email: { type: string, format: email }
        createdAt: { type: string, format: date-time }
```

## Anti-patterns à éviter

```
# ❌ Verbes dans les routes
POST /createUser
GET  /getUserById?id=123

# ✅ Noms + méthodes HTTP
POST /users
GET  /users/123

# ❌ Exposer la structure interne
GET /api/v1/db/user_table?userId=123

# ✅ Abstraire la couche données
GET /api/v1/users/123

# ❌ Ignorer l'idempotence
POST /orders/:id  # crée un doublon si retry

# ✅ PUT/PATCH pour les updates idempotents
PATCH /orders/:id
```
