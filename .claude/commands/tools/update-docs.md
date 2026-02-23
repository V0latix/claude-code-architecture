---
description: "Synchronise la documentation avec le code actuel. Détecte les divergences entre le code et la doc, met à jour ce qui est obsolète."
allowed-tools: Bash, Read, Write, Edit, Grep, Glob, Task
---

# Update Documentation

Synchronisation docs/code pour : **$ARGUMENTS**

## Instructions

### 1. Détecter les divergences

Comparer le code et la documentation existante :

```bash
# Lister les endpoints dans le code
grep -r "router\.\(get\|post\|put\|patch\|delete\)" --include="*.ts" -n

# Comparer avec la doc API si elle existe
cat docs/api-reference.md 2>/dev/null || echo "Pas de doc API"

# Fonctions exportées non documentées
grep -r "^export " --include="*.ts" | grep -v "node_modules"
```

### 2. Identifier ce qui est obsolète

Chercher dans la doc des références à :
- Fonctions qui n'existent plus
- Routes supprimées
- Paramètres changés
- Exemples de code cassés

### 3. Mettre à jour

Utiliser le `doc-writer` agent pour :
1. Corriger les informations obsolètes
2. Ajouter la documentation manquante
3. Supprimer les sections obsolètes
4. Mettre à jour le CHANGELOG

### 4. Vérifier les exemples de code

```bash
# Vérifier que les exemples TypeScript dans la doc compilent
npx ts-node --eval "$(grep -A5 '\`\`\`typescript' docs/*.md | grep -v '\`\`\`')" 2>&1
```

### Rapport de mise à jour

```markdown
## Documentation mise à jour

### Ajouts
- ...

### Corrections
- ...

### Suppressions
- ...
```
