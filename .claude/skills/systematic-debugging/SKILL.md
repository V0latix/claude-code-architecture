---
name: systematic-debugging
description: "Méthodologie de débogage en 4 phases avec root cause obligatoire : investigation, analyse de patterns, test d'hypothèse, implémentation. Activer pour tout bug, régression ou comportement inattendu avant de toucher au code."
license: MIT
---

# Systematic Debugging

## Quand utiliser cette skill

- Bug rapporté ou régression détectée
- Comportement inattendu en production ou en test
- Erreur dont l'origine n'est pas immédiatement claire
- Test flaky à stabiliser

## Loi de fer

> **AUCUN FIX SANS ROOT CAUSE IDENTIFIÉE.**
> Si la cause racine n'est pas claire après la Phase 1, continuer à investiguer — ne pas commencer à coder.

---

## Phase 1 — Investigation Root Cause

**Objectif :** Comprendre exactement pourquoi le bug se produit.

```bash
# 1. Reproduire le bug de façon fiable
npx vitest run --reporter=verbose 2>&1 | head -50

# 2. Lire la stack trace complète — ne pas ignorer les frames "internes"
# 3. Remonter le data flow depuis le point d'échec
# 4. Inspecter l'état au moment de l'échec
git log --oneline -20 -- src/path/to/file.ts   # quand ça a changé
git show <commit-sha> -- src/path/to/file.ts   # lire le contexte du changement
```

**Questions à répondre avant de passer à la suite :**
- À quel endroit précis le comportement diverge-t-il de ce qui est attendu ?
- Depuis quand ? (git bisect si nécessaire)
- Dans quelles conditions exactes se produit-il ?

```typescript
// Pattern : écrire un test qui reproduit le bug EXACTEMENT
it('reproduces bug #123: balance goes negative on concurrent refunds', async () => {
  const user = await createUser({ balance: 10 })
  // Simuler les conditions exactes de l'incident
  await Promise.all([
    processRefund(user.id, 8),
    processRefund(user.id, 8),
  ])
  const updated = await getUser(user.id)
  expect(updated.balance).toBeGreaterThanOrEqual(0) // RED : doit échouer
})
```

---

## Phase 2 — Analyse de Patterns

**Objectif :** Trouver un pattern similaire qui fonctionne, pour comprendre ce qui diffère.

```bash
# Chercher le même pattern ailleurs dans le codebase
grep -r "processRefund\|updateBalance" src/ --include="*.ts"

# Comparer avec un cas similaire qui fonctionne
git log --all --oneline --grep="refund" | head -10

# Vérifier si le problème existe dans d'autres contextes
grep -r "race condition\|concurrent\|lock" src/ --include="*.ts"
```

**Questions :**
- Y a-t-il un endroit dans le code où ce problème est déjà géré correctement ?
- Qu'est-ce qui est différent entre le cas qui fonctionne et celui qui échoue ?

---

## Phase 3 — Test d'Hypothèse

**Objectif :** Valider une seule hypothèse à la fois avant d'implémenter.

**Règle :** Changer une seule variable par hypothesis test. Jamais deux.

```typescript
// Hypothèse : le problème est un race condition sans transaction
// Test : ajouter un log pour confirmer l'ordre d'exécution
async function processRefund(userId: string, amount: number) {
  console.log(`[DEBUG] START refund ${amount} for ${userId} at ${Date.now()}`)
  const user = await db.user.findUnique({ where: { id: userId } })
  console.log(`[DEBUG] READ balance: ${user?.balance}`)
  // ...
}
// Relancer le test → confirmer que les deux refunds lisent le même solde initial
```

**Si l'hypothèse est invalidée** → revenir à Phase 1 avec les nouvelles informations.

---

## Phase 4 — Implémentation

**Objectif :** Corriger la root cause identifiée, pas le symptôme.

```typescript
// Correction : utiliser une transaction pour atomicité
async function processRefund(userId: string, amount: number) {
  return db.$transaction(async (tx) => {
    const user = await tx.user.findUnique({
      where: { id: userId },
      // Lock optimiste via version ou pessimiste selon le contexte
    })
    if (!user || user.balance < amount) {
      throw new InsufficientBalanceError(userId, amount)
    }
    return tx.user.update({
      where: { id: userId },
      data: { balance: { decrement: amount } },
    })
  })
}

// Vérifier que le test de reproduction passe maintenant
// npx vitest run → GREEN ✅
```

---

## Red Flags — Stopper immédiatement si

- **Modifier plusieurs fichiers simultanément** sans avoir identifié la root cause
- **"Ça devrait fonctionner maintenant"** sans avoir relancé les tests
- **Fixer le symptôme** (ex: mettre `balance = 0` si négatif) au lieu de la cause (race condition)
- **Ignorer une partie de la stack trace** parce qu'elle semble "interne"
- **git blame sans lire le contexte** — lire le commit complet et le PR associé

---

## Anti-patterns

```typescript
// ❌ Fix symptôme sans root cause
if (balance < 0) balance = 0  // Le race condition existe toujours

// ❌ Multiple hypothèses simultanées
// Changement 1 : ajouter transaction
// Changement 2 : changer le type de lock
// Changement 3 : ajouter retry logic
// → impossible de savoir ce qui a résolu le problème

// ✅ Une seule hypothèse, validée par le test de reproduction
// Test RED → hypothesis → corriger → test GREEN → commit
```

---

## Temps estimés

| Approche | Durée typique |
|----------|--------------|
| Débogage aléatoire (trial & error) | 2-4 heures |
| Débogage systématique (4 phases) | 15-45 minutes |

La Phase 1 est la plus longue — investir du temps ici divise le temps total par 4-8.
