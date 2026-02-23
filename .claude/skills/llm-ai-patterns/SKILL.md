---
name: llm-ai-patterns
description: "Patterns pour applications LLM/IA : RAG, agents, embeddings, vector search, évaluation de prompts, structured output et orchestration multi-agents avec l'SDK Anthropic. Activer pour tout projet intégrant Claude/LLMs, chatbots, agents IA ou pipelines RAG."
license: MIT
sources: "wshobson/agents (langchain-architecture, rag-implementation, llm-evaluation, prompt-engineering-patterns, embedding-strategies)"
---

# LLM & AI Patterns

## Quand utiliser cette skill

- Construction d'une application LLM (chatbot, agent, assistant)
- Implémentation d'un pipeline RAG (Retrieval-Augmented Generation)
- Recherche sémantique avec embeddings et vector databases
- Évaluation et optimisation de prompts
- Orchestration multi-agents avec l'Anthropic SDK

## 1. Client Anthropic — Setup de base

```typescript
import Anthropic from '@anthropic-ai/sdk'

const client = new Anthropic({
  apiKey: process.env.ANTHROPIC_API_KEY,
})

// Appel de base avec gestion d'erreurs
const response = await client.messages.create({
  model: 'claude-opus-4-5',
  max_tokens: 4096,
  system: 'Tu es un assistant expert en...',
  messages: [{ role: 'user', content: userMessage }],
})

const text = response.content[0].type === 'text' ? response.content[0].text : ''
```

## 2. Streaming pour UX réactive

```typescript
// Streaming avec Server-Sent Events (Next.js App Router)
export async function POST(req: Request) {
  const { message } = await req.json()

  const stream = await client.messages.stream({
    model: 'claude-sonnet-4-6',
    max_tokens: 2048,
    messages: [{ role: 'user', content: message }],
  })

  return new Response(stream.toReadableStream())
}

// Côté client
const response = await fetch('/api/chat', { method: 'POST', body: JSON.stringify({ message }) })
const reader = response.body!.getReader()
while (true) {
  const { done, value } = await reader.read()
  if (done) break
  setOutput(prev => prev + new TextDecoder().decode(value))
}
```

## 3. Tool Use (Function Calling)

```typescript
const tools: Anthropic.Tool[] = [
  {
    name: 'search_database',
    description: 'Search the product database by keyword or category',
    input_schema: {
      type: 'object',
      properties: {
        query: { type: 'string', description: 'Search query' },
        category: { type: 'string', enum: ['electronics', 'clothing', 'food'] },
        limit: { type: 'number', default: 10 },
      },
      required: ['query'],
    },
  },
]

// Boucle agentique avec tool use
const messages: Anthropic.MessageParam[] = [
  { role: 'user', content: userRequest }
]

while (true) {
  const response = await client.messages.create({
    model: 'claude-opus-4-5',
    max_tokens: 4096,
    tools,
    messages,
  })

  if (response.stop_reason === 'end_turn') break

  if (response.stop_reason === 'tool_use') {
    const toolUse = response.content.find(b => b.type === 'tool_use') as Anthropic.ToolUseBlock
    const toolResult = await executeTool(toolUse.name, toolUse.input)

    messages.push({ role: 'assistant', content: response.content })
    messages.push({
      role: 'user',
      content: [{ type: 'tool_result', tool_use_id: toolUse.id, content: JSON.stringify(toolResult) }],
    })
  }
}
```

## 4. RAG — Retrieval-Augmented Generation

```typescript
import { embed } from './embeddings'
import { vectorSearch } from './vector-db'

const ragPipeline = async (userQuery: string): Promise<string> => {
  // 1. Embed la question
  const queryEmbedding = await embed(userQuery)

  // 2. Récupérer les documents pertinents
  const relevantDocs = await vectorSearch(queryEmbedding, { topK: 5, minScore: 0.7 })

  // 3. Construire le contexte
  const context = relevantDocs
    .map((doc, i) => `[Document ${i + 1}]\n${doc.content}`)
    .join('\n\n')

  // 4. Générer la réponse avec le contexte
  const response = await client.messages.create({
    model: 'claude-sonnet-4-6',
    max_tokens: 2048,
    system: `Tu es un assistant qui répond aux questions en utilisant UNIQUEMENT
les documents fournis. Si la réponse n'est pas dans les documents, dis-le clairement.`,
    messages: [{
      role: 'user',
      content: `Documents de référence:\n${context}\n\nQuestion: ${userQuery}`,
    }],
  })

  return response.content[0].type === 'text' ? response.content[0].text : ''
}
```

## 5. Embeddings et Vector Search

```typescript
// Générer des embeddings avec l'API Voyage AI (recommandé par Anthropic)
import voyageai from 'voyageai'

const voyage = new voyageai.Client()

const embed = async (texts: string[]): Promise<number[][]> => {
  const result = await voyage.embed({
    input: texts,
    model: 'voyage-3',
  })
  return result.embeddings
}

// Calcul de similarité cosinus
const cosineSimilarity = (a: number[], b: number[]): number => {
  const dot = a.reduce((sum, val, i) => sum + val * b[i], 0)
  const normA = Math.sqrt(a.reduce((sum, val) => sum + val ** 2, 0))
  const normB = Math.sqrt(b.reduce((sum, val) => sum + val ** 2, 0))
  return dot / (normA * normB)
}
```

## 6. Structured Output avec Zod

```typescript
import { z } from 'zod'

const AnalysisSchema = z.object({
  sentiment: z.enum(['positive', 'negative', 'neutral']),
  confidence: z.number().min(0).max(1),
  keyTopics: z.array(z.string()).max(5),
  summary: z.string().max(200),
})

type Analysis = z.infer<typeof AnalysisSchema>

const analyzeText = async (text: string): Promise<Analysis> => {
  const response = await client.messages.create({
    model: 'claude-haiku-4-5',
    max_tokens: 1024,
    tools: [{
      name: 'submit_analysis',
      description: 'Submit text analysis results',
      input_schema: {
        type: 'object',
        properties: {
          sentiment: { type: 'string', enum: ['positive', 'negative', 'neutral'] },
          confidence: { type: 'number', minimum: 0, maximum: 1 },
          keyTopics: { type: 'array', items: { type: 'string' }, maxItems: 5 },
          summary: { type: 'string', maxLength: 200 },
        },
        required: ['sentiment', 'confidence', 'keyTopics', 'summary'],
      },
    }],
    tool_choice: { type: 'tool', name: 'submit_analysis' },
    messages: [{ role: 'user', content: `Analyze this text: ${text}` }],
  })

  const toolUse = response.content.find(b => b.type === 'tool_use') as Anthropic.ToolUseBlock
  return AnalysisSchema.parse(toolUse.input)
}
```

## 7. Multi-turn Conversation avec mémoire

```typescript
interface ConversationManager {
  messages: Anthropic.MessageParam[]
  add(role: 'user' | 'assistant', content: string): void
  trim(maxTokens?: number): void
}

const createConversation = (): ConversationManager => ({
  messages: [],
  add(role, content) { this.messages.push({ role, content }) },
  trim(maxTokens = 100_000) {
    // Garder toujours le premier message + les N derniers
    while (this.messages.length > 2) {
      this.messages.splice(1, 1)
    }
  },
})
```

## 8. Évaluation LLM-as-Judge

```typescript
const evaluateResponse = async (
  question: string,
  answer: string,
  criteria: string[]
): Promise<{ scores: Record<string, number>; feedback: string }> => {
  const response = await client.messages.create({
    model: 'claude-opus-4-5',
    max_tokens: 1024,
    system: 'Tu es un évaluateur expert et objectif.',
    messages: [{
      role: 'user',
      content: `Question: ${question}\nRéponse: ${answer}\n\n
Évalue selon ces critères: ${criteria.join(', ')}
Donne un score de 0 à 10 pour chaque critère et un feedback global.`,
    }],
  })
  // ... parser la réponse structurée
}
```

## Anti-patterns à éviter

```typescript
// ❌ Hardcoder le contexte de conversation (perd l'historique)
messages = [{ role: 'user', content: newMessage }]

// ✅ Maintenir l'historique
messages.push({ role: 'user', content: newMessage })

// ❌ Prompts vagues sans exemples
'Réponds bien à la question'

// ✅ Prompts précis avec exemples et contraintes
'Réponds en 3 points maximum. Format: bullet points. Langue: français.'

// ❌ Ignorer les token limits
// Un message peut avoir des millions de tokens → coûteux et lent

// ✅ Chunking + RAG pour les longs documents
// Découper en chunks de ~500 tokens avec overlap de 50
```
