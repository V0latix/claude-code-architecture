---
name: testing-patterns
description: "Stratégies et patterns de tests pour TypeScript/JavaScript avec Vitest, Jest, Testing Library et Playwright. Activer pour écrire des tests robustes, configurer des suites de tests ou analyser la couverture."
license: MIT
---

# Testing Patterns

## Quand utiliser cette skill

- Écriture de tests unitaires, d'intégration ou e2e
- Configuration d'une suite de tests
- Amélioration de la couverture de code
- Debugging de tests flaky
- Mise en place du TDD

## Patterns essentiels

### 1. Structure AAA (Arrange, Act, Assert)

```typescript
import { describe, it, expect, vi } from 'vitest'

describe('OrderService', () => {
  describe('processOrder', () => {
    it('should emit OrderProcessed event when order is valid', async () => {
      // Arrange
      const eventBus = { emit: vi.fn() }
      const service = new OrderService(eventBus)
      const order = buildOrder({ status: 'pending', total: 100 })

      // Act
      await service.processOrder(order)

      // Assert
      expect(eventBus.emit).toHaveBeenCalledOnce()
      expect(eventBus.emit).toHaveBeenCalledWith('OrderProcessed', {
        orderId: order.id,
        total: 100,
      })
    })
  })
})
```

### 2. Test Builders (Object Mother)

```typescript
// builders/order.ts
export const buildOrder = (overrides: Partial<Order> = {}): Order => ({
  id: 'order-123',
  userId: 'user-456',
  items: [{ productId: 'prod-1', quantity: 2, price: 50 }],
  status: 'pending',
  total: 100,
  createdAt: new Date('2024-01-01'),
  ...overrides,
})
```

### 3. Mocking avec Vitest

```typescript
// Mock de module entier
vi.mock('@/lib/email', () => ({
  sendEmail: vi.fn().mockResolvedValue({ messageId: 'test-id' }),
}))

// Mock partiel
vi.mock('@/db', async (importOriginal) => {
  const actual = await importOriginal<typeof import('@/db')>()
  return { ...actual, db: { user: { findUnique: vi.fn() } } }
})

// Spy sur une méthode
const spy = vi.spyOn(service, 'processPayment').mockResolvedValue(ok(payment))
```

### 4. Tests d'intégration avec base de données

```typescript
import { beforeAll, afterAll, beforeEach } from 'vitest'
import { db } from '@/db'

beforeAll(async () => {
  await db.$executeRaw`BEGIN`
})

afterAll(async () => {
  await db.$executeRaw`ROLLBACK`
  await db.$disconnect()
})

beforeEach(async () => {
  // Nettoyer les tables dans l'ordre (FK constraints)
  await db.order.deleteMany()
  await db.user.deleteMany()
})
```

### 5. Tests e2e avec Playwright

```typescript
import { test, expect } from '@playwright/test'

test.describe('Checkout Flow', () => {
  test('should complete purchase successfully', async ({ page }) => {
    // Navigate
    await page.goto('/products')
    await page.getByRole('button', { name: 'Add to cart' }).first().click()
    await page.getByRole('link', { name: 'Cart' }).click()

    // Fill checkout
    await page.getByLabel('Email').fill('test@example.com')
    await page.getByRole('button', { name: 'Checkout' }).click()

    // Assert
    await expect(page.getByText('Order confirmed')).toBeVisible()
    await expect(page).toHaveURL(/\/orders\/\d+/)
  })
})
```

### 6. Testing des Custom Hooks React

```typescript
import { renderHook, act } from '@testing-library/react'
import { useCounter } from './useCounter'

it('should increment counter', () => {
  const { result } = renderHook(() => useCounter(0))

  act(() => { result.current.increment() })

  expect(result.current.count).toBe(1)
})
```

## Configuration Vitest recommandée

```typescript
// vitest.config.ts
import { defineConfig } from 'vitest/config'

export default defineConfig({
  test: {
    environment: 'node',
    globals: true,
    coverage: {
      provider: 'v8',
      thresholds: { lines: 80, branches: 75, functions: 80 },
      exclude: ['**/*.config.*', '**/types/**', '**/__mocks__/**'],
    },
    setupFiles: ['./tests/setup.ts'],
  },
})
```

## Anti-patterns à éviter

```typescript
// ❌ Tester l'implémentation, pas le comportement
expect(service._internalCache.size).toBe(1) // fragile

// ✅ Tester le comportement observable
const result = await service.getUser(id)
expect(result).toEqual(expectedUser)

// ❌ Tests interdépendants
let sharedState: User
it('creates user', () => { sharedState = createUser() })
it('updates user', () => { updateUser(sharedState) }) // dépend du test précédent

// ✅ Chaque test est autonome
it('updates user', () => {
  const user = createUser() // chaque test crée ses propres données
  updateUser(user)
})
```
