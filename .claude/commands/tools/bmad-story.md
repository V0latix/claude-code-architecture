---
description: "Crée une user story BMAD complète et prête pour le développement (ready-for-dev). Analyse le contexte du projet, l'épic parent et les stories existantes pour générer une story autonome avec toutes les informations nécessaires à l'implémentation."
allowed-tools: Bash, Read, Write, Edit, Grep, Glob, Task
---

# BMAD Story Creator

Création de story BMAD pour : **$ARGUMENTS**

> Une story BMAD est **autonome** : elle contient tout le contexte pour être implémentée
> sans que le developer agent ait besoin d'aller chercher d'informations ailleurs.

---

## Instructions

Utiliser le `scrum-master agent` pour créer la story.

### 1. Charger le contexte

```bash
# Contexte obligatoire
cat docs/project-context.md 2>/dev/null || echo "⚠️ project-context.md manquant"
cat docs/architecture.md 2>/dev/null | head -60

# Trouver l'épic parent
ls docs/epic-*.md 2>/dev/null
# Demander à l'utilisateur quel épic si pas évident

# Analyser les stories existantes pour les patterns
ls docs/stories/ 2>/dev/null | sort | tail -5
# Lire la dernière story complète pour comprendre le niveau de détail attendu
```

### 2. Analyser l'épic parent

```bash
cat docs/epic-[N].md
```

Extraire :
- Objectif métier de l'épic
- Stories déjà créées (pour numérotation et dépendances)
- Critères d'acceptation de l'épic à couvrir

### 3. Déterminer le numéro de story

```bash
ls docs/stories/epic-[N]-story-*.md 2>/dev/null | sort | tail -1
# Incrémenter le numéro
```

### 4. Prévention des disasters (avant de créer)

Vérifier ces points critiques :

```bash
# La fonctionnalité existe-t-elle déjà ?
grep -r "$ARGUMENTS" src/ --include="*.ts" -l 2>/dev/null | head -10

# Y a-t-il déjà des fichiers à modifier ?
# (identifier les chemins exacts à utiliser dans Dev Notes)
find src -name "*.ts" | xargs grep -l "[mot-clé-feature]" 2>/dev/null | head -5

# Tests existants liés ?
find src -name "*.test.ts" | xargs grep -l "[mot-clé]" 2>/dev/null | head -5

# Git log pour patterns similaires
git log --oneline --grep="[mot-clé]" 2>/dev/null | head -5
```

### 5. Créer la story

Créer `docs/stories/epic-[N]-story-[M].md` en utilisant ce template :

```markdown
# Story [N].[M]: [Titre descriptif]

**Status**: ready-for-dev
**Epic**: [N] — [Titre de l'épic]
**Estimation**: [S/M/L]
**Priorité**: [haute/moyenne/basse]

---

## Story

As a **[rôle utilisateur]**, I want **[action à réaliser]**, so that **[bénéfice obtenu]**.

---

## Acceptance Criteria

1. **[Critère 1]** : [Description mesurable et vérifiable]
2. **[Critère 2]** : [Description mesurable et vérifiable]
3. **[Critère 3]** : [Description mesurable et vérifiable]

---

## Tasks / Subtasks

- [ ] **Task 1** : [Description] (AC: #1)
  - [ ] Subtask 1.1 : [Détail précis]
  - [ ] Subtask 1.2 : [Détail précis]
- [ ] **Task 2** : [Description] (AC: #2)
  - [ ] Subtask 2.1 : [Détail précis]
- [ ] **Task 3** : Tests (AC: tous)
  - [ ] Tests unitaires pour [composant]
  - [ ] Tests d'intégration pour [flux]
  - [ ] Mise à jour des tests existants si besoin

---

## Dev Notes

> Ces notes sont extraites de `docs/architecture.md` et `docs/project-context.md`.
> Le developer agent ne doit pas avoir à chercher ces informations ailleurs.

### Patterns à utiliser

- **Error handling** : [Pattern exact tiré de project-context.md]
- **Auth** : [Comment vérifier les permissions pour cette story]
- **Async** : [Pattern async à utiliser]
- **TypeScript** : Strict mode, pas de `any`

### Fichiers à créer / modifier

| Fichier | Action | Notes |
|---------|--------|-------|
| `src/[chemin]/[fichier].ts` | Créer/Modifier | [Ce qui change exactement] |
| `src/[chemin]/[fichier].test.ts` | Créer/Modifier | [Tests à ajouter] |
| `prisma/schema.prisma` | Modifier (si BDD) | [Modèles à ajouter/modifier] |

### Contraintes d'implémentation

- [Contrainte 1 tirée de project-context.md]
- [Contrainte 2 : pas de régression sur X]
- [Contrainte 3 : respecter le pattern Y]

### Dépendances

- **Dépend de** : Story [N].[M-1] (si applicable)
- **Bloque** : Story [N].[M+1] (si applicable)

### Project Structure Notes

- Alignement avec la structure existante : [chemin/conventions]
- Conflits détectés : Aucun / [description si applicable]

### References

- [Source: docs/architecture.md#Section]
- [Source: docs/project-context.md#Patterns]
- [Source: docs/epic-[N].md#Criteria]

---

## Non inclus (scope guard)

> Ces éléments sont explicitement hors scope de cette story.

- [Élément 1 hors scope]
- [Élément 2 hors scope — traité dans story [N].[M+X]]

---

## Dev Agent Record

*(À remplir par le developer agent pendant l'implémentation)*

### Agent Model Used
[à compléter]

### Debug Log References
[à compléter]

### Completion Notes
[à compléter]

### File List (Actual)
[à compléter]
```

### 6. Valider la story (checklist rapide)

Avant de livrer la story, vérifier selon `docs/bmad/checklists/story-creation.md` :

- [ ] La story ne réinvente pas l'existant
- [ ] Les chemins de fichiers sont exacts (vérifiés avec `find`)
- [ ] Les bonnes versions de bibliothèques sont référencées
- [ ] Les AC sont mesurables et vérifiables
- [ ] Les Tasks couvrent tous les AC (référence `AC: #N`)
- [ ] Les Dev Notes contiennent les patterns exacts de `project-context.md`
- [ ] Le scope guard est défini
- [ ] Status = `ready-for-dev`
