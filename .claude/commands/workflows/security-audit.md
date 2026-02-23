---
description: "Audit de sécurité complet du projet ou d'un module. Analyse OWASP, dépendances, authentification, configuration et génère un rapport de remédiation priorisé avec runbook."
allowed-tools: Bash, Read, Grep, Glob, Task
---

# Security Audit Complet

Audit de sécurité de : **$ARGUMENTS**

Si `$ARGUMENTS` est vide → auditer l'ensemble du projet.
Sinon → focaliser sur le module/fichier spécifié.

## Étape 1 — Reconnaissance de la surface d'attaque

```bash
# Surface d'attaque : endpoints, routes, handlers
grep -r "router\.\|app\.\(get\|post\|put\|patch\|delete\)\|export.*route\|handler" \
  --include="*.ts" --include="*.js" -l | grep -v node_modules

# Middleware d'authentification
grep -r "auth\|middleware\|protect\|requireAuth\|withAuth" \
  --include="*.ts" -l | grep -v node_modules

# Flux de données utilisateur
grep -r "req\.body\|req\.query\|req\.params\|formData\|userInput" \
  --include="*.ts" -l | grep -v node_modules

# Dépendances installées
cat package.json | jq '.dependencies | keys'
```

## Étape 2 — Scan des secrets et configs sensibles

```bash
# Secrets potentiels hardcodés
grep -rn "API_KEY\|SECRET\|PASSWORD\|TOKEN\|PRIVATE_KEY\|client_secret" \
  --include="*.ts" --include="*.js" --include="*.json" \
  --exclude-dir=node_modules --exclude-dir=.git \
  | grep -v "process\.env\|\.env\." | grep -v "//.*example\|//.*test"

# .env commité par erreur
git log --all --full-history --name-only | grep "\.env" 2>/dev/null

# Fichiers de config exposant des infos
find . -name "*.json" -not -path "*/node_modules/*" \
  | xargs grep -l "password\|secret\|private" 2>/dev/null
```

## Étape 3 — Analyses parallèles (lancer avec Task)

### `security-auditor agent` — OWASP Top 10
**Skills activées : security-scanning, auth-patterns, error-handling-patterns, api-design**

Analyser systématiquement :
1. **A01 Broken Access Control** : IDOR, privilege escalation, missing authorization
2. **A02 Cryptographic Failures** : données sensibles en clair, TLS, hachage mots de passe
3. **A03 Injection** : SQL, NoSQL, OS command, template injection
4. **A04 Insecure Design** : threat modeling, absence de rate limiting
5. **A05 Security Misconfiguration** : headers manquants, CORS, erreurs verbeux
6. **A06 Vulnerable Components** : npm audit, CVEs dans les dépendances
7. **A07 Auth Failures** : brute force, session fixation, weak passwords
8. **A08 Software Integrity** : supply chain, unsigned packages
9. **A09 Logging Failures** : pas de logs d'audit, logs avec PII
10. **A10 SSRF** : URLs contrôlées par l'utilisateur, webhooks

### `architect agent` — Sécurité par design
**Skills activées : auth-patterns, api-design, observability-patterns**

- Architecture d'authentification/autorisation robuste ?
- Séparation des privilèges (principe du moindre privilège) ?
- Défense en profondeur (validation côté client ET serveur) ?
- Données sensibles isolées (chiffrement at rest) ?
- Observabilité des événements de sécurité (logs d'audit) ?

### `devops-engineer agent` — Sécurité infra et pipeline
**Skills activées : docker-k8s, security-scanning, incident-response**

- Secrets dans les variables d'environnement (pas dans le code) ?
- Images Docker non-root, scanées (Trivy, Snyk) ?
- Network policies K8s restrictives ?
- RBAC K8s correctement configuré ?
- Scan SAST dans le pipeline CI/CD ?

## Étape 4 — Audit des dépendances

```bash
# npm audit avec focus sur les High/Critical
npm audit --json 2>/dev/null | python3 -c "
import json, sys
data = json.load(sys.stdin)
vulns = data.get('vulnerabilities', {})
critical = [(k,v) for k,v in vulns.items() if v.get('severity') in ('critical','high')]
for name, v in critical:
    print(f\"[{v['severity'].upper()}] {name}: {v.get('via', ['?'])[0]}\")
" 2>/dev/null || npm audit 2>/dev/null | grep -E "critical|high|moderate"
```

## Étape 5 — Vérification des headers de sécurité

```bash
# Si un serveur tourne localement
curl -s -I http://localhost:3000 2>/dev/null | grep -iE \
  "x-frame-options|x-content-type|strict-transport|content-security|referrer-policy|permissions-policy"
```

## Étape 6 — Rapport final

```markdown
# Rapport d'Audit Sécurité — $ARGUMENTS
**Date** : $(date)
**Périmètre** : [Module/Projet complet]

## Résumé exécutif
| Criticité | Nombre | À traiter dans |
|-----------|--------|----------------|
| 🔴 Critical | X | Immédiat |
| 🟠 High | X | 48h |
| 🟡 Medium | X | 1 semaine |
| 🟢 Low | X | Prochain sprint |

## Vulnérabilités par criticité

### 🔴 CRITIQUES — Bloquer le déploiement
| ID | Fichier:Ligne | Type OWASP | Description | Remédiation | Skill |
|----|--------------|------------|-------------|-------------|-------|
| SEC-01 | ... | A01 | ... | ... | auth-patterns |

### 🟠 HAUTS
[Même format]

### 🟡 MOYENS
[Même format]

## Dépendances vulnérables
| Package | Version actuelle | CVE | CVSS | Fix |
|---------|-----------------|-----|------|-----|

## Configuration et headers
| Check | Statut | Recommandation |
|-------|--------|----------------|
| X-Frame-Options | ❌ Absent | Ajouter DENY |
| CSP | ❌ Absent | Configurer la politique |
| HSTS | ✅ Présent | - |

## Plan de remédiation

### Immédiat (bloquer le merge/déploiement)
1. [SEC-01] ...

### Cette semaine
2. [SEC-02] ...

### Prochain sprint
3. [SEC-03] ...

## Runbook de sécurité
Si une vulnérabilité critique est exploitée en production :
→ Consulter l'`incident-responder agent` avec la skill `incident-response`

## Score de sécurité global : X/10
**Décision de déploiement : ✅ Autorisé / ❌ Bloqué**
```
