# Projet : [NOM DU PROJET]

## Stack technique

- Language : TypeScript strict
- Framework : Next.js 15 App Router
- Base de données : PostgreSQL + Prisma ORM
- Tests : Vitest + Testing Library
- Style : Tailwind CSS + Prettier + ESLint flat config

## Conventions de code

- Pas de `any` TypeScript
- Composants fonctionnels uniquement
- Noms de fichiers en kebab-case
- Imports absolus avec alias `@/`
- Commits en format conventionnel (feat, fix, chore, docs, refactor, test)

## Architecture des dossiers

- `/src/app` → Routes Next.js (App Router)
- `/src/components` → Composants réutilisables
- `/src/lib` → Utilitaires et helpers
- `/src/server` → Logique serveur (actions, API)
- `/prisma` → Schéma et migrations BDD
- `/docs` → Documentation projet
- `/docs/decisions` → Architecture Decision Records (ADR)

## Routing des agents

### Agents fondamentaux (disponibles dans tout projet)

| Tâche | Agent | Skills activées |
|-------|-------|-----------------|
| Brainstorming, recherche, briefs | `use analyst agent` | architecture-diagrams, prompt-engineering |
| Design système, choix tech, ADR | `use architect agent` | api-design, database-patterns, docker-k8s, architecture-diagrams, observability-patterns, auth-patterns, async-patterns |
| Implémentation, debugging, refactoring | `use developer agent` | async-patterns, testing-patterns, api-design, database-patterns, error-handling-patterns, auth-patterns |
| Tests, qualité, couverture | `use qa-engineer agent` | testing-patterns, error-handling-patterns, async-patterns |
| Audit sécurité, SAST, compliance | `use security-auditor agent` | security-scanning, auth-patterns, error-handling-patterns, api-design |
| CI/CD, Docker, Kubernetes, infra | `use devops-engineer agent` | docker-k8s, observability-patterns, mcp-builder, security-scanning, incident-response |
| Code review multi-critères | `use code-reviewer agent` | async-patterns, testing-patterns, security-scanning, error-handling-patterns, database-patterns, auth-patterns |
| PRD, spécifications, roadmap | `use product-manager agent` | architecture-diagrams, prompt-engineering |
| Stories, sprints, agile | `use scrum-master agent` | architecture-diagrams |
| UI/UX, wireframes, design | `use ux-expert agent` | frontend-frameworks, architecture-diagrams |
| Documentation technique | `use doc-writer agent` | architecture-diagrams, api-design, document-processing |

### Agents spécialisés (selon les besoins du projet)

| Tâche | Agent | Skills activées |
|-------|-------|-----------------|
| Applications LLM, RAG, chatbots, agents IA | `use ai-engineer agent` | llm-ai-patterns, prompt-engineering, async-patterns, api-design, testing-patterns |
| Analyse de données, ML, statistiques | `use data-scientist agent` | data-engineering, database-patterns, async-patterns, testing-patterns |
| Profiling, optimisation, benchmarks | `use performance-engineer agent` | async-patterns, database-patterns, observability-patterns, error-handling-patterns |
| Applications React Native / Flutter | `use mobile-developer agent` | frontend-frameworks, async-patterns, testing-patterns, security-scanning |
| Incidents production, postmortems | `use incident-responder agent` | incident-response, observability-patterns, error-handling-patterns, docker-k8s |
| Implémentation React/Next.js (code) | `use frontend-specialist agent` | frontend-frameworks, async-patterns, testing-patterns, auth-patterns, error-handling-patterns |

## Commandes disponibles

### Workflows

- `/workflows/full-context` — Analyse multi-agents complète d'une feature
- `/workflows/code-review` — Review parallèle par 5 agents spécialisés
- `/workflows/feature-dev` — Développement feature end-to-end
- `/workflows/security-audit` — Audit sécurité complet (OWASP Top 10)
- `/workflows/refactor` — Refactoring intelligent avec métriques before/after
- `/workflows/ai-feature` — Développement feature IA/LLM (RAG, agent, chatbot)
- `/workflows/performance-audit` — Profiling, benchmarks, optimisation DB et I/O
- `/workflows/incident-postmortem` — Triage incident, résolution, postmortem blameless
- `/workflows/new-project-setup` — Scaffold complet d'un nouveau projet
- `/workflows/data-pipeline` — Pipeline ELT, dbt, qualité des données, Airflow
- `/workflows/api-design-review` — Design/review API REST, OpenAPI, sécurité, tests de contrat
- `/workflows/repo-context` — Analyse un repo existant et génère CLAUDE.md, CONTEXT.md, architecture, ADRs et onboarding

### Tools

- `/tools/create-docs` — Génération documentation projet
- `/tools/update-docs` — Synchronisation docs/code
- `/tools/scaffold` — Scaffolding de composants/modules
- `/tools/git-status` — Git status enrichi avec suggestions
- `/tools/test-gen` — Génération automatique de tests
- `/tools/deps-audit` — Audit dépendances npm (sécurité, obsolescence, licences)
- `/tools/changelog` — Génération CHANGELOG depuis commits conventionnels
- `/tools/env-check` — Recensement et documentation des variables d'environnement

## Règles importantes

- Toujours écrire des tests avant d'implémenter (TDD)
- Ne jamais modifier `.env`, `.env.*` ou `package-lock.json`
- Utiliser les conventions de commit conventionnel
- Documenter les décisions d'architecture dans `/docs/decisions/` (ADR)
- Ne pas utiliser `any` en TypeScript — préférer `unknown` + type guards
- Chaque PR doit inclure des tests
- Toujours vérifier la sécurité avant de merger (use security-auditor agent)
