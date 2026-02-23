---
description: "Workflow BMAD pour un projet existant (brownfield). Commence par la découverte du contexte existant avant de créer les artifacts manquants et d'intégrer une nouvelle feature ou un refactoring via la boucle story BMAD."
allowed-tools: Bash, Read, Write, Edit, Grep, Glob, Task
---

# BMAD — Workflow Brownfield (Projet Existant)

Feature / amélioration à intégrer : **$ARGUMENTS**

> **Brownfield** = le projet a déjà du code, des patterns, une architecture.
> L'objectif est de s'y intégrer proprement, sans casser l'existant,
> en utilisant les conventions déjà établies.

---

## Étape 0 — Diagnostic BMAD

Avant tout, vérifier ce qui existe :

```bash
echo "=== BMAD Brownfield Diagnostic ==="

echo "--- Artifacts BMAD existants ---"
[ -f docs/project-brief.md ]    && echo "✅ project-brief.md" || echo "⬜ project-brief.md"
[ -f docs/prd.md ]               && echo "✅ prd.md" || echo "⬜ prd.md"
[ -f docs/architecture.md ]      && echo "✅ architecture.md" || echo "⬜ architecture.md"
[ -f docs/project-context.md ]   && echo "✅ project-context.md (constitution)" || echo "⚠️ project-context.md MANQUANT — critique"
[ -f CLAUDE.md ]                 && echo "✅ CLAUDE.md" || echo "⬜ CLAUDE.md"
ls docs/epic-*.md 2>/dev/null    && echo "✅ Épics trouvés" || echo "⬜ Pas d'épics"
ls docs/stories/ 2>/dev/null     && echo "✅ Stories trouvées" || echo "⬜ Pas de stories"

echo "--- Codebase ---"
cat package.json | grep '"version"' | head -1
find src -name "*.ts" 2>/dev/null | wc -l
find src -name "*.test.ts" -o -name "*.spec.ts" 2>/dev/null | wc -l
git log --oneline -5 2>/dev/null
```

**Décision selon le diagnostic** :

| Situation | Action |
|-----------|--------|
| `project-context.md` existe | → Étape 2 directement |
| Pas de `project-context.md` mais `architecture.md` existe | → Étape 1B |
| Rien n'existe | → Étape 1A complète (`/workflows/repo-context` recommandé en parallèle) |

---

## Étape 1A — Génération du contexte (si inexistant)

### `architect agent` + `developer agent` en parallèle

*(Sauter si `docs/project-context.md` existe déjà)*

#### 1A.1 — Découverte de l'architecture réelle

```bash
# Stack réel
cat package.json | grep -E '"(dependencies|devDependencies)"' -A 40 | head -60
cat tsconfig.json 2>/dev/null

# Patterns de code existants
find src -name "*.service.ts" | head -3 | xargs cat 2>/dev/null | head -80
find src -name "*.repository.ts" | head -2 | xargs cat 2>/dev/null | head -60
find src -name "*.test.ts" | head -2 | xargs cat 2>/dev/null | head -60

# Auth
grep -r "getServerSession\|auth()\|middleware" src/ --include="*.ts" -l 2>/dev/null | head -5

# Error handling pattern
grep -r "Result\|AppError\|throw new" src/ --include="*.ts" -l 2>/dev/null | head -5

# Prisma schema
cat prisma/schema.prisma 2>/dev/null | head -60
```

#### 1A.2 — Créer `docs/project-context.md`

```markdown
# Project Context — [Nom du projet]
> Généré le [date] via bmad-brownfield

## Technology Stack & Versions
- [Versions exactes]

## Critical Implementation Rules

### TypeScript
- [Strict mode ? any autorisé ?]
- [Conventions de nommage]

### Code Organization
- [Où créer les composants, services, etc.]
- [Conventions de nommage fichiers]

### Patterns Obligatoires
- Error handling : [Result type / throw / codes]
- Auth : [Comment vérifier les permissions]
- DB access : [Direct Prisma / Repository pattern]
- Async : [Patterns utilisés]

### Testing
- [Framework, patterns, où mettre les tests]
- [Coverage minimum]

### Ce qu'il NE FAUT PAS faire
- [Anti-patterns observés dans le code existant]
- [Pièges identifiés]
```

#### 1A.3 — Mettre à jour ou créer `docs/architecture.md`

*(Utiliser `/workflows/repo-context` pour une version complète)*

---

## Étape 1B — Vérification de cohérence (si architecture partielle)

### `architect agent`

*(Uniquement si `architecture.md` existe mais est incomplet ou potentiellement obsolète)*

```bash
cat docs/architecture.md
# Comparer avec le code réel
find src -name "route.ts" | head -10
cat prisma/schema.prisma 2>/dev/null | grep "^model" | head -20
git log --oneline --since="30 days ago" | head -20
```

Identifier les divergences entre la doc et le code réel et mettre `architecture.md` à jour.

---

## Étape 2 — Analyser la demande

### `analyst agent` (skills: architecture-diagrams, prompt-engineering)

```bash
cat docs/project-context.md
cat docs/prd.md 2>/dev/null || echo "Pas de PRD existant"
cat docs/architecture.md 2>/dev/null | head -80
```

Cadrer la demande `$ARGUMENTS` :

**Questions à répondre** :
- Cette demande est-elle dans le périmètre du PRD existant ? (si PRD existe)
- Quel(s) module(s) existants sont touchés ?
- Y a-t-il des dépendances sur des stories/épics existants ?
- La demande nécessite-t-elle un changement d'architecture ? (→ gate architect)
- Périmètre : 1 composant (Quick Flow) ou plusieurs (Full Flow) ?

**Décision d'aiguillage** :

| Critère | Recommandation |
|---------|---------------|
| < 1 composant, comportement clair | → `/workflows/bmad-quick` |
| 1-2 services, exigences claires | → Étape 3 (story directe) |
| Feature cross-composant | → Étape 3 avec épic |
| Changement architectural | → Revoir `docs/architecture.md` d'abord |

---

## Étape 3 — Créer / mettre à jour l'épic (si nécessaire)

### `product-manager agent` (skills: architecture-diagrams)

*(Sauter si la feature s'intègre dans un épic existant)*

```bash
ls docs/epic-*.md 2>/dev/null | xargs grep "## Titre" 2>/dev/null
cat docs/prd.md 2>/dev/null | head -40
```

Créer `docs/epic-[N].md` selon le template `docs/bmad/templates/epic-tmpl.md`.

S'assurer de :
- Aligner l'épic sur le PRD existant (pas de scope creep)
- Identifier les dépendances avec les épics existants
- Numéroter correctement (suite des épics existants)

---

## Étape 4 — Créer la story

### `scrum-master agent` (skills: architecture-diagrams) (commande `CS`)

```bash
cat docs/project-context.md          # Toujours en premier
cat docs/architecture.md
cat docs/epic-[N].md
# Analyser les stories existantes pour comprendre les patterns
ls docs/stories/ 2>/dev/null
cat docs/stories/epic-[N-1]-story-1.md 2>/dev/null | head -40   # Exemple de story complète
```

Créer `docs/stories/epic-[N]-story-[M].md` selon `docs/bmad/templates/story-tmpl.md`.

**Attention brownfield** — dans les `Dev Notes`, toujours inclure :
- Les fichiers existants à modifier (avec leur chemin exact)
- Les patterns existants à respecter (avec exemples du code actuel)
- Les tests existants à mettre à jour
- Les éventuelles migrations BDD nécessaires
- Les edge cases liés à l'existant

Valider avec la checklist `docs/bmad/checklists/story-creation.md` :
- La story ne réinvente pas une fonctionnalité existante ?
- Les bonnes versions/bibliothèques sont référencées ?
- Les bons chemins de fichiers sont indiqués ?
- Pas de risque de régression identifié ?

---

## Étape 5 — Boucle d'implémentation

*(Identique à la Phase 4 du workflow Greenfield)*

### Étape 5A — Implémenter

### `developer agent` (commande `DS`)

```bash
cat docs/project-context.md          # La constitution — TOUJOURS en premier
cat docs/stories/epic-[N]-story-[M].md
```

Règles **supplémentaires pour brownfield** :
- Analyser les tests existants avant d'écrire les nouveaux
- Ne pas changer le comportement de l'existant sans l'indiquer explicitement dans la story
- Suivre exactement les patterns de `project-context.md`
- Faire tourner la suite de tests existante après chaque changement

```bash
npm test 2>/dev/null || npx vitest run 2>/dev/null
npm run type-check 2>/dev/null
npm run lint 2>/dev/null
```

### Étape 5B — Code Review

### `code-reviewer agent` (commande `CR`)

```bash
git diff main...HEAD --stat
cat docs/stories/epic-[N]-story-[M].md
cat docs/project-context.md
```

Vérifications **spécifiques brownfield** :
- Cohérence avec les patterns existants (`project-context.md`)
- Aucune régression sur les features existantes
- Tests existants toujours au vert
- Pas de dépendance ajoutée sans justification

### Étape 5C — Mise à jour de `project-context.md`

Si des nouveaux patterns ont émergé pendant l'implémentation :

```bash
# Ajouter les nouvelles conventions découvertes
# Documenter les pièges rencontrés
# Mettre à jour les chemins de fichiers si structure modifiée
```

---

## Rapport brownfield

```markdown
# Feature BMAD Brownfield : $ARGUMENTS

## Contexte intégré
- project-context.md : ✅ Utilisé / ✅ Mis à jour
- architecture.md : ✅ Cohérent / ⚠️ Mis à jour

## Stories livrées
| Story | Status | Fichiers modifiés |
|-------|--------|------------------|
| epic-N-story-M | complete | X fichiers |

## Impact sur l'existant
- Régressions : Aucune / [liste si applicable]
- Patterns mis à jour dans project-context.md : Oui / Non
- Migrations BDD : Oui ([fichier]) / Non

## Prochaines étapes
- [ ] Review sécurité : `/workflows/security-audit`
- [ ] Tests de non-régression : `npm test`
```
