---
description: "Analyse multi-agents complète d'une feature ou d'un problème. Lance des analyses en parallèle depuis plusieurs expertises puis compile une synthèse actionnable."
allowed-tools: Bash, Read, Grep, Glob, Task
---

# Full Context Analysis

Analyse complète de la demande suivante : **$ARGUMENTS**

## Étapes d'exécution

### 1. Découverte du contexte

Commence par analyser le projet actuel :
- Lire `CLAUDE.md` pour le contexte projet
- Identifier les fichiers et modules concernés par `$ARGUMENTS`
- Comprendre l'architecture existante

### 2. Analyses parallèles (lancer avec Task)

Lance simultanément les sous-agents suivants :

**Analyst** : Cadrer le problème, identifier les besoins utilisateur et les risques métier

**Architect** : Analyser l'impact architectural, identifier les dépendances et proposer un design

**Security Auditor** : Identifier les risques de sécurité liés à `$ARGUMENTS`

**QA Engineer** : Définir la stratégie de tests et les critères de qualité

### 3. Plan d'implémentation

Sur la base des analyses :
- Déléguer au `developer` agent pour un plan d'implémentation détaillé
- Découper en étapes ordonnées avec dépendances

### 4. Synthèse finale

Compiler tous les résultats dans un document structuré :

```markdown
# Analyse Complète : [Feature/Problème]

## Résumé exécutif
[2-3 phrases]

## Contexte & Problème
[Analyse de l'analyst]

## Architecture proposée
[Recommandations de l'architect]

## Plan d'implémentation
[Étapes du developer]

## Stratégie de tests
[Plan du qa-engineer]

## Points de vigilance sécurité
[Risques du security-auditor]

## Prochaines étapes
1. ...
2. ...
```
