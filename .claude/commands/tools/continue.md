---
description: "Génère un fichier CONTINUE-HERE.md capturant l'état complet de la session : tâches en cours, fichiers modifiés, décisions prises, prochaine étape exacte. Utiliser avant une fin de contexte ou une pause longue pour reprendre exactement là où on s'est arrêté."
allowed-tools: Bash, Read, Write, Glob, Grep
---

# Continue — Sauvegarde d'état de session

Génération du fichier de reprise : **CONTINUE-HERE.md**

## Instructions

### 1. Collecter les informations de session

```bash
# Commits récents de la session
git log --oneline -10 2>/dev/null || echo "Pas de repo git"

# Fichiers modifiés non committés
git diff --stat HEAD 2>/dev/null || echo "Aucun changement non commité"

# Branche et worktree actifs
git branch --show-current 2>/dev/null
git worktree list 2>/dev/null || true

# Statut général
git status --short 2>/dev/null || true
```

### 2. Analyser les todos en cours

Chercher les tâches récentes avec leur statut :
- Tâches `in_progress` → tâche courante
- Tâches `pending` → prochaines étapes
- Tâches `completed` → déjà fait

### 3. Générer CONTINUE-HERE.md

Créer le fichier à la racine du projet avec la structure suivante :

```markdown
# CONTINUE HERE — [DATE ISO]

> Généré par /tools/continue pour reprendre la session après un reset de contexte.

## Contexte immédiat

**Branche :** [git branch]
**Worktree :** [git worktree list si applicable]

## Ce qui a été fait dans cette session

### Commits réalisés
[git log --oneline -10]

### Fichiers modifiés non committés
[git diff --stat HEAD]

## Tâche en cours

**Tâche active :** [tâche marquée in_progress dans les todos]

**Prochaine action exacte :**
[description précise de la prochaine action — assez détaillée pour être copiée directement dans un nouveau prompt]

## Prochaines étapes (dans l'ordre)

1. [tâche pending 1]
2. [tâche pending 2]
3. [...]

## Décisions importantes prises

[résumer les décisions architecturales, patterns choisis, approches retenues pendant cette session — extraire des commits et de la discussion]

## Commandes de vérification

```bash
# Vérifier que tout est encore vert avant de continuer
[commande de test adaptée au projet, ex: npx vitest run]
[commande de build: npm run build]
```

## Prompt de reprise suggéré

Colle ce prompt au début de la prochaine session :

---
Reprends le travail sur [NOM DU PROJET]. Lis CONTINUE-HERE.md pour le contexte.
Tâche en cours : [TÂCHE ACTIVE]
Prochaine action : [PROCHAINE ACTION EXACTE]
---
```

### 4. Confirmer la sauvegarde

Afficher :
```
✅ CONTINUE-HERE.md généré
📍 Prochaine action : [résumé court]
💡 Colle le prompt de reprise au début de ta prochaine session
```

### Règles

- Être **précis** sur la prochaine action — assez pour qu'un nouveau contexte reprenne sans ambiguïté
- Inclure les commandes de vérification pour confirmer l'état avant de continuer
- Si aucun repo git → capturer l'état via les fichiers récemment créés/modifiés
- Ne pas décrire ce qui n'a PAS été fait — seulement ce qui est en cours et ce qui suit
