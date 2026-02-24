---
name: writing-plans
description: "Création de plans d'implémentation granulaires : tâches de 2-5 minutes avec code exact, tests RED/GREEN et commits. Format docs/plans/YYYY-MM-DD-feature.md. Activer avant toute implémentation non triviale pour structurer le travail en cycles TDD atomiques."
license: MIT
---

# Writing Plans

## Quand utiliser cette skill

- Avant d'implémenter une feature de plus de 15 minutes
- Pour décomposer un ticket complexe en tâches atomiques
- Quand l'implémentation touche 3 fichiers ou plus
- Avant de lancer `/tools/execute-plan`

> Pour les plans BMAD (PRD, architecture, épics), utiliser les templates BMAD.
> Cette skill couvre les plans d'implémentation **technique granulaires**.

---

## Format du plan file

**Chemin :** `docs/plans/YYYY-MM-DD-nom-feature.md`

```markdown
# Plan : [Titre de la feature]

**Date :** YYYY-MM-DD
**Scope :** [bref résumé — 1 ligne]
**Fichiers principaux :** `src/lib/[feature].ts`, `src/lib/[feature].test.ts`

## Contexte

[Pourquoi cette feature ? Quel problème résout-elle ? Lien avec ticket/issue si applicable]

## Statuts
- [ ] Task 1
- [ ] Task 2
- [ ] Task 3

---

## Task 1 : [Titre court et précis]

**Fichier :** `src/lib/pricing.ts`
**Test :** `src/lib/pricing.test.ts`
**Durée estimée :** 3 min

**Test RED à écrire :**
```typescript
it('applies 10% discount for premium users', () => {
  expect(applyDiscount(100, 'premium')).toBe(90)
})
```

**Code GREEN à implémenter :**
```typescript
export function applyDiscount(price: number, tier: UserTier): number {
  if (tier === 'premium') return price * 0.9
  return price
}
```

**Vérification :**
```bash
npx vitest run src/lib/pricing.test.ts
```

**Commit :** `feat: add applyDiscount with premium tier support`

---

## Task 2 : ...
```

---

## Règles de rédaction

### Granularité

```
✅ "Ajouter la validation du format email dans registerUser"
✅ "Créer le hook useCart qui expose addItem/removeItem/total"
❌ "Implémenter le panier"  → trop large
❌ "Ajouter un if"          → trop petit, ne pas planifier
```

### Code exact — pas de pseudocode

```typescript
// ❌ Pseudocode
// function validateEmail(email) {
//   check format
//   return boolean
// }

// ✅ Code TypeScript complet
export function validateEmail(email: string): boolean {
  return /^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(email)
}
```

### Commits conventionnels par tâche

Chaque tâche a son propre commit. Ne pas regrouper plusieurs tâches en un seul commit.

```bash
# ✅ Un commit par tâche
git commit -m "feat: add validateEmail"
git commit -m "feat: add registerUser with email validation"
git commit -m "test: add integration test for user registration flow"
```

### YAGNI — Supprimer le superflu

```typescript
// ❌ Ne pas ajouter ce qui n'est pas dans le plan
// - Logging non demandé
// - Méthodes "utiles pour plus tard"
// - Configurations supplémentaires

// ✅ Strict minimum pour satisfaire le test GREEN
```

---

## Processus de création d'un plan

### 1. Lire et comprendre

```bash
# Lire les fichiers concernés
cat src/lib/payment.ts
cat src/lib/payment.test.ts

# Comprendre les patterns existants
grep -r "createOrder\|processPayment" src/ --include="*.ts" | head -20
```

### 2. Identifier les tâches

```
Feature : "Ajouter un système de remises"

Tâches identifiées :
1. applyDiscount(price, tier) — pure function (3 min)
2. getDiscountRate(userId) — appel BDD (4 min)
3. Ajouter discount au calcul dans processOrder (5 min)
4. Test d'intégration du flow complet (4 min)
```

### 3. Ordonner par dépendances

```
1 → 2 → 3 (chaque tâche dépend de la précédente)
4 peut être fait en parallèle avec 3 si le schéma est stable
```

### 4. Vérifier que chaque tâche est 2-5 min

Si une tâche est > 5 min → décomposer davantage.

---

## Exemple complet

```markdown
# Plan : Système de remises par tier utilisateur

**Date :** 2024-01-15
**Scope :** Appliquer des remises (premium -10%, trial -0%) lors du calcul de commande
**Fichiers :** `src/lib/discount.ts`, `src/server/order.service.ts`

## Statuts
- [ ] Task 1 — applyDiscount pure function
- [ ] Task 2 — getDiscountRate depuis BDD
- [ ] Task 3 — Intégrer dans processOrder
- [ ] Task 4 — Test d'intégration end-to-end

---

## Task 1 : applyDiscount — pure function

**Fichier :** `src/lib/discount.ts`
**Test :** `src/lib/discount.test.ts`
**Durée :** 3 min

**Test RED :**
```typescript
describe('applyDiscount', () => {
  it('applies 10% for premium', () => expect(applyDiscount(100, 'premium')).toBe(90))
  it('applies 0% for standard', () => expect(applyDiscount(100, 'standard')).toBe(100))
  it('rounds to 2 decimals', () => expect(applyDiscount(9.99, 'premium')).toBe(8.99))
})
```

**Code GREEN :**
```typescript
export type UserTier = 'premium' | 'standard' | 'trial'
const RATES: Record<UserTier, number> = { premium: 0.9, standard: 1, trial: 1 }
export function applyDiscount(price: number, tier: UserTier): number {
  return Math.round(price * (RATES[tier] ?? 1) * 100) / 100
}
```

**Vérification :** `npx vitest run src/lib/discount.test.ts`
**Commit :** `feat: add applyDiscount pure function with tier-based rates`
```

---

## Intégration avec les autres skills

| Skill | Rôle |
|-------|------|
| `tdd-enforcement` | Chaque tâche = 1 cycle RED-GREEN-REFACTOR |
| `verification-before-completion` | Chaque tâche inclut sa commande de vérification |
| `/tools/execute-plan` | Exécute ce plan par batches de 3 tâches |
