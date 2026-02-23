---
description: "Analyse un repo existant et génère toute la documentation de contexte (CLAUDE.md, CONTEXT.md par module, architecture, ADRs, onboarding). Produit un contexte riche qui sera automatiquement chargé par les futures sessions Claude pour maximiser leur efficacité."
allowed-tools: Bash, Read, Write, Edit, Grep, Glob, Task
---

# Repo Context Generation

Analyse et génération du contexte pour : **$ARGUMENTS**

> **Objectif** : Comprendre un repo existant en profondeur et générer les fichiers de contexte
> qui seront chargés automatiquement par Claude à chaque future session.
> Le résultat est un "cerveau documentaire" qui permet à Claude de travailler
> sur ce projet sans avoir à re-découvrir l'architecture à chaque fois.

---

## Phase 1 — Exploration du codebase

Lancer en **parallèle** avec Task les 3 agents d'exploration :

### `analyst agent` (skills: architecture-diagrams, prompt-engineering)
Analyser le **domaine métier** :
- Quel problème ce projet résout-il ?
- Qui sont les utilisateurs cibles ?
- Quels sont les concepts métier clés (entités, vocabulaire, règles) ?
- Quels sont les flux utilisateur principaux ?

```bash
# Comprendre le domaine
cat README.md 2>/dev/null | head -100
cat package.json | grep -E '"name"|"description"'
ls src/app/ 2>/dev/null | head -20          # Routes = domaines métier
ls src/server/ 2>/dev/null | head -20       # Services = entités métier
cat prisma/schema.prisma 2>/dev/null | head -80  # Modèles = ontologie
```

### `architect agent` (skills: api-design, database-patterns, architecture-diagrams, async-patterns, auth-patterns)
Analyser l'**architecture technique** :
- Stack réel (pas seulement package.json — vérifier comment il est utilisé)
- Patterns utilisés (Repository, CQRS, Event-driven, etc.)
- Structure des dossiers et conventions
- Points d'entrée API (routes, actions serveur)
- Schéma de données (Prisma ou autre)
- Mécanisme d'auth
- Gestion des erreurs (Result type ? Exceptions ? Codes d'erreur ?)
- Tests (stratégie, coverage, frameworks)

```bash
# Stack réel
cat package.json | grep -E '"dependencies|devDependencies"' -A 50 | head -80
cat tsconfig.json 2>/dev/null

# Conventions de code
ls src/ 2>/dev/null
find src -name "*.ts" -not -path "*/node_modules/*" | head -30
grep -r "^export " src/ --include="*.ts" -l 2>/dev/null | head -20

# API surface
find src/app/api -name "route.ts" 2>/dev/null | head -20
grep -r "use server" src/ --include="*.ts" -l 2>/dev/null | head -10

# Auth
grep -r "getServerSession\|auth()\|getSession\|useSession\|middleware" \
  src/ --include="*.ts" --include="*.tsx" -l 2>/dev/null | head -10

# Schéma BDD
cat prisma/schema.prisma 2>/dev/null || \
  find . -name "schema.prisma" 2>/dev/null | head -2

# Tests
find src -name "*.test.ts" -o -name "*.spec.ts" 2>/dev/null | wc -l
cat vitest.config.ts 2>/dev/null || cat jest.config.ts 2>/dev/null
```

### `developer agent` (skills: async-patterns, testing-patterns, error-handling-patterns, database-patterns)
Analyser les **patterns de code et conventions** :
- Convention de nommage (camelCase, PascalCase, kebab-case...)
- Style de code (TypeScript strict ? any autorisé ?)
- Patterns async (Promise, async/await, observables...)
- Gestion des erreurs (throw, Result type, codes d'erreur...)
- Organisation des imports
- Patterns de test (AAA, factories, mocks...)

```bash
# TypeScript strict mode
cat tsconfig.json | grep -E "strict|noImplicitAny"

# Exemples de code réels (pour comprendre les patterns)
find src -name "*.service.ts" 2>/dev/null | head -3 | xargs cat 2>/dev/null | head -100
find src -name "*.repository.ts" 2>/dev/null | head -2 | xargs cat 2>/dev/null | head -80
find src -name "*.test.ts" 2>/dev/null | head -2 | xargs cat 2>/dev/null | head -80

# Eslint config
cat .eslintrc* 2>/dev/null || cat eslint.config* 2>/dev/null | head -40

# Prettier
cat .prettierrc* 2>/dev/null | head -20

# Imports alias
cat tsconfig.json | grep -E "paths|baseUrl"
```

---

## Phase 2 — Synthèse et génération des fichiers

Après avoir collecté toutes les informations, utiliser le `doc-writer agent` (skills: architecture-diagrams, api-design) pour générer les fichiers suivants :

---

### 2.1 — CLAUDE.md (fichier principal de contexte)

> Ce fichier est **chargé automatiquement** par Claude à chaque session.
> Il doit être dense, précis et actionnable — pas bavard.

Créer ou remplacer `CLAUDE.md` avec ce template adapté au projet :

```markdown
# Projet : [NOM RÉEL DU PROJET]

## Stack technique

- Language : [TypeScript strict / JavaScript / autre]
- Framework : [Next.js 15 App Router / Express / autre]
- Base de données : [PostgreSQL + Prisma / MongoDB / autre]
- Tests : [Vitest / Jest] + [Testing Library / autre]
- Style : [Tailwind CSS / CSS Modules / autre]
- Auth : [NextAuth / Clerk / Auth.js / autre]

## Domaine métier

[2-3 phrases décrivant ce que fait le projet et pour qui]

### Entités clés
- `[Entité1]` — [description courte]
- `[Entité2]` — [description courte]

### Vocabulaire du domaine
- **[terme]** : [définition métier]

## Conventions de code

- TypeScript : [strict / non-strict] — [any autorisé ? non-null assertions ?]
- Noms de fichiers : [kebab-case / camelCase]
- Imports : [absolus avec @/ / relatifs]
- Gestion d'erreurs : [Result type / throw / codes d'erreur]
- Commits : [conventional commits / autre]

## Architecture des dossiers

```
src/
├── app/           → [Routes Next.js App Router / description si différent]
│   └── api/       → [Route handlers]
├── components/    → [Composants React réutilisables]
│   ├── ui/        → [Composants atomiques]
│   └── features/  → [Composants de feature]
├── lib/           → [Utilitaires, helpers, clients]
├── server/        → [Logique serveur]
│   ├── actions/   → [Server Actions Next.js]
│   ├── services/  → [Logique métier]
│   └── repositories/ → [Accès aux données]
└── types/         → [Types TypeScript partagés]
```

## Points d'entrée importants

- Auth : `[chemin vers la config auth]`
- Middleware : `[chemin vers middleware.ts]`
- DB Client : `[chemin vers prisma client]`
- Env vars : `[chemin vers env.ts ou équivalent]`

## Patterns à respecter

### Gestion d'erreurs
[Décrire le pattern utilisé dans le projet avec exemple]

### Accès aux données
[Décrire si Repository pattern, accès direct Prisma, etc.]

### Authentification
[Comment vérifier l'auth dans les routes/actions]

## Routing des agents

| Tâche | Agent |
|-------|-------|
| Feature UI | `use frontend-specialist agent` |
| Feature backend | `use developer agent` |
| Architecture | `use architect agent` |
| Tests | `use qa-engineer agent` |
| Sécurité | `use security-auditor agent` |
| LLM/IA | `use ai-engineer agent` |

## Règles importantes

- [Règle spécifique au projet 1]
- [Règle spécifique au projet 2]
- Ne jamais modifier `.env`, `.env.*`
- Chaque PR doit inclure des tests
```

---

### 2.2 — CONTEXT.md par module

Pour chaque répertoire significatif dans `src/` (server, components, lib...), créer un `CONTEXT.md` :

```markdown
# Module : [nom du module]

## Responsabilité
[Ce module est responsable de...]

## Structure interne
```
[module]/
├── [fichier].ts   → [rôle]
├── [fichier].ts   → [rôle]
└── index.ts       → [exports publics]
```

## Patterns utilisés
- [pattern] : [comment et où]

## Dépendances clés
- Dépend de : `[modules internes]`, `[packages externes clés]`
- Utilisé par : `[qui consomme ce module]`

## Conventions spécifiques
- [convention propre à ce module]

## Points d'attention
- [gotcha 1]
- [gotcha 2]
```

---

### 2.3 — docs/architecture.md

Documenter l'architecture réelle découverte :

```markdown
# Architecture Technique

## Vue d'ensemble
[Diagramme C4 ou Mermaid de l'architecture globale]

## Stack technique
[Table avec technologie + version + justification réelle]

## Architecture en couches
[Diagramme des couches réelles du projet]

## Flux de données principaux
[Les 2-3 flux les plus importants du projet]

## Patterns architecturaux utilisés
[Avec exemples de code réels tirés du projet]

## ADRs (Architecture Decision Records)
[Liste des décisions documentées dans /docs/decisions/]
```

---

### 2.4 — ADRs pour les décisions découvertes

Pour chaque décision architecturale significative trouvée dans le code, créer un ADR dans `docs/decisions/` :

```bash
# Trouver le prochain numéro ADR
ls docs/decisions/ 2>/dev/null | grep -oE "^[0-9]+" | sort -n | tail -1
```

Créer un ADR pour chaque décision identifiée :
- Choix de framework/bibliothèque importante
- Pattern architectural adopté
- Stratégie d'auth
- Structure de BDD notable
- Stratégie de tests

---

### 2.5 — docs/onboarding.md

Guide pour un nouveau développeur ou une nouvelle session Claude :

```markdown
# Guide d'onboarding

## En 5 minutes

1. **Comprendre le projet** : [description en 1 phrase]
2. **Lancer localement** :
   ```bash
   [commandes pour démarrer]
   ```
3. **Première tâche recommandée** : [fichier facile à explorer]

## Architecture en bref

[Résumé en 5-10 bullet points des décisions clés]

## Où trouver quoi

| Je veux... | Je regarde... |
|------------|---------------|
| Logique métier | `src/server/services/` |
| Accès BDD | `src/server/repositories/` |
| Routes API | `src/app/api/` |
| Composants | `src/components/` |
| Types | `src/types/` |
| Tests | `*.test.ts` à côté des fichiers |

## Conventions importantes

[Top 5 des conventions à respecter absolument]

## Pièges à éviter

- [Piège 1 identifié dans le code]
- [Piège 2]

## Pour aller plus loin

- Architecture complète : `docs/architecture.md`
- Décisions : `docs/decisions/`
- Variables d'environnement : `.env.example`
```

---

## Phase 3 — Rapport de génération

```markdown
# Contexte généré pour : $ARGUMENTS

## Fichiers créés/mis à jour

| Fichier | Statut | Description |
|---------|--------|-------------|
| `CLAUDE.md` | ✅ Créé | Contexte principal — chargé automatiquement |
| `src/CONTEXT.md` | ✅ Créé | Contexte module src/ |
| `src/server/CONTEXT.md` | ✅ Créé | Contexte module server |
| `src/components/CONTEXT.md` | ✅ Créé | Contexte module components |
| `docs/architecture.md` | ✅ Mis à jour | Architecture réelle |
| `docs/project-structure.md` | ✅ Mis à jour | Structure du projet |
| `docs/onboarding.md` | ✅ Créé | Guide nouveau développeur |
| `docs/decisions/00X-*.md` | ✅ Créé | X ADRs pour les décisions clés |
| `.env.example` | ✅ Mis à jour | Variables d'env documentées |

## Résumé du projet analysé

**Nom** : [nom]
**Domaine** : [description courte]
**Stack** : [tech stack réel]
**Taille** : [X fichiers TS, Y composants, Z routes API]
**Tests** : [X fichiers de test, coverage estimée]

## Points d'attention identifiés

- ⚠️ [Dette technique ou point d'attention 1]
- ⚠️ [Point d'attention 2]

## Prochaines étapes suggérées

1. Relire `CLAUDE.md` et ajuster si besoin
2. Compléter les sections [X] marquées avec `[TODO]`
3. Lancer `/tools/env-check` pour valider `.env.example`
4. Lancer `/tools/deps-audit` pour vérifier les dépendances
5. Lancer `/workflows/code-review` sur le module principal
```
