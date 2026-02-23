---
description: "Refactoring intelligent avec préservation du comportement. Analyse le code, mesure les métriques, propose un plan structuré, exécute et valide que tests et performances sont préservés."
allowed-tools: Bash, Read, Write, Edit, Grep, Glob, Task
---

# Refactoring Intelligent

Refactoring de : **$ARGUMENTS**

## Règle fondamentale

**Ne jamais changer le comportement observable.** Les tests doivent passer avant et après. Les performances ne doivent pas régresser.

## Phase 1 — Mesures de référence

```bash
# 1. Tests — état actuel (doit être vert avant de commencer)
npm test -- --coverage 2>&1 | tail -20

# 2. TypeScript — aucune erreur de type
npm run type-check 2>&1 | tail -10

# 3. Dépendances circulaires
npx madge --circular src/ 2>/dev/null | head -20

# 4. Code mort
npx ts-prune 2>/dev/null | grep -v "__" | head -20

# 5. Complexité cyclomatique
npx complexity-report --format json src/ 2>/dev/null | \
  python3 -c "import json,sys; d=json.load(sys.stdin); [print(f\"{r['cyclomatic']} {r['path']}\") for r in sorted(d['reports'], key=lambda x: -x['cyclomatic'])[:10]]" 2>/dev/null || true
```

## Phase 2 — Analyse multi-agents (lancer avec Task)

### `developer agent` (skills: async-patterns, testing-patterns, error-handling-patterns, database-patterns)
Analyser `$ARGUMENTS` pour :
- Code dupliqué (DRY violations, fonctions similaires)
- Fonctions trop longues (> 20 lignes = candidat à l'extraction)
- Complexité cyclomatique élevée (> 10)
- Gestion d'erreurs incomplète (ajouter Result type si absent)
- Patterns async incorrects (await en boucle, unhandled promises)
- Nommage peu clair (variables/fonctions cryptiques)

### `architect agent` (skills: api-design, database-patterns, architecture-diagrams, async-patterns)
Analyser l'architecture de `$ARGUMENTS` pour :
- Couplage fort entre modules (SRP violations)
- Dépendances circulaires
- Mauvais placement de logique (business logic dans les controllers ?)
- Schéma de données optimisable (N+1, index manquants)
- Abstractions prématurées ou manquantes

### `performance-engineer agent` (skills: async-patterns, database-patterns, observability-patterns)
Mesurer et analyser les performances de `$ARGUMENTS` :
- Appels I/O séquentiels convertibles en parallèle
- Requêtes en boucle (N+1 patterns)
- Objets alloués inutilement (pressure GC)
- Imports lourds qui ralentissent le startup

### `security-auditor agent` (skills: security-scanning, auth-patterns, error-handling-patterns)
Profiter du refactoring pour :
- Éliminer les patterns dangereux détectés
- Renforcer la gestion d'erreurs (ne pas exposer de détails internes)
- Ajouter la validation manquante

## Phase 3 — Plan de refactoring

Consolider les analyses et créer un plan ordonné :

```markdown
## Plan de Refactoring — $ARGUMENTS

### Étape 1 : [Nom court] — Risque : Faible/Moyen/Élevé
- Problème : [Description précise avec fichier:ligne]
- Technique : [Extract Function / Move / Rename / etc.]
- Tests impactés : [Oui/Non — lesquels]
- Skill utile : [async-patterns / error-handling-patterns / etc.]

### Étape 2 : ...

### Ordre d'exécution (du moins risqué au plus risqué)
```

## Phase 4 — Exécution itérative

Pour chaque étape du plan :

```bash
# Avant chaque modification
npm test -- --silent 2>&1 | tail -3  # Doit être "X passed"

# Après modification
npm test -- --silent 2>&1 | tail -3  # Doit être identique ou meilleur
npm run type-check 2>&1 | grep "error" | wc -l  # Doit être 0
```

**Techniques selon la skill activée :**

- **`error-handling-patterns`** → Remplacer try/catch verbeux par Result type, créer hiérarchie d'erreurs
- **`async-patterns`** → Convertir les await séquentiels en Promise.all, ajouter retry logic
- **`database-patterns`** → Éliminer N+1 avec include/select Prisma, ajouter index manquants
- **`testing-patterns`** → Refactoriser les tests vers le pattern AAA avec builders

Commit après chaque étape réussie :
```bash
git add -p  # Stager seulement les changements de l'étape
git commit -m "refactor: [description de l'étape]"
```

## Phase 5 — Validation finale

```bash
# Tests complets
npm test -- --coverage

# Performance : comparer avec le benchmark de départ
# (si performance-engineer a défini un benchmark)

# TypeScript strict
npm run type-check

# Lint
npm run lint

# Vérifier qu'il n'y a pas de nouvelles dépendances circulaires
npx madge --circular src/ 2>/dev/null
```

## Rapport final

```markdown
## Refactoring Effectué — $ARGUMENTS

### Techniques appliquées
| Étape | Technique | Skill utilisée |
|-------|-----------|----------------|
| 1 | Extract Function (getUserById) | - |
| 2 | Result type pour processPayment | error-handling-patterns |
| 3 | Promise.all sur 3 appels API | async-patterns |
| 4 | Élimination N+1 (orders + items) | database-patterns |

### Métriques avant/après
| Métrique | Avant | Après | Delta |
|---------|-------|-------|-------|
| Complexité cyclomatique max | X | X | -X |
| Lignes de code | X | X | -X% |
| Couverture tests | X% | X% | +X% |
| Dépendances circulaires | X | 0 | ✅ |
| Latence p95 (si mesuré) | Xms | Xms | -X% |

### Tests : ✅ X/X passent
### TypeScript : ✅ 0 erreur
### Prêt pour review : `/workflows/code-review $ARGUMENTS`
```
