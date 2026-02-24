---
name: tdd-enforcement
description: "Discipline TDD : cycles RED-GREEN-REFACTOR obligatoires, aucun code de production sans test qui échoue d'abord, tâches de 2-5 minutes. Complémentaire à testing-patterns (outils) — couvre le processus TDD. Activer pour toute nouvelle implémentation ou correction de bug."
license: MIT
---

# TDD Enforcement

## Quand utiliser cette skill

- Implémentation de toute nouvelle fonctionnalité
- Correction de bugs (en combinaison avec `systematic-debugging`)
- Refactoring avec préservation du comportement
- Toute tâche issue d'un plan (`writing-plans`)

> Cette skill couvre le **processus** TDD. Pour les outils de test (Vitest, Testing Library, mocks), utiliser `testing-patterns`.

## Loi de fer

> **AUCUN CODE DE PRODUCTION SANS TEST QUI ÉCHOUE D'ABORD.**
> Exceptions autorisées uniquement avec approbation explicite : migrations one-shot, glue code trivial (re-exports purs).

---

## Le Cycle RED-GREEN-REFACTOR

### RED — Écrire le test qui échoue

```typescript
// 1. Écrire le test AVANT d'ouvrir le fichier d'implémentation
it('applies 10% discount for premium users', () => {
  const price = applyDiscount(100, 'premium')
  expect(price).toBe(90)
})

// 2. Lancer les tests — VÉRIFIER qu'il échoue pour la bonne raison
// npx vitest run src/lib/discount.test.ts
// ✗ applies 10% discount for premium users
//   Error: applyDiscount is not a function   ← bonne raison ✅
//   (pas : "Expected 90, received undefined" ← mauvaise raison ❌)
```

**Piège RED :** Si le test échoue pour une mauvaise raison (import manquant, syntaxe…), corriger d'abord avant d'implémenter.

### GREEN — Code minimal pour faire passer

```typescript
// Implémenter le strict minimum — rien de plus
export function applyDiscount(price: number, tier: string): number {
  if (tier === 'premium') return price * 0.9
  return price
}

// npx vitest run src/lib/discount.test.ts
// ✓ applies 10% discount for premium users  ← GREEN ✅

// ⚠️  Ne pas ajouter de features non testées :
// ❌ Ajouter 'gold', 'silver' tiers sans tests
// ❌ Ajouter du logging sans tests
// ❌ Ajouter de la validation sans tests
```

### REFACTOR — Nettoyer sans casser

```typescript
// Améliorer la structure — les tests doivent rester verts
export type UserTier = 'premium' | 'standard' | 'trial'

const DISCOUNT_RATES: Record<UserTier, number> = {
  premium: 0.9,
  standard: 1.0,
  trial: 1.0,
}

export function applyDiscount(price: number, tier: UserTier): number {
  return price * (DISCOUNT_RATES[tier] ?? 1.0)
}

// npx vitest run src/lib/discount.test.ts
// ✓ applies 10% discount for premium users  ← toujours GREEN ✅

// Puis commit
// git commit -m "feat: add applyDiscount with tier-based pricing"
```

---

## Granularité des tâches

**Chaque cycle RED-GREEN-REFACTOR = 2-5 minutes maximum.**

Si une tâche prend plus de 5 minutes → décomposer :

```
// ❌ Tâche trop large : "Implémenter le système de paiement"

// ✅ Décomposition correcte :
// Task 1 (3 min) : validateCard — retourne true/false
// Task 2 (4 min) : chargeAmount — retourne { success, transactionId }
// Task 3 (2 min) : sendReceipt — envoie email de confirmation
// Task 4 (5 min) : processPayment — orchestre les 3 précédents
```

---

## Patterns RED-GREEN-REFACTOR par contexte

### Fonction pure

```typescript
// RED
it('formats price with currency symbol', () => {
  expect(formatPrice(9.99, 'EUR')).toBe('9,99 €')
})

// GREEN
export function formatPrice(amount: number, currency: string): string {
  if (currency === 'EUR') return `${amount.toFixed(2).replace('.', ',')} €`
  return `${amount.toFixed(2)}`
}

// REFACTOR
const FORMATTERS: Record<string, Intl.NumberFormat> = {
  EUR: new Intl.NumberFormat('fr-FR', { style: 'currency', currency: 'EUR' }),
  USD: new Intl.NumberFormat('en-US', { style: 'currency', currency: 'USD' }),
}
export function formatPrice(amount: number, currency: string): string {
  return (FORMATTERS[currency] ?? FORMATTERS['USD']).format(amount)
}
```

### Service avec dépendances

```typescript
// RED — mocker les dépendances
it('sends welcome email when user registers', async () => {
  const emailService = { send: vi.fn().mockResolvedValue(undefined) }
  const service = new UserService(emailService)

  await service.register({ email: 'user@test.com', name: 'Alice' })

  expect(emailService.send).toHaveBeenCalledWith({
    to: 'user@test.com',
    template: 'welcome',
    data: { name: 'Alice' },
  })
})

// GREEN — implémentation minimale
// REFACTOR — typage complet, gestion d'erreurs
```

### API endpoint (Next.js)

```typescript
// RED — tester le handler directement
it('returns 401 when token is missing', async () => {
  const req = new Request('http://localhost/api/profile')
  const res = await GET(req)
  expect(res.status).toBe(401)
})

// GREEN → REFACTOR
```

---

## Anti-patterns

```typescript
// ❌ Écrire l'implémentation avant le test
export function applyDiscount(price: number, tier: string): number {
  // ... code déjà écrit
}
// puis écrire un test pour "valider" ce qui existe déjà → ce n'est pas du TDD

// ❌ Test tautologique
it('calls the function', () => {
  const fn = vi.fn()
  fn()
  expect(fn).toHaveBeenCalled() // ne teste rien de métier

// ❌ Test trop large
it('processes the entire user registration flow', async () => {
  // 50 lignes, teste 10 comportements différents
  // → impossible de savoir ce qui échoue

// ✅ Tests unitaires, focalisés, lisibles
it('rejects registration when email already exists', async () => {
  // 10 lignes max, un seul comportement testé
})
```

---

## Intégration avec les autres skills

| Skill | Synergie |
|-------|---------|
| `systematic-debugging` | Phase 4 : écrire le test de reproduction (RED) avant de corriger |
| `verification-before-completion` | Vérifier GREEN à chaque étape, pas seulement à la fin |
| `writing-plans` | Chaque tâche du plan = 1 cycle RED-GREEN-REFACTOR |
| `testing-patterns` | Outils Vitest, mocks, builders, coverage |
