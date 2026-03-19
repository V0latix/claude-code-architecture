# Claude Code Architecture — Agents, Skills, MCP, Workflows & Hooks

Un kit d'architecture complet pour Claude Code qui transforme votre environnement de développement en un système multi-agents orchestré.

## Ce que contient ce repository

| Composant | Quantité | Description |
|-----------|----------|-------------|
| **Agents** | 20 | Experts spécialisés (architect, developer, ui-expert, vscode-developer...) |
| **Skills** | 24 | Paquets de connaissances modulaires avec progressive disclosure |
| **Workflows** | 17 | Workflows multi-agents (full-context, verify-goal, bmad-greenfield, vscode-extension-dev...) |
| **Tools** | 13 | Outils utilitaires (scaffold, write-plan, execute-plan, continue, vscode-scaffold...) |
| **Hooks** | 6 | Automatisations (auto-format, security-scanner, checkpoint-commit, context-monitor...) |
| **Modules** | 10 | Packages installables indépendamment (core, dev, vscode, bmad, ai-llm...) |
| **MCP Config** | 8 | Serveurs MCP préconfigurés |

## Installation modulaire

Installe uniquement les modules dont tu as besoin :

```bash
git clone https://github.com/V0latix/claude-code-architecture
cd claude-code-architecture

# Installation interactive (menu de sélection)
./install.sh /path/to/mon-projet

# Installer un module spécifique (ex: uniquement VSCode)
./install.sh --modules vscode /path/to/mon-projet

# Installer plusieurs modules
./install.sh --modules vscode,bmad,process /path/to/mon-projet

# Utiliser un bundle préconfiguré
./install.sh --bundle full-stack /path/to/mon-projet
./install.sh --bundle ai-developer /path/to/mon-projet

# Tout installer (équivalent au clone complet)
./install.sh --all /path/to/mon-projet

# Voir tous les modules disponibles
./install.sh --list
```

### Modules disponibles

| Module | Contenu | Dépend de |
|--------|---------|-----------|
| `core` | Hooks, 8 skills fondamentales, outils utilitaires | — |
| `process` | TDD discipline, debugging systématique, write-plan | core |
| `dev` | developer, architect, code-reviewer, qa-engineer, 7 workflows | core, process |
| `frontend` | frontend-specialist, ui-expert, ux-expert, shadcn/ui | core, dev |
| `devops` | devops-engineer, security-auditor, docker-k8s, security-audit | core, dev |
| `ai-llm` | ai-engineer, llm-ai-patterns, RAG, agents, chatbots | core, dev |
| `bmad` | bmad-orchestrator, 3 workflows BMAD, templates | core, dev |
| `vscode` | vscode-developer, vscode-extension-dev, scaffold | core, dev |
| `data` | data-scientist, data-engineering, data-pipeline | core, dev |
| `mobile` | mobile-developer, React Native / Flutter | core, dev, frontend |

### Bundles présets

| Bundle | Modules inclus | Pour qui |
|--------|---------------|---------|
| `full-stack` | core, process, dev, frontend, devops | Développeur full-stack Next.js/Node.js |
| `ai-developer` | core, process, dev, ai-llm | Développeur IA/LLM |
| `complete` | Tous les modules | Installation complète |

## Installation complète (cloner directement)

```bash
git clone https://github.com/V0latix/claude-code-architecture
cp -r claude-code-architecture/.claude votre-projet/
cp claude-code-architecture/CLAUDE.md votre-projet/
cp claude-code-architecture/.mcp.json votre-projet/
```

Ou utiliser directement ce repository comme template GitHub.

## Structure

```
.
├── CLAUDE.md                    # Contexte projet (chargé automatiquement)
├── .mcp.json                    # Configuration MCP servers
├── .claude/
│   ├── settings.json            # Hooks configurés
│   ├── agents/                  # 20 agents spécialisés
│   ├── skills/                  # 24 skills modulaires
│   ├── commands/
│   │   ├── workflows/           # 16 workflows multi-agents
│   │   └── tools/               # 12 outils utilitaires
│   └── hooks/scripts/           # Scripts d'automatisation
└── docs/                        # Documentation et ADRs
    ├── bmad/                    # Templates et checklists BMAD
    └── stories/                 # Stories BMAD générées
```

## Agents disponibles

Invoquer un agent avec `use [nom] agent:` dans Claude Code.

| Agent | Modèle | Rôle |
|-------|--------|------|
| `analyst` | Sonnet | Brainstorming, recherche, briefs |
| `architect` | Opus | Design système, ADR, choix technologiques |
| `developer` | Opus | Implémentation, debugging, refactoring |
| `frontend-specialist` | Sonnet | Implémentation React/Next.js (code UI) |
| `qa-engineer` | Sonnet | Tests, qualité, couverture |
| `security-auditor` | Opus | Audit sécurité, OWASP, SAST |
| `devops-engineer` | Sonnet | CI/CD, Docker, Kubernetes |
| `code-reviewer` | Opus | Review multi-critères en parallèle |
| `product-manager` | Sonnet | PRD, spécifications, roadmap |
| `scrum-master` | Haiku | User stories, sprints, agile |
| `ux-expert` | Sonnet | UI/UX, wireframes, design system |
| `ui-expert` | Sonnet | UI app end-to-end — design system, shadcn/ui, animations, dark mode |
| `doc-writer` | Haiku | Documentation technique |
| `ai-engineer` | Opus | Applications LLM, RAG, chatbots, agents IA |
| `data-scientist` | Sonnet | Analyse de données, ML, statistiques |
| `performance-engineer` | Sonnet | Profiling, optimisation, benchmarks |
| `mobile-developer` | Sonnet | Applications React Native / Flutter |
| `vscode-developer` | Sonnet | Extensions VSCode — TreeView, Webview, LSP, Chat Participant, Marketplace |
| `incident-responder` | Opus | Incidents production, postmortems |
| `bmad-orchestrator` | Opus | Orchestrateur BMAD — routing de phase, gates, coordination |

## Commandes disponibles

### Workflows (préfixe `/workflows/`)

```bash
/workflows/full-context [feature]         # Analyse multi-agents complète
/workflows/code-review [fichier]          # Review par 5 agents en parallèle
/workflows/feature-dev [feature]          # Développement E2E
/workflows/security-audit [module]        # Audit sécurité complet (OWASP)
/workflows/refactor [cible]               # Refactoring intelligent
/workflows/ai-feature [feature]           # Développement feature IA/LLM/RAG
/workflows/performance-audit [module]     # Profiling, benchmarks, optimisation DB
/workflows/incident-postmortem [incident] # Triage, résolution, postmortem blameless
/workflows/new-project-setup              # Scaffold complet d'un nouveau projet
/workflows/data-pipeline [pipeline]       # Pipeline ELT, dbt, qualité des données
/workflows/api-design-review [api]        # Design/review API REST, OpenAPI, sécurité
/workflows/repo-context [chemin/repo]     # Analyse repo existant → génère tout le contexte
/workflows/vscode-extension-dev [ext]    # Développement extension VSCode end-to-end → Marketplace

# BMAD — Breakthrough Method of Agile AI-driven Development
/workflows/bmad-greenfield [projet]       # BMAD nouveau projet : Brief → PRD → Archi → Dev loop
/workflows/bmad-brownfield [feature]      # BMAD projet existant : contexte → story → implémentation
/workflows/bmad-quick [changement]        # BMAD Quick Flow : spec rapide → dev direct
```

### Tools (préfixe `/tools/`)

```bash
/tools/create-docs                   # Générer la documentation
/tools/update-docs                   # Synchroniser docs/code
/tools/scaffold [composant]          # Scaffolding de fichiers
/tools/git-status                    # Git status enrichi
/tools/test-gen [fichier]            # Générer des tests automatiquement
/tools/deps-audit                    # Audit sécurité et obsolescence des dépendances
/tools/changelog [version]           # Générer le CHANGELOG depuis git
/tools/env-check                     # Recenser et documenter les variables d'env
/tools/bmad-story [description]      # Créer une story BMAD prête pour le développement
/tools/vscode-scaffold [nom] [type]  # Scaffold extension VSCode (command|treeview|webview|language|chat-participant)
/tools/write-plan [feature]          # Créer un plan TDD granulaire dans docs/plans/ (tâches 2-5 min)
/tools/execute-plan [chemin-plan]    # Exécuter un plan task par task avec TDD + verification
```

## Hooks automatiques

| Hook | Déclencheur | Action |
|------|-------------|--------|
| `context-injector` | SessionStart | Log du contexte de session |
| `security-scanner` | PreToolUse (Edit/Write) | Bloque les fichiers sensibles |
| `auto-format` | PostToolUse (Edit/Write) | Formate le code automatiquement |
| `checkpoint-commit` | PostToolUse (Write) | Commit automatique de checkpoint |
| `squash-checkpoints` | Stop | Squash des checkpoints en un commit propre |

## MCP Servers préconfigurés

Configurer les variables d'environnement requises, puis lancer :

```bash
# GitHub MCP
export GITHUB_TOKEN=ghp_...

# PostgreSQL MCP (si utilisé)
export DATABASE_URL=postgresql://...

# Brave Search MCP (si utilisé)
export BRAVE_API_KEY=BSA...
```

## Adapter au projet

1. Modifier `CLAUDE.md` avec le stack réel du projet
2. Ajuster les modèles dans les frontmatters des agents si besoin
3. Activer/désactiver les hooks dans `.claude/settings.json`
4. Configurer les MCP servers dans `.mcp.json`

## Références

- [Documentation Claude Code](https://docs.anthropic.com/fr/docs/claude-code)
- [MCP Servers officiels](https://github.com/modelcontextprotocol/servers)
- [Anthropic Skills](https://github.com/anthropics/skills)

## Licence

MIT
