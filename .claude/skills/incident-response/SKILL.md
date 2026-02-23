---
name: incident-response
description: "Patterns de gestion d'incidents de production : runbooks, postmortems blameless, escalade, communication de crise et on-call handoff. Activer lors d'incidents en production, pour créer des runbooks ou rédiger un postmortem."
license: MIT
sources: "wshobson/agents (postmortem-writing, incident-runbook-templates, on-call-handoff-patterns, incident-responder)"
---

# Incident Response

## Quand utiliser cette skill

- Gérer un incident de production actif
- Créer des runbooks préventifs
- Rédiger un postmortem après un incident
- Structurer le handoff on-call
- Définir les niveaux de sévérité et d'escalade

## 1. Niveaux de sévérité

| Niveau | Définition | SLA de réponse | Exemple |
|--------|-----------|----------------|---------|
| **P0 — Critical** | Service totalement indisponible | < 5 min | Site down, paiements impossibles |
| **P1 — High** | Feature critique dégradée | < 15 min | Login défaillant, erreur > 5% |
| **P2 — Medium** | Impact partiel ou workaround possible | < 1h | Feature secondaire cassée |
| **P3 — Low** | Impact minimal, peut attendre | < 24h | Bug cosmétique, lenteur mineure |

## 2. Incident Commander — Rôles

```markdown
## Rôles lors d'un incident P0/P1

**Incident Commander (IC)** : Coordonne la réponse, prend les décisions finales
**Tech Lead** : Analyse technique, propose et exécute les corrections
**Communicant** : Met à jour le statut page, informe les parties prenantes
**Scribe** : Documente tout (timeline, actions, décisions) en temps réel
```

## 3. Template Runbook

```markdown
# Runbook : [Nom de l'alerte/Scénario]

## Résumé
[Description en 1-2 phrases de la situation]

## Sévérité : [P0 / P1 / P2 / P3]
## Propriétaire : [Équipe responsable]
## Dernière mise à jour : [Date]

## Symptômes
- [ ] Symptôme 1 observable
- [ ] Symptôme 2 observable

## Impact
- **Utilisateurs affectés** : [Estimation]
- **Revenue impact** : [Si applicable]

## Diagnostic rapide (< 5 min)

\`\`\`bash
# 1. Vérifier le statut du service
kubectl get pods -n production | grep [service-name]
kubectl describe pod [pod-name] -n production

# 2. Vérifier les logs des 15 dernières minutes
kubectl logs -l app=[service] -n production --since=15m | grep -i error | tail -50

# 3. Vérifier les métriques clés
# → Grafana dashboard : https://grafana.internal/d/[dashboard-id]
\`\`\`

## Actions de remédiation

### Option A : Rollback rapide (recommandé si possible)
\`\`\`bash
kubectl rollout undo deployment/[service-name] -n production
kubectl rollout status deployment/[service-name] -n production
\`\`\`

### Option B : Scale up (si problème de charge)
\`\`\`bash
kubectl scale deployment/[service-name] --replicas=10 -n production
\`\`\`

### Option C : Restart des pods (si problème mémoire/état)
\`\`\`bash
kubectl rollout restart deployment/[service-name] -n production
\`\`\`

## Vérification post-action
- [ ] Error rate < 0.1%
- [ ] Latence P95 < 500ms
- [ ] Tous les health checks verts
- [ ] Monitoring actif

## Escalade
Si non résolu en [X] minutes :
1. Contacter [Nom] via Slack #oncall ou +33...
2. Escalader à [Manager] si P0 persistant > 30 min

## Références
- [Lien Grafana Dashboard]
- [Lien Runbook connexe]
- [Postmortem de l'incident similaire]
```

## 4. Timeline d'incident (Scribe)

```markdown
# Timeline Incident [ID] — [Date]

**[HH:MM]** 🚨 Alerte déclenchée : [Nom alerte]
**[HH:MM]** 👤 IC désigné : [Nom]
**[HH:MM]** 🔍 Diagnostic commencé
**[HH:MM]** 💡 Hypothèse : [Description]
**[HH:MM]** 🔧 Action : [Ce qui a été fait]
**[HH:MM]** ✅/❌ Résultat : [Effet observé]
**[HH:MM]** 🔧 Action 2 : [Rollback vers version X]
**[HH:MM]** ✅ Service restauré — Error rate < 0.1%
**[HH:MM]** 📢 Communication envoyée aux utilisateurs
**[HH:MM]** 📝 Incident clos — Postmortem planifié
```

## 5. Template Postmortem (Blameless)

```markdown
# Postmortem : [Titre court]

**Date** : [Date de l'incident]
**Durée** : [X heures Y minutes]
**Sévérité** : [P0/P1]
**Rédigé par** : [Noms] — **Reviewé par** : [Noms]

> ⚠️ Ce document est BLAMELESS. L'objectif est d'apprendre, pas de blâmer.

## Résumé (TL;DR)
[2-3 phrases décrivant l'incident, son impact et la cause racine]

## Impact
- **Durée d'indisponibilité** : X min
- **Utilisateurs affectés** : ~X (X%)
- **Requêtes en erreur** : X
- **Revenue estimé perdu** : $X

## Timeline
[Reprendre la timeline détaillée de l'incident]

## Analyse des causes racines (5 Why)

| Pourquoi ? | Réponse |
|------------|---------|
| Pourquoi l'incident s'est-il produit ? | [Cause immédiate] |
| Pourquoi cette cause existait-elle ? | [Cause sous-jacente] |
| Pourquoi n'a-t-on pas prévenu ? | [Gap de monitoring] |
| Pourquoi le monitoring n'existait pas ? | [Gap de processus] |
| Pourquoi ce gap de processus ? | [Cause systémique] |

## Ce qui a bien fonctionné
- Détection rapide grâce à l'alerte X
- Communication claire par [Nom]
- Rollback exécuté en Y minutes

## Ce qui aurait pu mieux se passer
- L'alerte aurait pu se déclencher 10 min plus tôt
- Le runbook n'était pas à jour

## Actions correctives

| Action | Responsable | Priorité | Deadline |
|--------|-------------|----------|----------|
| Mettre à jour le runbook | [Nom] | P1 | J+3 |
| Ajouter alerte sur [métrique] | [Nom] | P1 | J+7 |
| Test de rollback automatique | [Nom] | P2 | J+14 |
```

## 6. On-Call Handoff

```markdown
# On-Call Handoff — [Date de début]

## État du système
- **Status global** : 🟢 Opérationnel / 🟡 Dégradé / 🔴 Incident
- **Dernière déployement** : [Version] — [Date]

## Incidents en cours
- [ ] Aucun incident actif

## Points de vigilance
- [Service X] : Deploy prévu vendredi, surveiller les erreurs
- [DB] : Query lente détectée, ticket #123 en cours

## Alertes à surveiller particulièrement
- Memory leak suspecté sur [service] → redémarrer si RSS > 2GB

## Contacts d'escalade
- Backend Lead : [Nom] — [Contact]
- Infra Lead : [Nom] — [Contact]

## Dashboards importants
- [Grafana Global](https://grafana.internal)
- [Sentry Errors](https://sentry.io/...)
```

## Anti-patterns à éviter

```
# ❌ Culture du blâme dans les postmortems
"C'est la faute de [développeur] qui a mergé sans tester"

# ✅ Focus sur les systèmes, pas les individus
"Le processus de review n'avait pas de checklist pour ce type de changement"

# ❌ Postmortem sans actions concrètes assignées
"Nous devons améliorer notre monitoring" (sans responsable ni deadline)

# ✅ Actions SMART avec responsable et deadline

# ❌ Runbook non testé ou obsolète
# Tester les runbooks régulièrement en staging (gameday)

# ❌ Gérer un incident sans scribe
# La timeline est essentielle pour le postmortem et l'apprentissage
```
