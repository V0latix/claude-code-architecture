---
name: architecture-diagrams
description: "Création de diagrammes techniques avec Mermaid et le modèle C4 : flowcharts, séquences, ER diagrams, architectures de systèmes et diagrammes de composants. Activer pour documenter une architecture, créer des schémas de flux ou visualiser des dépendances."
license: MIT
sources: "wshobson/agents (mermaid-expert, c4-code, c4-component, c4-container, c4-context, architecture-decision-records)"
---

# Architecture Diagrams

## Quand utiliser cette skill

- Documenter une architecture système
- Créer des diagrammes de séquence pour les flux de données
- Visualiser des schémas de base de données
- Représenter des architectures C4 (Context, Container, Component, Code)
- Créer des flowcharts de processus métier

## 1. Mermaid — Syntaxe essentielle

### Flowchart

```mermaid
flowchart TD
    A[Requête utilisateur] --> B{Authentifié ?}
    B -->|Non| C[Redirect /login]
    B -->|Oui| D{Permission ?}
    D -->|Non| E[403 Forbidden]
    D -->|Oui| F[Traiter la requête]
    F --> G{Succès ?}
    G -->|Oui| H[200 OK + données]
    G -->|Non| I[500 Error + log]

    style C fill:#ff9999
    style E fill:#ff9999
    style H fill:#99ff99
```

### Diagramme de séquence

```mermaid
sequenceDiagram
    autonumber
    actor User
    participant Browser
    participant Next.js
    participant API
    participant DB

    User->>Browser: Click "Login"
    Browser->>Next.js: POST /api/auth/login
    Next.js->>DB: SELECT user WHERE email=?
    DB-->>Next.js: User record
    Next.js->>Next.js: bcrypt.compare(password, hash)

    alt Mot de passe valide
        Next.js->>Next.js: Générer JWT
        Next.js-->>Browser: 200 OK + Set-Cookie: session
        Browser-->>User: Redirect /dashboard
    else Mot de passe invalide
        Next.js-->>Browser: 401 Unauthorized
        Browser-->>User: Afficher erreur
    end
```

### Diagramme ER (Base de données)

```mermaid
erDiagram
    USER {
        string id PK
        string email UK
        string name
        enum role
        datetime createdAt
    }

    ORDER {
        string id PK
        string userId FK
        enum status
        decimal total
        datetime createdAt
    }

    ORDER_ITEM {
        string id PK
        string orderId FK
        string productId FK
        int quantity
        decimal price
    }

    PRODUCT {
        string id PK
        string name
        decimal price
        int stock
    }

    USER ||--o{ ORDER : "places"
    ORDER ||--|{ ORDER_ITEM : "contains"
    PRODUCT ||--o{ ORDER_ITEM : "included in"
```

### Architecture de microservices

```mermaid
graph TB
    Client([Client Browser]) --> Gateway[API Gateway<br/>Kong/Nginx]

    Gateway --> Auth[Auth Service<br/>:3001]
    Gateway --> Users[Users Service<br/>:3002]
    Gateway --> Orders[Orders Service<br/>:3003]
    Gateway --> Payments[Payments Service<br/>:3004]

    Auth --> AuthDB[(PostgreSQL<br/>auth_db)]
    Users --> UsersDB[(PostgreSQL<br/>users_db)]
    Orders --> OrdersDB[(PostgreSQL<br/>orders_db)]
    Orders --> Queue([RabbitMQ])
    Queue --> Payments
    Payments --> PaymentsDB[(PostgreSQL<br/>payments_db)]

    Orders --> Cache[(Redis<br/>Cache)]

    style Gateway fill:#f4a261
    style Queue fill:#e9c46a
    style Cache fill:#e9c46a
```

## 2. Modèle C4 — 4 niveaux

### Niveau 1 : Context (vue d'ensemble)

```mermaid
C4Context
    title System Context: E-Commerce Platform

    Person(customer, "Customer", "Buys products online")
    Person(admin, "Admin", "Manages products and orders")

    System(ecommerce, "E-Commerce Platform", "Allows customers to browse, order and pay for products")

    System_Ext(payment, "Stripe", "Payment processing")
    System_Ext(email, "SendGrid", "Email notifications")
    System_Ext(analytics, "Mixpanel", "User analytics")

    Rel(customer, ecommerce, "Browses and orders", "HTTPS")
    Rel(admin, ecommerce, "Manages catalog", "HTTPS")
    Rel(ecommerce, payment, "Processes payments", "HTTPS API")
    Rel(ecommerce, email, "Sends emails", "SMTP/API")
    Rel(ecommerce, analytics, "Tracks events", "HTTPS")
```

### Niveau 2 : Container (composants principaux)

```mermaid
C4Container
    title Container Diagram: E-Commerce Platform

    Person(customer, "Customer")

    Container_Boundary(platform, "E-Commerce Platform") {
        Container(web, "Web App", "Next.js 15", "Server-side rendered frontend")
        Container(api, "API Server", "Node.js/Express", "REST API business logic")
        Container(worker, "Background Worker", "BullMQ", "Async job processing")
        ContainerDb(db, "Database", "PostgreSQL", "User, product, order data")
        ContainerDb(cache, "Cache", "Redis", "Sessions, API cache")
    }

    System_Ext(stripe, "Stripe API")

    Rel(customer, web, "Uses", "HTTPS")
    Rel(web, api, "API calls", "HTTPS/JSON")
    Rel(api, db, "Read/write", "SQL")
    Rel(api, cache, "Read/write", "Redis protocol")
    Rel(api, worker, "Enqueue jobs", "Redis")
    Rel(worker, stripe, "Process payments", "HTTPS")
```

## 3. Diagramme de déploiement

```mermaid
graph TB
    subgraph Internet
        User([Users])
    end

    subgraph Vercel["Vercel Edge Network"]
        CDN[CDN / Edge Cache]
        NextApp[Next.js App<br/>Serverless Functions]
    end

    subgraph Railway["Railway / Cloud"]
        direction LR
        API[API Service<br/>Node.js]
        Worker[Worker Service<br/>BullMQ]
        PG[(PostgreSQL)]
        Redis[(Redis)]
    end

    User --> CDN
    CDN --> NextApp
    NextApp --> API
    API --> PG
    API --> Redis
    Worker --> Redis
    Worker --> PG
```

## 4. Règles pour des bons diagrammes

```
✅ Titres clairs et descriptifs
✅ Flèches avec labels explicatifs ("Calls", "Reads from", "Publishes to")
✅ Couleurs cohérentes pour les catégories (DB = bleu, service = vert, externe = gris)
✅ Niveau de détail adapté au public (C4 Level 1 pour execs, Level 3 pour devs)
✅ Mettre à jour les diagrammes avec le code (versionner dans /docs/)

❌ Diagrammes avec > 15 éléments sans regroupement
❌ Flèches non labelisées (on ne sait pas ce qui transite)
❌ Mélanger les niveaux d'abstraction (process OS + composant métier ensemble)
❌ Diagrammes non versionnés (obsolètes rapidement)
```

## 5. Générer des diagrammes depuis le code

```typescript
// Générer un diagramme ER depuis le schéma Prisma
import { getDMMF } from '@prisma/internals'

const generateERDiagram = async (schemaPath: string): Promise<string> => {
  const dmmf = await getDMMF({ datamodelPath: schemaPath })

  let mermaid = 'erDiagram\n'
  for (const model of dmmf.datamodel.models) {
    mermaid += `    ${model.name.toUpperCase()} {\n`
    for (const field of model.fields.filter(f => f.kind !== 'object')) {
      mermaid += `        ${field.type} ${field.name}${field.isId ? ' PK' : ''}${field.isUnique ? ' UK' : ''}\n`
    }
    mermaid += '    }\n'
  }
  return mermaid
}
```
