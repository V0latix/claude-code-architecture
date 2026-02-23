---
name: database-patterns
description: "Patterns de base de données : schémas Prisma, requêtes optimisées, migrations, index, transactions et patterns N+1. Activer pour concevoir des schémas, optimiser des requêtes ou résoudre des problèmes de performance BDD."
license: MIT
---

# Database Patterns

## Quand utiliser cette skill

- Conception d'un schéma de base de données
- Optimisation de requêtes lentes
- Résolution du problème N+1
- Implémentation de transactions
- Stratégie de migration

## Prisma — Patterns essentiels

### Schéma bien structuré

```prisma
// schema.prisma
model User {
  id        String   @id @default(cuid())
  email     String   @unique
  name      String
  role      Role     @default(USER)
  createdAt DateTime @default(now())
  updatedAt DateTime @updatedAt

  orders    Order[]
  profile   Profile?

  @@index([email])
  @@index([createdAt])
}

model Order {
  id        String      @id @default(cuid())
  userId    String
  status    OrderStatus @default(PENDING)
  total     Decimal     @db.Decimal(10, 2)
  createdAt DateTime    @default(now())

  user      User        @relation(fields: [userId], references: [id])
  items     OrderItem[]

  @@index([userId, createdAt])
  @@index([status, createdAt])
}

enum Role { USER ADMIN MODERATOR }
enum OrderStatus { PENDING CONFIRMED SHIPPED DELIVERED CANCELLED }
```

### Éviter le N+1 avec select/include

```typescript
// ❌ N+1 Problem
const users = await prisma.user.findMany()
for (const user of users) {
  // 1 query par user !
  const orders = await prisma.order.findMany({ where: { userId: user.id } })
}

// ✅ Include (eager loading)
const users = await prisma.user.findMany({
  include: {
    orders: {
      where: { status: 'CONFIRMED' },
      orderBy: { createdAt: 'desc' },
      take: 5,
    },
  },
})

// ✅ Select (seulement les champs nécessaires)
const users = await prisma.user.findMany({
  select: {
    id: true,
    name: true,
    email: true,
    _count: { select: { orders: true } },
  },
})
```

### Transactions

```typescript
// Transaction séquentielle
const result = await prisma.$transaction(async (tx) => {
  const order = await tx.order.create({ data: orderData })

  await tx.inventory.updateMany({
    where: { productId: { in: productIds } },
    data: { quantity: { decrement: 1 } },
  })

  await tx.payment.create({ data: { orderId: order.id, amount: order.total } })

  return order
})

// Transaction avec retry (pour les conflits de concurrence)
await prisma.$transaction(
  async (tx) => { /* ... */ },
  { maxWait: 5000, timeout: 10000, isolationLevel: 'Serializable' }
)
```

### Pagination curseur efficace

```typescript
const getOrders = async (cursor?: string, limit = 20) => {
  const orders = await prisma.order.findMany({
    take: limit + 1,  // +1 pour savoir s'il y a une page suivante
    ...(cursor && {
      cursor: { id: cursor },
      skip: 1,
    }),
    orderBy: { createdAt: 'desc' },
  })

  const hasNextPage = orders.length > limit
  return {
    data: orders.slice(0, limit),
    nextCursor: hasNextPage ? orders[limit - 1].id : null,
  }
}
```

## Stratégie d'indexation

```sql
-- Index composé pour les requêtes fréquentes
CREATE INDEX idx_orders_user_status ON orders(user_id, status);

-- Index partiel pour les données actives
CREATE INDEX idx_active_sessions ON sessions(user_id)
  WHERE expires_at > NOW();

-- Index pour LIKE (full-text search)
CREATE INDEX idx_products_name_gin ON products
  USING gin(to_tsvector('english', name));
```

## Anti-patterns à éviter

```typescript
// ❌ Select * en production
await prisma.user.findMany()  // charge TOUT

// ✅ Sélectionner uniquement les champs nécessaires
await prisma.user.findMany({ select: { id: true, email: true } })

// ❌ Pas de pagination
await prisma.order.findMany()  // peut renvoyer millions de lignes

// ✅ Toujours paginer
await prisma.order.findMany({ take: 50, skip: page * 50 })

// ❌ Requêtes dans des boucles
for (const id of ids) {
  await prisma.user.findUnique({ where: { id } })
}

// ✅ Requête unique
await prisma.user.findMany({ where: { id: { in: ids } } })
```
