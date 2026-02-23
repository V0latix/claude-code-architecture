---
description: "Gestion complète d'un incident de production. Couvre le triage initial, la résolution, le postmortem blameless et le plan d'action préventif. Utilise l'incident-responder avec la skill incident-response."
allowed-tools: Bash, Read, Grep, Glob, Task
---

# Incident Management & Postmortem

Incident à traiter : **$ARGUMENTS**

Si `$ARGUMENTS` contient une description d'incident → démarrer en Phase 1 (Triage).
Si l'incident est résolu → aller directement en Phase 3 (Postmortem).

---

## Phase 1 — Triage et qualification

### `incident-responder agent`
**Skills activées : incident-response, observability-patterns, error-handling-patterns, docker-k8s**

**Qualifier immédiatement :**

| Critère | Question |
|---------|---------|
| Sévérité | P0 (service down) / P1 (fonctionnalité critique dégradée) / P2 (partiel) / P3 (mineur) ? |
| Périmètre | Tous les utilisateurs / segment / région ? |
| Début | Quand l'incident a-t-il commencé ? |
| Symptômes | Erreurs ? Latence ? Données corrompues ? |
| Déclencheur | Déploiement récent ? Pic de trafic ? Dépendance externe ? |

**Actions immédiates selon la sévérité :**

```bash
# P0/P1 — Vérification rapide de l'état des services
kubectl get pods -n production 2>/dev/null | grep -v Running | grep -v Completed
kubectl get events -n production --sort-by='.lastTimestamp' 2>/dev/null | tail -20

# Logs des dernières erreurs
kubectl logs -n production deployment/api --since=15m 2>/dev/null | grep -i "error\|fatal\|panic" | tail -30

# Métriques clés
kubectl top pods -n production 2>/dev/null | sort -k3 -rn | head -10

# Vérifier les déploiements récents (cause fréquente)
kubectl rollout history deployment/api -n production 2>/dev/null
git log --oneline -10 2>/dev/null
```

**Nommer les rôles IC :**
- **Incident Commander (IC)** : coordonne, prend les décisions
- **Tech Lead** : diagnostic technique, propose et exécute les remèdes
- **Communicant** : met à jour la status page, notifie les parties prenantes
- **Scribe** : documente la timeline en temps réel

---

## Phase 2 — Résolution

### `incident-responder agent` + `devops-engineer agent`
**Skills activées : incident-response, docker-k8s, observability-patterns**

**Runbook de diagnostic :**

```bash
# Option A — Rollback immédiat (si déploiement récent)
kubectl rollout undo deployment/api -n production 2>/dev/null
kubectl rollout status deployment/api -n production 2>/dev/null

# Option B — Scale up si surcharge
kubectl scale deployment/api --replicas=5 -n production 2>/dev/null

# Option C — Redémarrage des pods crashés
kubectl delete pod -n production -l app=api --field-selector=status.phase=Failed 2>/dev/null

# Vérification post-action
kubectl get pods -n production -w 2>/dev/null | head -20
```

**Checklist de résolution :**
- [ ] Service restauré et stable depuis > 5 minutes
- [ ] Métriques d'erreur revenues à la normale
- [ ] Status page mise à jour (incident résolu)
- [ ] Parties prenantes notifiées
- [ ] Timeline documentée

**Timeline à maintenir en temps réel :**
```
HH:MM — Alerte reçue : [description]
HH:MM — IC nommé : [nom]
HH:MM — Diagnostic initial : [hypothèse]
HH:MM — Action 1 : [ce qui a été fait] → [résultat]
HH:MM — Action 2 : [ce qui a été fait] → [résultat]
HH:MM — Service restauré
HH:MM — Monitoring confirmé stable
HH:MM — Incident clôturé
```

---

## Phase 3 — Postmortem blameless

**À faire dans les 48-72h suivant la résolution.**

### `incident-responder agent` + `analyst agent`
**Skills activées : incident-response, architecture-diagrams, prompt-engineering**

**Principes :**
- **Blameless** : les individus ne sont pas responsables — les systèmes le sont
- **Factuel** : s'appuyer sur les logs, métriques, timeline — pas les souvenirs
- **Actionnable** : chaque cause racine doit produire une action de remédiation

### `architect agent`
**Skills activées : api-design, observability-patterns, error-handling-patterns, database-patterns**

Analyser les défaillances systémiques :
- Absence de circuit breaker / retry logic ?
- Health checks insuffisants ?
- Alertes trop tardives ou trop bruyantes ?
- Tests manquants qui auraient détecté le problème ?
- Documentation absente (runbook inexistant) ?

---

## Phase 4 — Rapport postmortem

```markdown
# Postmortem — $ARGUMENTS
**Date de l'incident** : [date]
**Durée** : [début] → [fin] = [X heures Y minutes]
**Sévérité** : P[0-3]
**Auteurs** : [noms de l'équipe]
**Statut** : Brouillon / Reviewé / Final

---

## Résumé exécutif
[2-3 phrases : ce qui s'est passé, impact, comment résolu]

## Impact
| Métrique | Valeur |
|---------|--------|
| Durée totale | X heures |
| Utilisateurs affectés | X (X% de la base) |
| Transactions perdues/échouées | X |
| SLO breach | Oui/Non — [X% uptime vs Y% SLO] |
| Impact financier estimé | $X |

## Timeline factuelle
| Heure | Événement | Qui |
|-------|----------|-----|
| HH:MM | Première alerte | PagerDuty |
| HH:MM | IC nommé | [nom] |
| HH:MM | [action] | Tech Lead |
| HH:MM | Service restauré | [nom] |
| HH:MM | Post-incident monitoring | [nom] |

**MTTD** (Mean Time to Detect) : X minutes
**MTTA** (Mean Time to Acknowledge) : X minutes
**MTTR** (Mean Time to Resolve) : X heures

## Causes racines (5-Why)

### Cause racine #1
| # | Pourquoi ? | Réponse |
|---|-----------|---------|
| 1 | Pourquoi le service est tombé ? | La DB a saturé ses connexions |
| 2 | Pourquoi les connexions ont saturé ? | Connection pool trop petit (10) |
| 3 | Pourquoi le pool était trop petit ? | Pas de charge test avec concurrence élevée |
| 4 | Pourquoi pas de charge test ? | Pas de processus de load testing défini |
| 5 | Pourquoi pas de processus ? | **Cause racine : absence de playbook de perf testing** |

### Cause racine #2
[Même format]

## Ce qui a bien fonctionné
- ✅ Alerte déclenchée rapidement (< 2 min)
- ✅ Rollback exécuté en < 5 min
- ✅ Communication claire vers les utilisateurs

## Ce qui n'a pas fonctionné
- ❌ Runbook absent pour ce type d'incident
- ❌ Pas d'alerte sur le pool de connexions DB
- ❌ Feature flag absent → impossible de désactiver la feature impactée

## Plan d'action préventif

| # | Action | Propriétaire | Délai | Priorité | Lié à la cause |
|---|--------|-------------|-------|----------|----------------|
| 1 | Ajouter alerte sur pg_stat_activity.count | DevOps | 3 jours | P0 | Cause #1 |
| 2 | Augmenter connection pool (10→50) | Dev | 1 jour | P0 | Cause #1 |
| 3 | Écrire runbook pour saturation DB | DevOps | 1 semaine | P1 | Cause #1 |
| 4 | Ajouter load test dans CI/CD pipeline | QA | 2 semaines | P1 | Cause #1 |
| 5 | Implémenter feature flags avec Unleash | Architect | 1 mois | P2 | Cause #2 |

## Métriques de suivi
- Date de review du plan d'action : [dans 2 semaines]
- Toutes les actions P0 complétées : [date cible]
- Prochain game day/chaos engineering : [date]

---
*Document partagé avec l'équipe pour apprentissage collectif.*
*Rappel : cet incident n'est la faute d'aucun individu — nous améliorons le système.*
```

## Agents à utiliser pour les actions préventives
- Implémentation des fixes : `use developer agent` avec skill `error-handling-patterns`
- Observabilité manquante : `use devops-engineer agent` avec skill `observability-patterns`
- Review architecture : `/workflows/refactor $ARGUMENTS`
- Prochaine feature risquée : `/workflows/security-audit`
