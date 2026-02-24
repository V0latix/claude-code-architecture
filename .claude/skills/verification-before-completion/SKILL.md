---
name: verification-before-completion
description: "Enforcement des preuves fraîches avant toute déclaration de succès : relancer les commandes, coller la sortie réelle, ne jamais présumer du résultat. Activer systématiquement avant de marquer une tâche comme terminée."
license: MIT
---

# Verification Before Completion

## Quand utiliser cette skill

- Avant de déclarer "c'est terminé" ou "ça fonctionne"
- Avant de marquer une tâche comme `completed`
- Avant tout commit ou push
- Après avoir corrigé un bug ou implémenté une feature

## Loi de fer

> **AUCUNE DÉCLARATION DE SUCCÈS SANS PREUVE FRAÎCHE.**
> Relancer les commandes dans la session courante. Ne jamais présumer du résultat sur la base d'une exécution passée ou d'une lecture du code.

---

## Checklist de vérification obligatoire

Avant de déclarer une tâche terminée, exécuter **toutes** les commandes applicables et coller leur sortie :

```bash
# 1. Tests — doit afficher le nombre de tests qui passent
npx vitest run 2>&1 | tail -20

# 2. TypeScript — doit afficher "Found 0 errors"
npx tsc --noEmit 2>&1

# 3. Lint — doit afficher 0 warnings et 0 errors
npx eslint src/ --max-warnings 0 2>&1 | tail -10

# 4. Build (si applicable) — doit réussir sans erreur
npm run build 2>&1 | tail -20
```

**Format de réponse attendu :**
```
✅ Tests : 42 passed (0 failed) — npx vitest run
✅ TypeScript : 0 errors — npx tsc --noEmit
✅ Lint : 0 warnings — npx eslint src/
✅ Build : succeeded in 3.2s
```

---

## Règles détaillées

### 1. Fraîcheur des preuves

Les résultats doivent venir de la **session courante**, après les dernières modifications.

```bash
# ❌ Invalide : résultat d'une exécution précédente
# "J'ai lancé les tests tout à l'heure et ça passait"

# ✅ Valide : relancer maintenant
npx vitest run
# [coller la sortie]
```

### 2. Scope de vérification

Vérifier ce qui est **réellement affecté** par les changements, pas seulement le fichier modifié.

```bash
# Si la modification touche src/lib/auth.ts → vérifier aussi les tests d'intégration
npx vitest run src/lib/auth.test.ts src/server/api/auth.test.ts

# Si la modification touche le schéma Prisma → vérifier les migrations
npx prisma validate
npx prisma migrate dev --name check
```

### 3. Erreurs partielles

Si une commande échoue partiellement :

```bash
# ❌ Déclarer terminé si certains tests passent mais d'autres échouent
# ✅ Lister explicitement les échecs et ne pas déclarer terminé

# Format en cas d'échec :
# ❌ Tests : 40 passed, 2 FAILED
#    - auth.test.ts > should refresh token → AssertionError
#    - user.test.ts > should delete account → Timeout
# → Tâche NON terminée, poursuite nécessaire
```

### 4. Builds incrémentaux

Les builds incrémentaux peuvent cacher des erreurs réelles. Forcer un build clean si nécessaire.

```bash
# Pour un build clean (supprimer le cache)
rm -rf .next dist
npm run build
```

---

## Patterns anti-vérification à éviter

```typescript
// ❌ "Le code semble correct donc ça devrait marcher"
// ❌ "J'ai testé mentalement, ça va"
// ❌ "C'était vert tout à l'heure avant ma dernière modif"
// ❌ "Le TypeScript compile probablement, j'ai pas changé les types"
// ❌ "Les tests d'intégration prennent longtemps, je les passe"

// ✅ Relancer, coller la sortie, déclarer terminé seulement si tout est vert
```

---

## Intégration avec d'autres skills

- **`tdd-enforcement`** — Vérification à chaque étape RED → GREEN → REFACTOR
- **`systematic-debugging`** — Vérification que le test de reproduction échoue bien (Phase 1) et passe bien (Phase 4)
- **`writing-plans`** — Chaque tâche du plan inclut sa commande de vérification

---

## Modèle de rapport de completion

```markdown
## Tâche X — Terminée ✅

**Changements :** `src/lib/payment.ts` — ajout de la vérification de solde

**Preuves :**
- Tests : `npx vitest run` → 38 passed, 0 failed
- TypeScript : `npx tsc --noEmit` → 0 errors
- Lint : `npx eslint src/` → 0 warnings
- Commit : `git commit -m "feat: add balance check before payment"`

**Prochaine tâche :** Task 3 — Ajouter les notifications email
```
