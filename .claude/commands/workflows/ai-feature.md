---
description: "Développement d'une feature IA/LLM end-to-end : RAG, agent, chatbot ou classification. Orchestre ai-engineer, architect, security-auditor et qa-engineer."
allowed-tools: Bash, Read, Write, Edit, Grep, Glob, Task
---

# AI Feature Development

Développement de la feature IA : **$ARGUMENTS**

## Phase 1 — Qualification de la tâche LLM

Identifier le type de feature IA :

- **RAG** → Répondre à des questions sur des documents personnalisés
- **Agent** → Orchestrer des outils pour accomplir des tâches complexes
- **Chatbot** → Conversation multi-tour avec mémoire de contexte
- **Classifier** → Catégoriser du texte (sentiment, intent, etc.)
- **Extraction** → Extraire des données structurées depuis du texte

**Lancer l'ai-engineer agent** pour définir :
1. Le choix du modèle (haiku/sonnet/opus selon la complexité)
2. L'architecture du pipeline LLM
3. La stratégie de prompt

## Phase 2 — Architecture (architect agent)

Analyser l'impact système :
- Comment les données entrent dans le pipeline LLM ?
- Où stocker les embeddings ? (pgvector, Pinecone, Weaviate)
- Gestion du contexte et de la mémoire des conversations
- Limites de coût et de latence acceptables
- Créer l'ADR si décision significative

## Phase 3 — Implémentation (ai-engineer agent)

Suivre cet ordre avec la skill `llm-ai-patterns` :

```typescript
// 1. Ingestion des données (si RAG)
// 2. Génération des embeddings
// 3. Stockage dans le vector store
// 4. Pipeline de retrieval
// 5. Prompt system + augmentation
// 6. Streaming de la réponse
// 7. Structured output si nécessaire
```

Commandes à valider :
```bash
# Type checking
npm run type-check

# Tests
npm test -- --grep "ai|llm|rag|chat"
```

## Phase 4 — Sécurité (security-auditor agent)

Points critiques pour les features LLM :
- **Prompt injection** : L'utilisateur peut-il manipuler le prompt système ?
- **Data leakage** : Les documents confidentiels peuvent-ils être exposés ?
- **PII dans les logs** : Les messages utilisateur sont-ils loggués ?
- **Rate limiting** : Protection contre les abus coûteux (coût API)
- **Output sanitization** : Le contenu généré est-il filtré avant affichage ?

## Phase 5 — Évaluation (ai-engineer + qa-engineer agents)

Métriques d'évaluation LLM :

```typescript
// LLM-as-judge : évaluer la qualité des réponses
const evalCriteria = [
  'faithfulness',      // La réponse est-elle basée sur les documents ?
  'relevance',         // La réponse répond-elle à la question ?
  'coherence',         // La réponse est-elle logique et bien structurée ?
  'hallucination',     // Contient-elle des informations inventées ?
]

// Tests de régression : snapshots des réponses critiques
// Tester avec 20+ questions de validation
```

## Phase 6 — Monitoring production

Configurer le monitoring avec la skill `observability-patterns` :
- **Latence** : Time-to-first-token, durée totale de la réponse
- **Coûts** : Tokens consommés par requête (input + output)
- **Qualité** : Thumbs up/down des utilisateurs
- **Erreurs** : Timeouts, refusals, content filter triggers

## Rapport de livraison

```markdown
## Feature IA Livrée : $ARGUMENTS

### Type : [RAG | Agent | Chatbot | Classifier | Extraction]
### Modèle utilisé : [claude-haiku-4-5 | claude-sonnet-4-6 | claude-opus-4-5]

### Architecture du pipeline
[Description courte]

### Coût estimé
- Tokens/requête : ~X input + ~Y output
- Coût/1000 requêtes : ~$Z

### Tests
- Tests unitaires : X nouveaux
- Tests d'évaluation LLM : X questions testées
- Score qualité baseline : X/10

### Points de vigilance sécurité
- ...

### Prêt pour merge : ✅ / ❌
```
