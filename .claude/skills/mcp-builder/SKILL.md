---
name: mcp-builder
description: "Guide pour créer des serveurs MCP (Model Context Protocol) de qualité en TypeScript ou Python. Activer pour construire un nouveau serveur MCP, intégrer une API externe dans Claude, ou déboguer un serveur MCP existant."
license: MIT
sources: "anthropics/skills (mcp-builder skill)"
---

# MCP Builder

## Quand utiliser cette skill

- Créer un serveur MCP pour intégrer une API externe dans Claude
- Déboguer ou améliorer un serveur MCP existant
- Comprendre les patterns MCP pour tool design
- Évaluer la qualité d'un serveur MCP

## Principe fondamental

> "La qualité d'un serveur MCP se mesure à sa capacité à permettre à un LLM d'accomplir des tâches réelles efficacement."

## 1. Structure d'un serveur MCP TypeScript (recommandé)

```typescript
// server.ts
import { McpServer } from '@modelcontextprotocol/sdk/server/mcp.js'
import { StdioServerTransport } from '@modelcontextprotocol/sdk/server/stdio.js'
import { z } from 'zod'

const server = new McpServer({
  name: 'my-service',
  version: '1.0.0',
})

// Définir un outil
server.tool(
  'search_products',
  'Search products in the catalog by keyword and filters',
  {
    query: z.string().describe('Search keyword or phrase'),
    category: z.enum(['electronics', 'clothing', 'food']).optional()
      .describe('Optional category filter'),
    maxResults: z.number().min(1).max(50).default(10)
      .describe('Maximum number of results to return'),
  },
  async ({ query, category, maxResults }) => {
    try {
      const results = await searchProducts({ query, category, limit: maxResults })

      if (results.length === 0) {
        return {
          content: [{ type: 'text', text: `No products found for "${query}"` }],
        }
      }

      const formatted = results.map(p =>
        `- **${p.name}** (${p.category}): $${p.price} — ${p.description}`
      ).join('\n')

      return {
        content: [{
          type: 'text',
          text: `Found ${results.length} products:\n\n${formatted}`,
        }],
      }
    } catch (error) {
      return {
        content: [{
          type: 'text',
          text: `Search failed: ${error instanceof Error ? error.message : 'Unknown error'}. Try with different keywords or check if the service is available.`,
        }],
        isError: true,
      }
    }
  }
)

// Démarrer le serveur
const transport = new StdioServerTransport()
await server.connect(transport)
```

## 2. Resources MCP (données exposées)

```typescript
// Exposer des ressources accessibles par Claude
server.resource(
  'system-status',
  'status://system',
  'Current system health status',
  async () => {
    const status = await checkHealth()
    return {
      contents: [{
        uri: 'status://system',
        mimeType: 'application/json',
        text: JSON.stringify(status, null, 2),
      }],
    }
  }
)

// Resource dynamique avec URI templates
server.resource(
  'user-profile',
  new ResourceTemplate('user://{userId}/profile', { list: undefined }),
  'User profile data',
  async (uri, { userId }) => {
    const user = await getUserById(userId)
    return {
      contents: [{
        uri: uri.href,
        mimeType: 'application/json',
        text: JSON.stringify(user, null, 2),
      }],
    }
  }
)
```

## 3. Prompts MCP (workflows prédéfinis)

```typescript
// Prompts réutilisables pour des workflows courants
server.prompt(
  'analyze-repository',
  'Analyze a GitHub repository for code quality and security',
  {
    owner: z.string().describe('GitHub owner/organization'),
    repo: z.string().describe('Repository name'),
    focus: z.enum(['security', 'quality', 'performance']).optional(),
  },
  async ({ owner, repo, focus }) => ({
    messages: [{
      role: 'user',
      content: {
        type: 'text',
        text: `Please analyze the repository ${owner}/${repo}.
${focus ? `Focus specifically on: ${focus}` : 'Cover: code quality, security vulnerabilities, and architecture.'}
Use the available tools to fetch the repository contents and provide actionable recommendations.`,
      },
    }],
  })
)
```

## 4. Bonnes pratiques de tool design

```typescript
// ✅ Noms d'outils : verbe_objet en snake_case
'search_documents', 'create_issue', 'update_user', 'delete_record'

// ✅ Descriptions riches (le LLM prend ses décisions dessus)
// Description précise : quand l'utiliser, ce qu'elle retourne, limites
description: `Search GitHub issues in a repository. Returns issues with title,
number, state, labels, and assignees. Best for finding existing issues or
checking if a bug has been reported. Use create_issue to open new issues.`

// ✅ Paramètres avec descriptions et valeurs par défaut
{
  query: z.string().describe('Search query using GitHub search syntax'),
  state: z.enum(['open', 'closed', 'all']).default('open').describe('Issue state filter'),
  perPage: z.number().min(1).max(100).default(30).describe('Results per page'),
}

// ✅ Réponses informatives même en cas d'échec
if (results.length === 0) {
  return { content: [{ type: 'text',
    text: `No issues found matching "${query}". Try: broader terms, check spelling, or use 'state: all' to include closed issues.`
  }]}
}
```

## 5. Configuration .mcp.json

```json
{
  "mcpServers": {
    "my-service": {
      "command": "node",
      "args": ["path/to/server.js"],
      "env": {
        "API_KEY": "${MY_API_KEY}",
        "BASE_URL": "https://api.example.com"
      }
    },
    "python-service": {
      "command": "python",
      "args": ["-m", "my_mcp_server"],
      "env": { "DATABASE_URL": "${DATABASE_URL}" }
    }
  }
}
```

## 6. Évaluation — 10 questions de test

Avant de considérer un serveur MCP prêt :

1. Peut-il effectuer la tâche principale end-to-end ?
2. Les messages d'erreur sont-ils actionnables ?
3. Gère-t-il correctement les données vides/nulles ?
4. Fonctionne-t-il avec des paramètres inhabituels mais valides ?
5. Les descriptions des outils permettent-elles un bon choix par le LLM ?
6. Les réponses sont-elles bien formatées pour la lecture ?
7. Les timeouts et limites de taux sont-ils gérés ?
8. Les secrets sont-ils passés via variables d'environnement ?
9. Le serveur s'arrête-t-il proprement (SIGTERM) ?
10. Les opérations destructives ont-elles une confirmation ?

## Anti-patterns à éviter

```typescript
// ❌ Trop d'outils spécialisés (difficile de choisir pour le LLM)
'search_by_name', 'search_by_id', 'search_by_email', 'search_by_phone'

// ✅ Un outil flexible avec paramètres optionnels
'search_users' avec { query, searchBy: 'name' | 'id' | 'email' | 'phone' }

// ❌ Erreurs cryptiques
throw new Error('404')

// ✅ Erreurs explicatives
return { content: [{ type: 'text', text: 'User not found. Check that the userId exists and you have access.' }], isError: true }

// ❌ Retourner des données brutes JSON non formatées
return { content: [{ type: 'text', text: JSON.stringify(data) }] }

// ✅ Format lisible par le LLM
return { content: [{ type: 'text', text: formatForReadability(data) }] }
```
