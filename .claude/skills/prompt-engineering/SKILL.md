---
name: prompt-engineering
description: "Techniques d'optimisation de prompts pour LLMs : few-shot, chain-of-thought, structuration XML, prompts système, évaluation et patterns pour Claude. Activer lors de la conception de prompts pour applications LLM ou lors de l'optimisation de la qualité des réponses."
license: MIT
---

# Prompt Engineering

## Quand utiliser cette skill

- Conception de prompts pour applications LLM
- Optimisation de la qualité des réponses
- Implémentation d'agents et workflows LLM
- Évaluation et debugging de prompts
- Architecture de systèmes multi-agents

## Techniques fondamentales

### 1. Structure XML pour Claude

```xml
<system>
  Tu es un assistant expert en [domaine].
  Réponds toujours en [langue].
  Format de réponse : [structure attendue]
</system>

<context>
  <project>Description du projet</project>
  <constraints>Contraintes importantes</constraints>
</context>

<task>
  [Description précise de la tâche]
</task>

<examples>
  <example>
    <input>Exemple d'entrée</input>
    <output>Exemple de sortie attendue</output>
  </example>
</examples>
```

### 2. Chain-of-Thought (CoT)

```typescript
const prompt = `
Analyse cette architecture et identifie les problèmes de sécurité.

Réfléchis étape par étape :
1. D'abord, identifie les surfaces d'attaque
2. Ensuite, évalue chaque surface pour les vulnérabilités OWASP
3. Puis, évalue la criticité de chaque problème
4. Enfin, propose des remédiations concrètes

Architecture à analyser :
${architectureDescription}
`
```

### 3. Few-Shot Learning

```typescript
const classifyIntentPrompt = `
Classifie l'intention de l'utilisateur parmi : [question, action, feedback, other]

Exemples :
Input: "Comment fonctionne la pagination ?"
Output: question

Input: "Supprime mon compte"
Output: action

Input: "Le bouton ne fonctionne pas"
Output: feedback

Input: "${userMessage}"
Output:
`
```

### 4. Prompt Système robuste

```typescript
const systemPrompt = `
Tu es un assistant de code senior spécialisé en TypeScript et React.

# Règles absolues
- Ne jamais utiliser `any` en TypeScript
- Toujours écrire des types explicites
- Préférer les composants fonctionnels
- Suivre les conventions du projet

# Format de réponse
- Code uniquement dans des blocs \`\`\`typescript
- Explications courtes avant chaque bloc
- Inclure les imports nécessaires
- Ajouter des commentaires pour la logique complexe uniquement

# Ce que tu ne fais PAS
- Ne pas modifier les fichiers de config (.env, package.json)
- Ne pas créer de nouveaux fichiers sans le demander
- Ne pas supprimer du code existant sans avertir
`
```

### 5. Évaluation de prompts

```typescript
interface PromptEval {
  prompt: string
  testCases: Array<{
    input: string
    expectedOutput: string
    evaluator: (output: string) => boolean
  }>
}

// Évaluation automatique
const runEval = async (eval: PromptEval) => {
  const results = await Promise.all(
    eval.testCases.map(async (tc) => {
      const output = await callLLM(eval.prompt, tc.input)
      return {
        pass: tc.evaluator(output),
        input: tc.input,
        output,
        expected: tc.expectedOutput,
      }
    })
  )

  const passRate = results.filter((r) => r.pass).length / results.length
  return { passRate, results }
}
```

### 6. Structured Output avec Zod

```typescript
import { z } from 'zod'
import Anthropic from '@anthropic-ai/sdk'

const AnalysisSchema = z.object({
  summary: z.string(),
  issues: z.array(z.object({
    severity: z.enum(['critical', 'high', 'medium', 'low']),
    description: z.string(),
    remediation: z.string(),
  })),
  score: z.number().min(0).max(10),
})

const response = await client.messages.create({
  model: 'claude-opus-4-5',
  messages: [{ role: 'user', content: prompt }],
  tools: [{
    name: 'submit_analysis',
    description: 'Submit security analysis results',
    input_schema: zodToJsonSchema(AnalysisSchema),
  }],
  tool_choice: { type: 'tool', name: 'submit_analysis' },
})
```

## Anti-patterns à éviter

```
# ❌ Prompts vagues
"Améliore ce code"

# ✅ Instructions précises et contextuelles
"Refactorise cette fonction pour : 1) Réduire la complexité cyclomatique sous 10,
2) Extraire la logique de validation dans une fonction séparée,
3) Ajouter la gestion d'erreurs avec Result<T, E>"

# ❌ Pas de contexte
"Pourquoi est-ce que ça ne marche pas ?"

# ✅ Contexte complet
"Cette fonction retourne undefined au lieu de l'objet User attendu.
Stack trace : [...]
Code concerné : [...]
Ce que j'attendais : [...]"

# ❌ Demander plusieurs choses à la fois
"Écris les tests, la doc et refactorise le code"

# ✅ Une tâche à la fois
"Écris les tests unitaires pour la fonction processPayment"
```
