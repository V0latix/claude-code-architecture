---
description: "Génère la documentation complète du projet : README, API docs, guide de contribution et architecture. Analyse le code existant pour produire une doc à jour."
allowed-tools: Bash, Read, Write, Edit, Grep, Glob, Task
---

# Create Documentation

Génération de la documentation pour : **$ARGUMENTS**

Si `$ARGUMENTS` est vide, générer toute la documentation du projet.

## Instructions

Utilise le `doc-writer` agent pour :

### 1. Analyser le projet

```bash
# Structure du projet
find . -type f -name "*.ts" -o -name "*.tsx" | grep -v node_modules | head -30
cat package.json | jq '{name, description, version, scripts}'
```

### 2. Générer selon les besoins

**Si `$ARGUMENTS` = "readme"** → Créer/mettre à jour `README.md`
**Si `$ARGUMENTS` = "api"** → Créer `docs/api-reference.md`
**Si `$ARGUMENTS` = "contributing"** → Créer `CONTRIBUTING.md`
**Si `$ARGUMENTS` = "architecture"** → Créer `docs/architecture.md`
**Si vide** → Générer tous les fichiers ci-dessus

### 3. Contenu minimal par document

**README.md** :
- Description du projet
- Installation rapide (< 5 commandes)
- Exemple d'utilisation minimal
- Liens vers la doc
- Guide de contribution

**docs/api-reference.md** :
- Toutes les routes/endpoints
- Paramètres et types
- Exemples de requêtes/réponses
- Codes d'erreur

**CONTRIBUTING.md** :
- Setup de l'environnement de dev
- Conventions de code
- Process de PR
- Standards de commits

**docs/architecture.md** :
- Vue d'ensemble du système
- Diagramme des composants (ASCII)
- Flux de données principaux
- Décisions techniques (ADR)
