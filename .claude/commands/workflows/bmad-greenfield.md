---
description: "Workflow BMAD complet pour un nouveau projet (greenfield). Orchestre les 4 phases de A à Z : Analyse → Planning → Solutioning → Implémentation. Produit tous les artifacts BMAD et guide le développement story par story jusqu'au déploiement."
allowed-tools: Bash, Read, Write, Edit, Grep, Glob, Task
---

# BMAD — Workflow Greenfield (Nouveau Projet)

Développement BMAD pour : **$ARGUMENTS**

> **Méthode BMAD** : Chaque phase produit des artifacts qui nourrissent la suivante.
> Le projet avance uniquement quand les gates de qualité sont validés.

---

## 🔍 Détection du contexte

```bash
echo "=== Détection des artifacts BMAD existants ==="
ls docs/*.md 2>/dev/null
ls docs/stories/ 2>/dev/null | head -20
cat docs/project-brief.md 2>/dev/null | head -3
cat docs/prd.md 2>/dev/null | head -3
cat docs/architecture.md 2>/dev/null | head -3
```

> **Si des artifacts existent déjà**, reprendre à la phase correspondante.
> **Si le projet est existant**, utiliser `/workflows/feature-dev` à la place.

---

## PHASE 1 — Analyse 🧠

### `analyst agent` (skills: architecture-diagrams, prompt-engineering)

**Objectif** : Comprendre le problème, valider les hypothèses, créer la vision stratégique.

#### 1.1 — Brainstorming & Discovery

Conduire un entretien structuré avec l'utilisateur :

```
Questions clés à poser :
- Quel problème ce projet résout-il ?
- Qui sont les utilisateurs cibles ? (personas)
- Quelles sont les alternatives existantes ?
- Quelle est la proposition de valeur unique ?
- Quelles sont les contraintes clés (temps, budget, tech) ?
- Quel est le critère de succès minimal (MVP) ?
```

#### 1.2 — Créer `docs/project-brief.md`

Utiliser le template `docs/bmad/templates/project-brief-tmpl.md`.

Sections obligatoires :
- Résumé exécutif (1 paragraphe)
- Problème et contexte
- Utilisateurs cibles et personas
- Proposition de valeur
- Périmètre MVP (Must / Should / Could / Won't)
- Hypothèses à valider
- Contraintes et risques

**✅ Gate Phase 1** : `docs/project-brief.md` créé et validé par l'utilisateur.

---

## PHASE 2 — Planning 📋

### `product-manager agent` (skills: architecture-diagrams, prompt-engineering)

**Prérequis** : `docs/project-brief.md` ✅

**Objectif** : Transformer la vision en exigences précises, mesurables et priorisées.

#### 2.1 — Créer `docs/prd.md`

```bash
cat docs/project-brief.md
```

Utiliser le template `docs/bmad/templates/prd-tmpl.md`.

Sections obligatoires :
- Objectifs produit & métriques de succès (KPIs)
- Personas et user journeys
- Fonctionnalités par épic (avec priorité MoSCoW)
- Exigences non-fonctionnelles (perf, sécurité, accessibilité)
- Hors périmètre (explicite)
- Critères d'acceptation par feature
- Dépendances et risques

#### 2.2 — Créer `docs/front-end-spec.md` (si UI)

### `ux-expert agent` (skills: frontend-frameworks, architecture-diagrams)

*(Uniquement si le projet a une composante interface utilisateur)*

```bash
cat docs/prd.md
```

Utiliser le template `docs/bmad/templates/front-end-spec-tmpl.md`.

Sections :
- Architecture frontend (routing, state management)
- Design system (tokens, composants clés)
- Wireframes / maquettes ASCII des écrans principaux
- Flux utilisateur (parcours complets)
- Points d'attention accessibilité (WCAG 2.1 AA)
- Conventions de nommage composants

**✅ Gate Phase 2** : `docs/prd.md` créé, revu et approuvé.

---

## PHASE 3 — Solutioning 🏗️

**Prérequis** : `docs/prd.md` ✅

### 3.1 — Architecture

### `architect agent` (skills: api-design, database-patterns, docker-k8s, architecture-diagrams, observability-patterns, auth-patterns, async-patterns)

```bash
cat docs/prd.md
cat docs/front-end-spec.md 2>/dev/null
```

#### Créer `docs/architecture.md`

Utiliser le template `docs/bmad/templates/architecture-tmpl.md`.

Sections obligatoires :
- Diagramme C4 (contexte + conteneurs)
- Stack technique avec justifications
- Architecture en couches (avec diagramme Mermaid)
- Schéma de données (si BDD)
- Design des APIs (endpoints principaux)
- Stratégie d'authentification & autorisation
- Gestion des erreurs (pattern choisi)
- Observabilité (logs, métriques, traces)
- ADRs pour les décisions clés

#### Créer `docs/project-context.md`

> **Ce fichier est la "constitution" du projet** — il sera chargé par tous les agents à chaque session.

```markdown
# Project Context

## Stack & Versions
[Versions exactes de toutes les dépendances clés]

## Règles d'implémentation critiques
[Règles TypeScript, patterns de code, conventions]

## Structure des fichiers
[Conventions de nommage, où créer quoi]

## Patterns obligatoires
[Error handling, auth checks, async patterns, testing]

## Ce qu'il NE FAUT PAS faire
[Anti-patterns identifiés, pièges du projet]
```

### 3.2 — Épics & Stories

### `scrum-master agent` (skills: architecture-diagrams)

```bash
cat docs/prd.md
cat docs/architecture.md
cat docs/project-context.md
```

#### Créer les épics (`docs/epic-N.md`)

Utiliser le template `docs/bmad/templates/epic-tmpl.md`.

Pour chaque épic :
- Titre et objectif métier
- User stories de haut niveau
- Critères d'acceptation de l'épic
- Dépendances avec les autres épics
- Ordre de développement suggéré

#### Créer les stories initiales (`docs/stories/epic-N-story-M.md`)

Utiliser le template `docs/bmad/templates/story-tmpl.md`.

Chaque story doit être **autonome** : contenir tout le contexte pour être implémentée sans chercher ailleurs.

Structure obligatoire :
```
# Story [N].[M]: [Titre]
Status: ready-for-dev

## Story
As a [rôle], I want [action], so that [bénéfice].

## Acceptance Criteria
1. ...

## Tasks / Subtasks
- [ ] Task 1 (AC: #1)
  - [ ] Subtask 1.1

## Dev Notes
[Contexte technique tiré de architecture.md et project-context.md]

### References
[Source: docs/architecture.md#Section]
```

### 3.3 — 🚦 Gate : Implementation Readiness Check

### `architect agent` + `product-manager agent`

```bash
cat docs/architecture.md
cat docs/prd.md
ls docs/epic-*.md
ls docs/stories/
```

Évaluer selon `docs/bmad/checklists/implementation-readiness.md` :

**Verdict** :
- ✅ **PASS** → Phase 4 autorisée
- ⚠️ **CONCERNS** → Documenter dans `docs/architecture.md#known-concerns`, continuer
- ❌ **FAIL** → Retourner en Phase 3 pour corriger

**✅ Gate Phase 3** : Implementation Readiness = PASS ou CONCERNS documentés.

---

## PHASE 4 — Implémentation 💻

**Prérequis** : Gate Phase 3 validé ✅

### 4.1 — Sprint Planning

### `scrum-master agent`

```bash
cat docs/epic-1.md
ls docs/stories/
```

Initialiser le tracking :
- Prioriser les stories par valeur / dépendances
- Créer `docs/sprint-backlog.md` avec l'ordre d'implémentation

### 4.2 — Boucle de développement par story

Pour **chaque story** dans l'ordre du backlog :

#### Étape A — Préparer la story

### `scrum-master agent` (commande `CS`)

```bash
cat docs/project-context.md
cat docs/architecture.md
cat docs/epic-[N].md
ls docs/stories/
```

- Vérifier que la story est complète (checklist `docs/bmad/checklists/story-creation.md`)
- Compléter les `Dev Notes` avec les références exactes aux fichiers
- Mettre le status à `ready-for-dev`
- Identifier les fichiers à toucher

#### Étape B — Implémenter la story

### `developer agent` (skills: async-patterns, testing-patterns, api-design, database-patterns, error-handling-patterns, auth-patterns) (commande `DS`)

```bash
cat docs/project-context.md          # La constitution — toujours charger en premier
cat docs/stories/epic-[N]-story-[M].md
cat docs/architecture.md
```

Règles d'implémentation :
1. **TDD** — écrire les tests AVANT le code
2. **TypeScript strict** — aucun `any`
3. **Respecter les patterns** de `project-context.md`
4. **Mettre à jour la story** au fur et à mesure :
   - Cocher les tasks
   - Remplir `## Dev Agent Record` (fichiers modifiés, notes)
5. **Ne pas déborder** du scope de la story

Quand terminé, mettre `Status: complete` dans la story.

#### Étape C — Code Review

### `code-reviewer agent` (commande `CR`)

```bash
cat docs/stories/epic-[N]-story-[M].md
git diff main...HEAD --stat
```

Vérifier selon `docs/bmad/checklists/story-dod.md` :
- Code correspond aux acceptance criteria ?
- Tests passent ? Coverage suffisant ?
- Patterns de `project-context.md` respectés ?
- Pas de régression introduite ?
- Documentation mise à jour ?

**Si review FAIL** → retourner à l'Étape B avec les corrections.

#### Étape D — Tests E2E (si applicable)

### `qa-engineer agent` (skills: testing-patterns) (commande `QA`)

*(Exécuter après completion d'un épic entier)*

- Générer les tests Playwright pour les parcours critiques de l'épic
- S'assurer que les critères d'acceptation de l'épic sont couverts

### 4.3 — Gestion des imprévus (Correct Course)

Si blocage ou changement de scope en cours de sprint :

### `product-manager agent` + `scrum-master agent` (commande `CC`)

```bash
cat docs/prd.md
cat docs/epic-[N].md
cat docs/stories/epic-[N]-story-[M].md
```

- Évaluer l'impact sur le scope
- Modifier la story ou créer une nouvelle
- Ne JAMAIS modifier `docs/prd.md` ni `docs/architecture.md` sans gate explicite

### 4.4 — Rétrospective d'épic

### `scrum-master agent` (commande `ER`) — après chaque épic

```bash
git log --oneline --since="[date début épic]"
ls docs/stories/epic-[N]-*.md | xargs grep "Status:" 
```

Produire `docs/retrospective-epic-[N].md` :
- Ce qui a bien fonctionné
- Ce qui a été difficile
- Patterns découverts à ajouter à `project-context.md`
- Améliorations pour l'épic suivant

**Mettre à jour `docs/project-context.md`** avec les nouveaux patterns appris.

---

## Rapport de livraison finale

```markdown
# Projet BMAD Livré : $ARGUMENTS

## Phases complétées
- [x] Phase 1 — Analyse (docs/project-brief.md)
- [x] Phase 2 — Planning (docs/prd.md)
- [x] Phase 3 — Solutioning (docs/architecture.md + X épics)
- [x] Phase 4 — Implémentation (X stories livrées)

## Artifacts générés
| Document | Chemin |
|----------|--------|
| Project Brief | docs/project-brief.md |
| PRD | docs/prd.md |
| Front-end Spec | docs/front-end-spec.md |
| Architecture | docs/architecture.md |
| Project Context | docs/project-context.md |
| Épics | docs/epic-1.md ... epic-N.md |
| Stories | docs/stories/ (X fichiers) |

## Statistiques
- Épics : X
- Stories : Y (Z complètes)
- Tests : A unitaires, B intégration, C E2E
- Coverage : X%

## Prochaines étapes
- [ ] Déploiement : `/workflows/new-project-setup` pour CI/CD
- [ ] Sécurité : `/workflows/security-audit`
- [ ] Performance : `/workflows/performance-audit`
```
