---
description: "Audit de sécurité complet du projet ou d'un module. Analyse OWASP, dépendances, secrets, configuration et génère un rapport de remédiation priorisé."
allowed-tools: Bash, Read, Grep, Glob, Task
---

# Security Audit Complet

Audit de sécurité de : **$ARGUMENTS**

## Périmètre d'audit

Si `$ARGUMENTS` est vide, auditer l'ensemble du projet.
Sinon, focaliser sur le module/fichier spécifié.

## Étape 1 — Reconnaissance

```bash
# Analyser la surface d'attaque
find . -name "*.ts" -o -name "*.js" | grep -v node_modules | head -50
cat package.json | jq '.dependencies, .devDependencies'
```

## Étape 2 — Scan des secrets

```bash
# Chercher des secrets potentiels
grep -r "API_KEY\|SECRET\|PASSWORD\|TOKEN\|PRIVATE" --include="*.ts" --include="*.js" \
  --exclude-dir=node_modules --exclude-dir=.git -l

# Variables d'environnement hardcodées
grep -r "process\.env\." --include="*.ts" --include="*.js" \
  --exclude-dir=node_modules
```

## Étape 3 — Analyse SAST (security-auditor agent)

Analyser pour chaque catégorie OWASP :

1. **Injection** : SQL, NoSQL, command injection
2. **Authentication** : Session, JWT, password handling
3. **Authorization** : RBAC, IDOR, privilege escalation
4. **Sensitive Data** : Encryption, logging, data exposure
5. **XSS** : Output encoding, CSP
6. **CSRF** : Token validation, SameSite cookies
7. **Dependencies** : Known CVEs

## Étape 4 — Audit des dépendances

```bash
npm audit --json | jq '.vulnerabilities | to_entries[] | {
  package: .key,
  severity: .value.severity,
  via: .value.via[0]
}'
```

## Étape 5 — Rapport final

```markdown
# Rapport d'Audit Sécurité — $ARGUMENTS
**Date** : $(date)
**Auditeur** : Claude Code (security-auditor agent)

## Résumé exécutif
- Critiques : X
- Hauts : X
- Moyens : X
- Faibles : X

## Vulnérabilités par criticité

### 🔴 CRITIQUES
| ID | Localisation | Description | Remédiation |
|----|-------------|-------------|-------------|

### 🟠 HAUTS
...

### 🟡 MOYENS
...

## Dépendances vulnérables
| Package | Version | CVE | Fix disponible |
|---------|---------|-----|----------------|

## Plan de remédiation
1. [Immédiat] ...
2. [Cette semaine] ...
3. [Prochain sprint] ...

## Score de sécurité global : X/10
```
