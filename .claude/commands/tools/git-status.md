---
description: "Git status enrichi avec analyse des changements, suggestions de message de commit et détection des problèmes potentiels avant un commit."
allowed-tools: Bash, Read, Grep
---

# Git Status Enrichi

## Instructions

Exécuter une analyse complète de l'état git du projet.

### 1. État actuel

```bash
git status --short
git diff --stat HEAD
```

### 2. Analyse des changements

```bash
# Voir les changements détaillés
git diff HEAD

# Fichiers stagés
git diff --cached --stat
```

### 3. Vérifications pré-commit

```bash
# Y a-t-il des secrets potentiels ?
git diff HEAD | grep -iE "(api_key|secret|password|token|private_key)" || echo "Aucun secret détecté"

# Y a-t-il des fichiers sensibles modifiés ?
git status --short | grep -E "(.env|package-lock.json|.pem|.key)" || echo "Aucun fichier sensible"

# Tests qui passent ?
npm test --silent 2>&1 | tail -5
```

### 4. Suggestion de message de commit

Sur la base des changements, proposer un message de commit au format conventionnel :

```
type(scope): description courte

- détail 1
- détail 2

Refs: #[issue-number]
```

**Types** : `feat`, `fix`, `docs`, `style`, `refactor`, `test`, `chore`, `ci`, `perf`

### 5. Rapport

```markdown
## Git Status — $(date)

### Fichiers modifiés : X
### Fichiers ajoutés : X
### Fichiers supprimés : X

### Changements notables
- ...

### Avertissements
- ...

### Message de commit suggéré
```[type]([scope]): [description]```

### Prêt pour commit : ✅ / ⚠️ / ❌
```
