---
description: "Génère ou met à jour le CHANGELOG.md depuis l'historique git avec commits conventionnels. Supporte le versioning sémantique et groupe les changements par type."
allowed-tools: Bash, Read, Write, Edit, Glob, Task
---

# Changelog

Génération du CHANGELOG pour : **$ARGUMENTS**

> Si `$ARGUMENTS` est vide, génère depuis le dernier tag jusqu'à HEAD.
> Si `$ARGUMENTS` est une version (ex: `v1.2.0`), génère le diff entre cette version et la précédente.

## Instructions

### 1. Analyser l'historique git

```bash
# Récupérer le dernier tag (version précédente)
LAST_TAG=$(git describe --tags --abbrev=0 2>/dev/null || echo "")
echo "Dernier tag : $LAST_TAG"

# Commits depuis le dernier tag (ou les 100 derniers si pas de tag)
if [ -n "$LAST_TAG" ]; then
  git log ${LAST_TAG}..HEAD --pretty=format:"%h %s" --no-merges
else
  git log --pretty=format:"%h %s" --no-merges | head -100
fi
```

```bash
# Statistiques des types de commits
git log ${LAST_TAG}..HEAD --pretty=format:"%s" --no-merges 2>/dev/null | \
  grep -oE "^(feat|fix|chore|docs|refactor|test|perf|style|ci|build|revert)" | \
  sort | uniq -c | sort -rn
```

### 2. Déterminer la prochaine version

En suivant le **Semantic Versioning** (semver) :

| Type de commit | Impact version |
|----------------|---------------|
| `feat:` | MINOR (0.X.0) |
| `fix:` | PATCH (0.0.X) |
| `feat!:` ou `BREAKING CHANGE:` | MAJOR (X.0.0) |
| `chore:`, `docs:`, `test:` | Pas de bump |

```bash
# Version actuelle
cat package.json | grep '"version"' | head -1
```

### 3. Générer le CHANGELOG

Utiliser le `doc-writer agent` pour créer/mettre à jour `CHANGELOG.md` avec ce format :

```markdown
# Changelog

Toutes les modifications notables de ce projet sont documentées ici.
Format basé sur [Keep a Changelog](https://keepachangelog.com/fr/1.0.0/).

## [Unreleased]

## [X.Y.Z] — YYYY-MM-DD

### ✨ Nouvelles fonctionnalités
- Description claire de la feature ([#123](lien-pr)) — @auteur

### 🐛 Corrections
- Fix du bug de connexion en production ([abc1234](lien-commit))

### ⚡ Améliorations de performance
- Optimisation des requêtes BDD (-40% p95)

### 🔒 Sécurité
- Mise à jour de [package] (CVE-XXXX-XXXX)

### 🔧 Maintenance
- Mise à jour des dépendances
- Refactoring du module auth

### 📚 Documentation
- Ajout des exemples d'API

### ⚠️ Breaking Changes
- `oldFunction()` supprimée → utiliser `newFunction()` à la place

---
[Unreleased]: https://github.com/org/repo/compare/vX.Y.Z...HEAD
[X.Y.Z]: https://github.com/org/repo/compare/vX.Y.Y...vX.Y.Z
```

### 4. Mettre à jour package.json

```bash
# Si une nouvelle version est déterminée
# npm version [patch|minor|major] --no-git-tag-version
echo "Version suggérée calculée, à appliquer manuellement"
```

### 5. Vérification

```bash
# S'assurer que le CHANGELOG.md est valide
cat CHANGELOG.md | head -30

# Commits non classifiés (sans préfixe conventionnel)
git log ${LAST_TAG}..HEAD --pretty=format:"%s" --no-merges | \
  grep -vE "^(feat|fix|chore|docs|refactor|test|perf|style|ci|build|revert|merge)" | head -10
```
