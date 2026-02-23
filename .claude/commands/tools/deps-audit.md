---
description: "Audit des dépendances npm : vulnérabilités de sécurité, packages obsolètes et licences incompatibles. Génère un rapport priorisé avec recommandations de mise à jour."
allowed-tools: Bash, Read, Write, Edit, Grep, Glob, Task
---

# Deps Audit

Audit des dépendances pour : **$ARGUMENTS**

## Instructions

### 1. Vulnérabilités de sécurité

```bash
# Audit npm natif
npm audit --json 2>/dev/null | head -200

# Compter par sévérité
npm audit 2>/dev/null | tail -5
```

### 2. Packages obsolètes

```bash
# Packages avec mise à jour disponible
npm outdated 2>/dev/null

# Packages non maintenus (dernière release > 2 ans)
cat package.json | grep -E '"dependencies"|"devDependencies"' -A 100 | head -60
```

### 3. Analyse de la surface de dépendances

```bash
# Compter les dépendances directes
cat package.json | grep -c '"' 

# Dépendances inutilisées (si depcheck disponible)
npx depcheck --json 2>/dev/null | head -50

# Taille des dépendances lourdes (si bundle-phobia disponible)
ls node_modules --sort=size -lh 2>/dev/null | tail -20
```

### 4. Vérification des licences

```bash
# Licences déclarées
npx license-checker --summary 2>/dev/null || \
  cat node_modules/*/package.json 2>/dev/null | grep '"license"' | sort | uniq -c | sort -rn | head -20
```

Utiliser le `security-auditor agent` pour analyser les résultats et identifier :
- Licences incompatibles avec le projet (GPL dans un projet propriétaire, etc.)
- Packages avec CVE critique ou haute
- Packages abandonnés avec des alternatives recommandées

### 5. Rapport de sortie

Générer `docs/deps-audit-report.md` :

```markdown
# Rapport d'audit des dépendances

**Date** : [date]
**Projet** : [nom]

## Résumé

| Criticité | Nombre |
|-----------|--------|
| 🔴 Critique | X |
| 🟠 Haute | X |
| 🟡 Modérée | X |
| 🟢 Faible | X |

## Vulnérabilités de sécurité

### 🔴 Critiques
- `package@version` — CVE-XXXX-XXXX — [description courte]
  - **Fix** : `npm install package@safe-version`

### 🟠 Hautes
- ...

## Packages obsolètes

| Package | Actuel | Latest | Action recommandée |
|---------|--------|--------|-------------------|
| ... | ... | ... | Mise à jour mineure / Majeure avec breaking changes |

## Licences

| Licence | Packages | Compatibilité |
|---------|----------|---------------|
| MIT | X | ✅ Compatible |
| GPL-3.0 | X | ⚠️ Vérifier |

## Actions recommandées

### Priorité 1 — Immédiat (sécurité)
1. `npm install [package]@[safe-version]`

### Priorité 2 — Cette semaine (mises à jour mineures)
```bash
npm update
```

### Priorité 3 — Prochain sprint (majeures avec breaking changes)
- ...
```
