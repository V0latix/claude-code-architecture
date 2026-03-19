# Structure du Projet

## Vue d'ensemble

```
project/
├── CLAUDE.md                          # Contexte projet permanent (chargé à chaque session)
├── .mcp.json                          # Configuration MCP servers
├── install.sh                         # Installateur modulaire interactif
├── modules/                           # Manifests d'installation modulaire
│   ├── core/module.json               # Fondation (hooks + skills de base)
│   ├── process/module.json            # Discipline TDD (debugging, tdd-enforcement...)
│   ├── dev/module.json                # Développement général
│   ├── frontend/module.json           # UI/Frontend
│   ├── devops/module.json             # Infrastructure & ops
│   ├── ai-llm/module.json             # Applications IA/LLM
│   ├── bmad/module.json               # Méthodologie BMAD
│   ├── vscode/module.json             # Extensions VSCode
│   ├── data/module.json               # Data science
│   └── mobile/module.json             # Mobile (React Native/Flutter)
├── bundles/                           # Bundles présets (full-stack, ai-developer, complete)
├── .claude/
│   ├── settings.json                  # Hooks et permissions
│   ├── agents/                        # Subagents spécialisés (20 agents)
│   ├── skills/                        # Paquets de connaissances modulaires (24 skills)
│   ├── commands/
│   │   ├── workflows/                 # Workflows multi-agents (17 workflows)
│   │   └── tools/                     # Outils utilitaires (13 tools)
│   └── hooks/
│       ├── scripts/                   # Scripts d'automatisation (dont context-monitor.js)
│       └── config/                    # Configuration des hooks
├── docs/                              # Documentation
│   ├── project-structure.md           # Ce fichier
│   ├── architecture.md               # Architecture technique
│   ├── decisions/                    # Architecture Decision Records
│   ├── bmad/                         # Artefacts BMAD
│   │   ├── templates/                # Templates (brief, PRD, architecture, epic, story...)
│   │   └── checklists/               # Checklists qualité (DoD, story-creation, IR, PM)
│   └── stories/                      # Stories BMAD générées (epic-N-story-M.md)
└── src/                              # Code source
    └── CONTEXT.md                    # Contexte module (Tier 3)
```

## Modules disponibles

| Module | Contenu | Dépend de |
|--------|---------|-----------|
| `core` | Hooks, 8 skills fondamentales, outils utilitaires | — |
| `process` | TDD discipline : debugging, tdd-enforcement, writing-plans, git-worktrees | core |
| `dev` | developer, architect, code-reviewer, qa-engineer, doc-writer + 7 workflows | core, process |
| `frontend` | frontend-specialist, ui-expert, ux-expert, shadcn/ui, document-processing | core, dev |
| `devops` | devops-engineer, incident-responder, security-auditor, performance-engineer + 4 workflows | core, dev |
| `ai-llm` | ai-engineer, llm-ai-patterns, prompt-engineering, workflow ai-feature | core, dev |
| `bmad` | bmad-orchestrator, product-manager, scrum-master + 3 workflows BMAD + templates | core, dev |
| `vscode` | vscode-developer, vscode-extension, workflow vscode-extension-dev | core, dev |
| `data` | data-scientist, data-engineering, workflow data-pipeline | core, dev |
| `mobile` | mobile-developer (React Native / Flutter) | core, dev, frontend |

## Agents disponibles

### Agents fondamentaux

| Agent | Modèle | Rôle |
|-------|--------|------|
| `analyst` | Sonnet | Brainstorming, recherche, briefs |
| `architect` | Opus | Design système, ADR, choix tech |
| `developer` | Opus | Implémentation, debugging, refactoring |
| `frontend-specialist` | Sonnet | Implémentation React/Next.js (code UI) |
| `qa-engineer` | Sonnet | Tests, qualité, couverture |
| `security-auditor` | Opus | Audit sécurité, SAST, compliance |
| `devops-engineer` | Sonnet | CI/CD, Docker, K8s |
| `code-reviewer` | Opus | Review multi-critères en parallèle |
| `product-manager` | Sonnet | PRD, spécifications, roadmap |
| `scrum-master` | Haiku | Stories, sprints, agile |
| `ux-expert` | Sonnet | UI/UX, wireframes, design system |
| `doc-writer` | Haiku | Documentation technique |

### Agents spécialisés

| Agent | Modèle | Rôle |
|-------|--------|------|
| `ai-engineer` | Opus | Applications LLM, RAG, chatbots, agents IA |
| `data-scientist` | Sonnet | Analyse de données, ML, statistiques |
| `performance-engineer` | Sonnet | Profiling, optimisation, benchmarks |
| `mobile-developer` | Sonnet | Applications React Native / Flutter |
| `incident-responder` | Opus | Incidents production, postmortems |
| `ui-expert` | Sonnet | UI app end-to-end — design system, shadcn/ui, animations, dark mode |
| `vscode-developer` | Sonnet | Extensions VSCode — TreeView, Webview, LSP, Chat Participant, Marketplace |
| `bmad-orchestrator` | Opus | Orchestrateur BMAD — routing phases, gates, coordination |

## Skills disponibles

| Skill | Cas d'usage |
|-------|-------------|
| `api-design` | Design d'API REST/GraphQL, versioning, OpenAPI |
| `architecture-diagrams` | Diagrammes Mermaid, modèle C4, flowcharts |
| `async-patterns` | Code asynchrone TypeScript/Node.js, concurrence |
| `auth-patterns` | JWT, sessions, OAuth/OIDC, RBAC, MFA |
| `data-engineering` | ETL/ELT pipelines, dbt, Airflow, qualité données |
| `database-patterns` | Schémas Prisma, requêtes optimisées, migrations |
| `docker-k8s` | Containerisation, docker-compose, manifests K8s |
| `document-processing` | Lecture/création PDF, Word (DOCX), Excel (XLSX) |
| `error-handling-patterns` | Result type, error boundaries, retry logic |
| `frontend-frameworks` | React 18+, Next.js 15, Server Components, état |
| `incident-response` | Runbooks, postmortems blameless, escalade |
| `llm-ai-patterns` | RAG, agents, embeddings, structured output |
| `mcp-builder` | Création de serveurs MCP (TypeScript/Python) |
| `observability-patterns` | Prometheus, Grafana, OpenTelemetry, SLOs |
| `prompt-engineering` | Few-shot, chain-of-thought, optimisation prompts |
| `security-scanning` | OWASP Top 10, SAST, secrets scanning |
| `testing-patterns` | Vitest, Jest, Testing Library, Playwright, TDD |
| `ui-design-system` | shadcn/ui, Radix UI, Framer Motion, dark mode, design tokens |
| `vscode-extension` | API namespaces VSCode, TreeView, Webview, LSP, Chat Participant, bundling, publishing |
| `systematic-debugging` | Débogage 4 phases : root cause → pattern → hypothèse → implémentation |
| `verification-before-completion` | Preuves fraîches obligatoires avant toute déclaration de succès |
| `tdd-enforcement` | Cycles RED-GREEN-REFACTOR, aucun code sans test qui échoue d'abord |
| `writing-plans` | Plans granulaires docs/plans/ avec tâches TDD de 2-5 minutes et code exact |
| `git-worktrees` | Workspaces isolés par feature, baseline tests, nettoyage |

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
- `/workflows/repo-context` — Analyse repo existant → génère CLAUDE.md, CONTEXT.md, architecture, ADRs, onboarding
- `/workflows/vscode-extension-dev` — Développement extension VSCode end-to-end (concept → Marketplace)

- `/workflows/verify-goal` — Vérification orientée-objectif : vérités observables, artefacts substantiels, câblage des composants

#### Workflows BMAD
- `/workflows/bmad-greenfield` — BMAD nouveau projet : Brief → PRD → Architecture → Épics → Dev story-by-story
- `/workflows/bmad-brownfield` — BMAD projet existant : découverte contexte → story → implémentation
- `/workflows/bmad-quick` — BMAD Quick Flow : spec rapide → dev direct (bug fix, refactor, petite feature)

### Tools
- `/tools/create-docs` — Génération de documentation
- `/tools/update-docs` — Synchronisation docs/code
- `/tools/scaffold` — Scaffolding de composants/modules
- `/tools/git-status` — Git status enrichi
- `/tools/test-gen` — Génération automatique de tests
- `/tools/deps-audit` — Audit dépendances npm (sécurité, obsolescence, licences)
- `/tools/changelog` — Génération CHANGELOG depuis commits conventionnels
- `/tools/env-check` — Recensement et documentation des variables d'environnement
- `/tools/bmad-story` — Créer une story BMAD complète et prête pour le développement
- `/tools/vscode-scaffold` — Scaffold complet extension VSCode (command, treeview, webview, LSP, chat-participant)
- `/tools/write-plan` — Créer un plan TDD granulaire dans docs/plans/ (tâches 2-5 min, code exact)
- `/tools/execute-plan` — Exécuter un plan task par task avec TDD + verification automatique
- `/tools/continue` — Sauvegarder l'état complet de session dans CONTINUE-HERE.md pour reprendre après un reset
