---
description: "Exécute un plan d'implémentation task par task depuis docs/plans/. Applique tdd-enforcement et verification-before-completion à chaque tâche. Batches de 3 tâches avec rapport de progression."
allowed-tools: Bash, Read, Write, Edit, Grep, Glob, Task
---

# Execute Plan

Exécution du plan : **$ARGUMENTS**

## Instructions

### 1. Lire et valider le plan

```bash
cat $ARGUMENTS
```

Vérifier que le fichier plan existe et contient des tâches `- [ ]` (pending).

Si le fichier n'existe pas → arrêter et afficher : "Plan introuvable : $ARGUMENTS"
Si toutes les tâches sont déjà complétées → afficher : "Plan déjà complet ✅"

### 2. Identifier les tâches pending

Extraire toutes les tâches avec `- [ ]` dans la section `## Statuts`.
Compter : X tâches pending sur Y total.

### 3. Exécuter par batches de 3

Pour chaque batch de 3 tâches pending :

#### Pour chaque tâche du batch :

**a) Marquer in-progress**

Remplacer `- [ ] Task N` par `- [~] Task N` dans le fichier plan.

**b) Lire la spécification**

Lire la section `## Task N` dans le plan pour obtenir :
- Fichier cible
- Test RED à écrire
- Code GREEN à implémenter
- Commande de vérification
- Message de commit

**c) Appliquer TDD**

```
1. Écrire le test RED
2. Lancer les tests → vérifier qu'il échoue pour la bonne raison
3. Écrire le code GREEN (strict minimum)
4. Lancer les tests → vérifier qu'ils passent
5. REFACTOR si nécessaire → les tests doivent toujours passer
```

**d) Vérification obligatoire avant completion**

```bash
# Relancer DANS LA SESSION COURANTE — pas de présomption
[commande de vérification du plan]
npx tsc --noEmit
```

Coller la sortie réelle. Si échec → ne pas marquer completed.

**e) Commit**

```bash
git add [fichiers modifiés]
git commit -m "[message de commit du plan]"
```

**f) Marquer completed**

Remplacer `- [~] Task N` par `- [x] Task N` dans le fichier plan.
Afficher : `✅ Task N terminée`

#### Après chaque batch

Afficher un rapport de progression :
```
Batch 1/3 terminé : Tasks 1-3 ✅
Progression : 3/9 (33%)
```

Pause entre les batches : vérifier si l'utilisateur veut continuer ou s'il y a des blocages.

### 4. Gestion des blocages

Si une tâche ne peut pas être complétée :
- Ne pas marquer completed
- Laisser `- [~]` (in-progress)
- Afficher clairement le blocage
- Demander à l'utilisateur comment procéder

```
⚠️ Blocage sur Task 3 :
[description du problème]
Options :
1. Modifier la spécification de la tâche
2. Décomposer en sous-tâches
3. Passer à la tâche suivante et revenir
```

### 5. Rapport final

À la fin de tous les batches :

```
## Rapport d'exécution

✅ Terminées : X/Y tâches
⚠️ Bloquées : Z tâches (si applicable)

Vérification globale :
- Tests : [résultat]
- TypeScript : [résultat]

Prochaines étapes : [si tâches bloquées ou suggestions]
```

### Règles absolues

- **Jamais** déclarer une tâche terminée sans avoir relancé la commande de vérification
- **Jamais** sauter l'étape RED (test qui échoue) même si "évidente"
- **Toujours** committer avant de passer à la tâche suivante
- **Stopper** immédiatement en cas de régression sur les tests existants
