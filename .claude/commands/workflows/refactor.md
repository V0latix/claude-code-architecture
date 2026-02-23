---
description: "Refactoring intelligent avec préservation du comportement. Analyse le code, propose un plan de refactoring, l'exécute et vérifie que les tests passent."
allowed-tools: Bash, Read, Write, Edit, Grep, Glob, Task
---

# Refactoring Intelligent

Refactoring de : **$ARGUMENTS**

## Règle fondamentale

**Ne jamais changer le comportement observable.** Les tests doivent passer avant et après.

## Phase 1 — Analyse (developer + architect agents)

### 1.1 Mesurer l'état actuel

```bash
# Lancer les tests existants et noter le résultat
npm test -- --coverage

# Vérifier les métriques de qualité
npx ts-prune  # Dead code
npx madge --circular src/  # Dépendances circulaires
```

### 1.2 Identifier les problèmes

Analyser `$ARGUMENTS` pour :
- Code dupliqué (DRY violations)
- Fonctions trop longues (> 20 lignes)
- Complexité cyclomatique élevée (> 10)
- Couplage fort entre modules
- Nommage peu clair
- Dépendances circulaires
- Code mort ou non utilisé

### 1.3 Prioriser les opportunités

Classer par rapport effort/impact.

## Phase 2 — Plan de refactoring

Proposer un plan avec ces étapes :

```markdown
## Plan de Refactoring — $ARGUMENTS

### Étape 1 : [Nom]
- Problème : ...
- Solution : ...
- Risque : Faible/Moyen/Élevé
- Tests impactés : ...

### Étape 2 : [Nom]
...
```

**Valider le plan avant de commencer l'implémentation.**

## Phase 3 — Exécution

Pour chaque étape du plan :

1. Vérifier que les tests passent au départ
2. Appliquer le refactoring
3. Vérifier que les tests passent toujours
4. Commit avec message clair : `refactor: [description]`

Techniques de refactoring à appliquer :
- Extract Function / Extract Variable
- Rename (clarifier les noms)
- Move Function (meilleure cohésion)
- Replace Conditional with Polymorphism
- Introduce Parameter Object
- Replace Magic Number with Named Constant

## Phase 4 — Validation finale

```bash
# Tous les tests doivent passer
npm test

# Pas de régression de couverture
npm test -- --coverage

# TypeScript strict
npm run type-check

# Lint
npm run lint
```

## Rapport final

```markdown
## Refactoring Effectué — $ARGUMENTS

### Changements appliqués
- ...

### Métriques avant/après
| Métrique | Avant | Après |
|---------|-------|-------|
| Complexité cyclomatique | X | X |
| Lignes de code | X | X |
| Couverture tests | X% | X% |
| Code dupliqué | X% | X% |

### Tests : ✅ Tous passent (X/X)
```
