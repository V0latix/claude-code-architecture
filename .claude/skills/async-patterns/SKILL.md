---
name: async-patterns
description: "Patterns avancés pour la programmation asynchrone (TypeScript/Node.js) avec async/await, gestion de concurrence, rate limiting et error handling. Activer quand l'utilisateur travaille avec du code asynchrone, des queues, des workers ou des appels API en parallèle."
license: MIT
---

# Async Patterns

## Quand utiliser cette skill

- Code avec `async/await`, `Promise`, ou callbacks
- Appels API multiples en parallèle
- Gestion de files d'attente et workers
- Rate limiting et throttling
- Optimisation de performance I/O

## Patterns essentiels

### 1. Promise.all avec gestion d'erreurs

```typescript
// ✅ Exécution parallèle avec gestion d'erreurs individuelle
const results = await Promise.allSettled([
  fetchUsers(),
  fetchOrders(),
  fetchInventory(),
])

const [users, orders, inventory] = results.map((r) =>
  r.status === 'fulfilled' ? r.value : null
)
```

### 2. Concurrence contrôlée (p-limit)

```typescript
import pLimit from 'p-limit'

const limit = pLimit(10) // Max 10 opérations simultanées

const results = await Promise.all(
  urls.map((url) => limit(() => fetch(url)))
)
```

### 3. Queue avec worker pool

```typescript
import PQueue from 'p-queue'

const queue = new PQueue({ concurrency: 5 })

for (const task of tasks) {
  queue.add(() => processTask(task))
}

await queue.onIdle()
```

### 4. Retry avec backoff exponentiel

```typescript
const withRetry = async <T>(
  fn: () => Promise<T>,
  maxAttempts = 3,
  baseDelay = 1000
): Promise<T> => {
  for (let attempt = 1; attempt <= maxAttempts; attempt++) {
    try {
      return await fn()
    } catch (error) {
      if (attempt === maxAttempts) throw error
      await new Promise((r) => setTimeout(r, baseDelay * 2 ** (attempt - 1)))
    }
  }
  throw new Error('unreachable')
}
```

### 5. Timeout sur une Promise

```typescript
const withTimeout = <T>(promise: Promise<T>, ms: number): Promise<T> =>
  Promise.race([
    promise,
    new Promise<never>((_, reject) =>
      setTimeout(() => reject(new Error(`Timeout after ${ms}ms`)), ms)
    ),
  ])
```

### 6. Circuit Breaker

```typescript
class CircuitBreaker {
  private failures = 0
  private state: 'closed' | 'open' | 'half-open' = 'closed'
  private nextAttempt = Date.now()

  async execute<T>(fn: () => Promise<T>): Promise<T> {
    if (this.state === 'open') {
      if (Date.now() < this.nextAttempt) throw new Error('Circuit breaker OPEN')
      this.state = 'half-open'
    }
    try {
      const result = await fn()
      this.onSuccess()
      return result
    } catch (error) {
      this.onFailure()
      throw error
    }
  }

  private onSuccess() { this.failures = 0; this.state = 'closed' }
  private onFailure() {
    this.failures++
    if (this.failures >= 5) {
      this.state = 'open'
      this.nextAttempt = Date.now() + 60_000 // 1 minute
    }
  }
}
```

## Anti-patterns à éviter

```typescript
// ❌ Pas de await en boucle (séquentiel au lieu de parallèle)
for (const user of users) {
  await processUser(user) // LENT
}

// ✅ Traitement parallèle
await Promise.all(users.map(processUser))

// ❌ Pas d'unhandled rejections
const data = await fetchData() // crash si erreur non catchée

// ✅ Toujours gérer les erreurs
const data = await fetchData().catch((err) => {
  logger.error('fetchData failed', { err })
  return null
})

// ❌ Pas de Promise dans un constructeur
class Service {
  constructor() {
    this.init() // fire-and-forget, erreurs perdues
  }
}

// ✅ Factory async
class Service {
  static async create(): Promise<Service> {
    const service = new Service()
    await service.init()
    return service
  }
}
```
