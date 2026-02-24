---
description: "Génère un plan d'implémentation granulaire dans docs/plans/YYYY-MM-DD-[feature].md. Décompose la feature en tâches TDD de 2-5 minutes avec code exact, tests RED/GREEN et commits. Utilise writing-plans + tdd-enforcement."
allowed-tools: Bash, Read, Write, Edit, Grep, Glob, Task
---

# Write Plan

Création d'un plan d'implémentation pour : **$ARGUMENTS**

## Instructions

Utilise le `developer` agent avec les skills `writing-plans` et `tdd-enforcement` pour créer un plan granulaire.

### 1. Analyser le contexte

Lire les fichiers concernés par la feature :

```bash
# Trouver les fichiers liés
grep -r "$ARGUMENTS" src/ --include="*.ts" -l 2>/dev/null | head -10
ls src/lib/ src/server/ src/components/ 2>/dev/null
```

Comprendre l'architecture existante avant de planifier.

### 2. Identifier et ordonner les tâches

Pour chaque tâche :
- Durée : 2-5 minutes (1 cycle RED-GREEN-REFACTOR)
- 1 fichier principal + 1 fichier test
- Code exact (pas de pseudocode)
- 1 commit par tâche

### 3. Générer le fichier plan

Créer `docs/plans/YYYY-MM-DD-$ARGUMENTS.md` avec ce format :

```markdown
# Plan : [Titre de la feature]

**Date :** YYYY-MM-DD
**Scope :** [résumé 1 ligne]
**Fichiers principaux :** [liste]

## Contexte

[Pourquoi cette feature ? Quel problème résout-elle ?]

## Statuts
- [ ] Task 1 — [titre]
- [ ] Task 2 — [titre]
- [ ] Task 3 — [titre]

---

## Task 1 : [Titre précis]

**Fichier :** `src/lib/[feature].ts`
**Test :** `src/lib/[feature].test.ts`
**Durée :** X min

**Test RED :**
```typescript
it('[comportement attendu]', () => {
  // test complet et exécutable
})
```

**Code GREEN :**
```typescript
// implémentation minimale
```

**Vérification :**
```bash
npx vitest run src/lib/[feature].test.ts
```

**Commit :** `feat: [description courte]`

---

## Task 2 : ...

## Checklist finale
- [ ] `npx vitest run` → 0 failed
- [ ] `npx tsc --noEmit` → 0 errors
- [ ] `npx eslint src/` → 0 warnings
- [ ] Documentation mise à jour si nécessaire
```

### 4. Créer le dossier si nécessaire

```bash
mkdir -p docs/plans
```

### 5. Afficher un résumé

Après génération, afficher :
- Nombre de tâches créées
- Durée totale estimée
- Chemin du fichier généré
- Commande pour exécuter : `/tools/execute-plan docs/plans/YYYY-MM-DD-$ARGUMENTS.md`
