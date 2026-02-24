---
description: "Génère un projet d'extension VSCode complet et runnable : package.json manifest, src/extension.ts, provider selon le type, tests Mocha, esbuild config, tsconfig.json, .vscodeignore et .vscode/launch.json. Arguments : [nom-extension] [type] où type = command | treeview | webview | language | chat-participant."
allowed-tools: Bash, Read, Write, Edit, Grep, Glob, Task
---

# VSCode Extension Scaffold

Génération du scaffold pour l'extension VSCode : **$ARGUMENTS**

Format de `$ARGUMENTS` : `[nom-extension] [type]`

| Exemples |
|----------|
| `prisma-explorer treeview` |
| `code-reviewer chat-participant` |
| `myconfig-support language` |
| `hello-world command` |
| `my-dashboard webview` |

Types supportés : `command` (défaut) | `treeview` | `webview` | `language` | `chat-participant`

---

## Instructions

### Étape 1 — Parser les arguments

```bash
# Vérifier l'environnement
node --version && npm --version
```

Extraire depuis `$ARGUMENTS` :
- `EXTENSION_NAME` : première partie (kebab-case, ex: `prisma-explorer`)
- `EXTENSION_TYPE` : deuxième partie (ex: `treeview`), défaut: `command`
- `EXTENSION_DISPLAY_NAME` : convertir kebab-case → Title Case (ex: `Prisma Explorer`)
- `PUBLISHER` : lire depuis un `package.json` existant si présent, sinon utiliser `mon-publisher`

---

### Étape 2 — Générer les 10 fichiers

#### Fichier 1 : `package.json`

Manifest VSCode complet. Le bloc `contributes` varie selon le type :

**Si `command` :**
```json
{
  "name": "$EXTENSION_NAME",
  "displayName": "$EXTENSION_DISPLAY_NAME",
  "description": "Description de l'extension",
  "version": "0.0.1",
  "publisher": "$PUBLISHER",
  "engines": { "vscode": "^1.85.0" },
  "categories": ["Other"],
  "repository": { "type": "git", "url": "https://github.com/$PUBLISHER/$EXTENSION_NAME" },
  "activationEvents": ["onCommand:$EXTENSION_NAME.action"],
  "main": "./dist/extension.js",
  "contributes": {
    "commands": [
      { "command": "$EXTENSION_NAME.action", "title": "Run Action", "category": "$EXTENSION_DISPLAY_NAME" }
    ],
    "menus": {
      "commandPalette": [{ "command": "$EXTENSION_NAME.action" }]
    }
  },
  "scripts": {
    "vscode:prepublish": "node esbuild.js --production",
    "compile": "node esbuild.js",
    "watch": "node esbuild.js --watch",
    "pretest": "node esbuild.js && npx tsc --noEmit",
    "test": "npx @vscode/test-cli run"
  },
  "devDependencies": {
    "@types/vscode": "^1.85.0",
    "@types/mocha": "^10.0.6",
    "@types/node": "20.x",
    "@vscode/test-cli": "^0.0.9",
    "@vscode/test-electron": "^2.3.9",
    "esbuild": "^0.20.0",
    "typescript": "^5.3.3"
  }
}
```

**Si `treeview` :** ajouter dans `contributes` :
```json
"views": {
  "explorer": [{ "id": "$EXTENSION_NAME.treeView", "name": "$EXTENSION_DISPLAY_NAME" }]
},
"commands": [
  { "command": "$EXTENSION_NAME.refresh", "title": "Refresh", "icon": "$(refresh)" }
],
"menus": {
  "view/title": [{ "command": "$EXTENSION_NAME.refresh", "when": "view == $EXTENSION_NAME.treeView", "group": "navigation" }]
}
```
Activation event : `"onView:$EXTENSION_NAME.treeView"`

**Si `webview` :** activation event : `"onCommand:$EXTENSION_NAME.openPanel"`

**Si `language` :** ajouter dans `contributes` :
```json
"languages": [{ "id": "$EXTENSION_NAME", "aliases": ["$EXTENSION_DISPLAY_NAME"], "extensions": [".$EXTENSION_NAME"] }],
"grammars": [{ "language": "$EXTENSION_NAME", "scopeName": "source.$EXTENSION_NAME", "path": "./syntaxes/$EXTENSION_NAME.tmLanguage.json" }]
```
Activation event : `"onLanguage:$EXTENSION_NAME"`

**Si `chat-participant` :** ajouter dans `contributes` :
```json
"chatParticipants": [{
  "id": "$EXTENSION_NAME.assistant",
  "name": "$EXTENSION_NAME",
  "description": "Assistant $EXTENSION_DISPLAY_NAME",
  "isSticky": false
}]
```
Activation event : `"onStartupFinished"`

---

#### Fichier 2 : `src/extension.ts`

```typescript
import * as vscode from 'vscode'
// TYPE-SPECIFIC IMPORT PLACEHOLDER

export function activate(context: vscode.ExtensionContext): void {
  console.log('Extension "$EXTENSION_NAME" is now active')

  // TYPE-SPECIFIC ACTIVATION PLACEHOLDER
}

export function deactivate(): void {
  // Nettoyage synchrone si nécessaire
  // Les disposables de context.subscriptions sont automatiquement disposés
}
```

**Si `command` :** remplacer le placeholder par :
```typescript
const disposable = vscode.commands.registerCommand('$EXTENSION_NAME.action', async () => {
  await vscode.window.withProgress(
    { location: vscode.ProgressLocation.Notification, title: 'Action en cours...', cancellable: true },
    async (_progress, token) => {
      token.onCancellationRequested(() => vscode.window.showWarningMessage('Action annulée'))
      // TODO: Implémenter la logique
      vscode.window.showInformationMessage('$EXTENSION_DISPLAY_NAME : action terminée !')
    }
  )
})
context.subscriptions.push(disposable)
```

**Si `treeview` :** importer le provider et l'enregistrer :
```typescript
import { $ExtensionNameTreeProvider } from './providers/tree-provider'
const provider = new $ExtensionNameTreeProvider()
const treeView = vscode.window.createTreeView('$EXTENSION_NAME.treeView', {
  treeDataProvider: provider,
  showCollapseAll: true,
})
const refreshCmd = vscode.commands.registerCommand('$EXTENSION_NAME.refresh', () => provider.refresh())
context.subscriptions.push(treeView, refreshCmd)
```

**Si `webview` :** importer et créer le panel :
```typescript
import { $ExtensionNamePanel } from './providers/webview-panel'
const openCmd = vscode.commands.registerCommand('$EXTENSION_NAME.openPanel', () => {
  $ExtensionNamePanel.createOrShow(context.extensionUri)
})
context.subscriptions.push(openCmd)
```

**Si `language` :** enregistrer les providers :
```typescript
import { $ExtensionNameCompletionProvider } from './providers/completion-provider'
const completionProvider = vscode.languages.registerCompletionItemProvider(
  { language: '$EXTENSION_NAME', scheme: 'file' },
  new $ExtensionNameCompletionProvider(),
  '.'
)
context.subscriptions.push(completionProvider)
```

**Si `chat-participant` :** enregistrer le participant :
```typescript
import { registerChatParticipant } from './providers/chat-handler'
registerChatParticipant(context)
```

---

#### Fichier 3 : `src/providers/[type]-provider.ts`

**Si `treeview` → `src/providers/tree-provider.ts` :**
```typescript
import * as vscode from 'vscode'

interface TreeNodeData { id: string; label: string; children?: TreeNodeData[] }

export class $ExtensionNameTreeItem extends vscode.TreeItem {
  constructor(public readonly data: TreeNodeData, state: vscode.TreeItemCollapsibleState) {
    super(data.label, state)
    this.id = data.id
    this.tooltip = data.label
    this.contextValue = data.children?.length ? 'folder' : 'item'
    this.iconPath = new vscode.ThemeIcon(data.children?.length ? 'folder' : 'file')
  }
}

export class $ExtensionNameTreeProvider implements vscode.TreeDataProvider<$ExtensionNameTreeItem> {
  private readonly _onDidChangeTreeData = new vscode.EventEmitter<$ExtensionNameTreeItem | undefined | null>()
  readonly onDidChangeTreeData = this._onDidChangeTreeData.event
  private data: TreeNodeData[] = [
    { id: '1', label: 'Item 1' },
    { id: '2', label: 'Item 2', children: [{ id: '3', label: 'Sous-item' }] },
  ]

  refresh(newData?: TreeNodeData[]): void {
    if (newData) this.data = newData
    this._onDidChangeTreeData.fire(undefined)
  }

  getTreeItem(element: $ExtensionNameTreeItem): vscode.TreeItem { return element }

  getChildren(element?: $ExtensionNameTreeItem): $ExtensionNameTreeItem[] {
    const nodes = element ? element.data.children ?? [] : this.data
    return nodes.map(n => new $ExtensionNameTreeItem(
      n,
      n.children?.length ? vscode.TreeItemCollapsibleState.Collapsed : vscode.TreeItemCollapsibleState.None
    ))
  }
}
```

**Si `webview` → `src/providers/webview-panel.ts` :**
```typescript
import * as vscode from 'vscode'
import * as crypto from 'crypto'

export class $ExtensionNamePanel {
  static currentPanel: $ExtensionNamePanel | undefined
  private readonly _panel: vscode.WebviewPanel
  private _disposables: vscode.Disposable[] = []

  static createOrShow(extensionUri: vscode.Uri): void {
    if ($ExtensionNamePanel.currentPanel) {
      $ExtensionNamePanel.currentPanel._panel.reveal()
      return
    }
    const panel = vscode.window.createWebviewPanel('$EXTENSION_NAME', '$EXTENSION_DISPLAY_NAME',
      vscode.ViewColumn.One, { enableScripts: true, localResourceRoots: [vscode.Uri.joinPath(extensionUri, 'media')] })
    $ExtensionNamePanel.currentPanel = new $ExtensionNamePanel(panel, extensionUri)
  }

  private constructor(panel: vscode.WebviewPanel, extensionUri: vscode.Uri) {
    this._panel = panel
    const nonce = crypto.randomBytes(16).toString('hex')
    this._panel.webview.html = `<!DOCTYPE html><html lang="fr">
<head>
  <meta charset="UTF-8" />
  <meta http-equiv="Content-Security-Policy" content="default-src 'none'; script-src 'nonce-${nonce}';" />
  <title>$EXTENSION_DISPLAY_NAME</title>
</head>
<body>
  <h1>$EXTENSION_DISPLAY_NAME</h1>
  <button id="btn">Action</button>
  <script nonce="${nonce}">
    const vscode = acquireVsCodeApi();
    document.getElementById('btn').addEventListener('click', () => {
      vscode.postMessage({ command: 'action' });
    });
  </script>
</body></html>`
    this._panel.webview.onDidReceiveMessage(msg => {
      if (msg.command === 'action') vscode.window.showInformationMessage('Action depuis le Webview !')
    }, null, this._disposables)
    this._panel.onDidDispose(() => this.dispose(), null, this._disposables)
  }

  dispose(): void {
    $ExtensionNamePanel.currentPanel = undefined
    this._panel.dispose()
    this._disposables.forEach(d => d.dispose())
    this._disposables = []
  }
}
```

**Si `language` → `src/providers/completion-provider.ts` :**
```typescript
import * as vscode from 'vscode'

export class $ExtensionNameCompletionProvider implements vscode.CompletionItemProvider {
  provideCompletionItems(
    document: vscode.TextDocument,
    position: vscode.Position
  ): vscode.CompletionItem[] {
    const linePrefix = document.lineAt(position).text.slice(0, position.character)
    if (!linePrefix.endsWith('.')) return []
    return [
      Object.assign(new vscode.CompletionItem('property1', vscode.CompletionItemKind.Property), {
        documentation: new vscode.MarkdownString('Description de property1'),
      }),
      Object.assign(new vscode.CompletionItem('method1', vscode.CompletionItemKind.Method), {
        insertText: new vscode.SnippetString('method1(${1:param})'),
      }),
    ]
  }
}
```

**Si `chat-participant` → `src/providers/chat-handler.ts` :**
```typescript
import * as vscode from 'vscode'

export function registerChatParticipant(context: vscode.ExtensionContext): void {
  const handler: vscode.ChatRequestHandler = async (request, _chatContext, stream, token) => {
    const models = await vscode.lm.selectChatModels({ vendor: 'copilot', family: 'gpt-4o' })
    if (!models.length) { stream.markdown('Aucun modèle disponible.'); return {} }
    stream.progress('Analyse en cours...')
    const messages = [
      vscode.LanguageModelChatMessage.User('Tu es un assistant $EXTENSION_DISPLAY_NAME. Réponds en français.'),
      vscode.LanguageModelChatMessage.User(request.prompt),
    ]
    const response = await models[0].sendRequest(messages, {}, token)
    for await (const chunk of response.text) {
      if (token.isCancellationRequested) break
      stream.markdown(chunk)
    }
    return {}
  }
  const participant = vscode.chat.createChatParticipant('$EXTENSION_NAME.assistant', handler)
  participant.iconPath = vscode.Uri.joinPath(context.extensionUri, 'images', 'icon.png')
  context.subscriptions.push(participant)
}
```

---

#### Fichier 4 : `test/suite/extension.test.ts`

```typescript
import * as assert from 'assert'
import * as vscode from 'vscode'

suite('$EXTENSION_DISPLAY_NAME Test Suite', () => {
  suiteSetup(async () => {
    const ext = vscode.extensions.getExtension('$PUBLISHER.$EXTENSION_NAME')
    if (ext && !ext.isActive) await ext.activate()
  })

  test('Extension should be active', () => {
    const ext = vscode.extensions.getExtension('$PUBLISHER.$EXTENSION_NAME')
    assert.ok(ext?.isActive, 'Extension should be active after activation')
  })

  // TYPE-SPECIFIC TEST PLACEHOLDER
  // Si command : test('Command should be registered', async () => {
  //   const commands = await vscode.commands.getCommands(true)
  //   assert.ok(commands.includes('$EXTENSION_NAME.action'))
  // })
})
```

---

#### Fichier 5 : `test/runTest.ts`

```typescript
import { run } from '@vscode/test-cli'

run({
  files: 'dist/test/suite/**/*.test.js',
  workspaceFolder: '.',
}).catch(err => {
  console.error('Tests failed:', err)
  process.exit(1)
})
```

---

#### Fichier 6 : `esbuild.js`

```javascript
const esbuild = require('esbuild')

const isProduction = process.argv.includes('--production')
const isWatch = process.argv.includes('--watch')

const buildOptions = {
  entryPoints: ['src/extension.ts'],
  bundle: true,
  outfile: 'dist/extension.js',
  external: ['vscode'],   // Fourni par l'Extension Host
  format: 'cjs',          // CommonJS obligatoire
  platform: 'node',
  target: 'node20',
  sourcemap: !isProduction,
  minify: isProduction,
  logLevel: 'info',
}

if (isWatch) {
  esbuild.context(buildOptions).then(ctx => { void ctx.watch(); console.log('Watching...') })
} else {
  esbuild.build(buildOptions).catch(() => process.exit(1))
}
```

---

#### Fichier 7 : `tsconfig.json`

```json
{
  "compilerOptions": {
    "module": "commonjs",
    "target": "ES2020",
    "lib": ["ES2020"],
    "outDir": "dist",
    "rootDir": "src",
    "strict": true,
    "skipLibCheck": true,
    "esModuleInterop": true
  },
  "include": ["src"],
  "exclude": ["node_modules", ".vscode-test", "dist"]
}
```

---

#### Fichier 8 : `.vscodeignore`

```
.vscode/**
.vscode-test/**
src/**
test/**
.gitignore
esbuild.js
tsconfig.json
**/*.map
**/*.ts
!dist/**
```

---

#### Fichier 9 : `.vscode/launch.json`

```json
{
  "version": "0.2.0",
  "configurations": [
    {
      "name": "Run Extension",
      "type": "extensionHost",
      "request": "launch",
      "args": ["--extensionDevelopmentPath=${workspaceFolder}"],
      "outFiles": ["${workspaceFolder}/dist/**/*.js"],
      "preLaunchTask": "npm: compile",
      "sourceMaps": true
    },
    {
      "name": "Extension Tests",
      "type": "extensionHost",
      "request": "launch",
      "args": [
        "--extensionDevelopmentPath=${workspaceFolder}",
        "--extensionTestsPath=${workspaceFolder}/dist/test/suite"
      ],
      "outFiles": ["${workspaceFolder}/dist/**/*.js"],
      "preLaunchTask": "npm: pretest"
    }
  ]
}
```

---

#### Fichier 10 : `CHANGELOG.md`

```markdown
# Changelog

Toutes les modifications notables de cette extension sont documentées ici.
Format basé sur [Keep a Changelog](https://keepachangelog.com/fr/1.0.0/).

## [Unreleased]

## [0.0.1] - AAAA-MM-JJ

### Ajouté
- Version initiale de $EXTENSION_DISPLAY_NAME
```

---

### Étape 3 — Post-scaffold

Afficher le récapitulatif des fichiers générés :

```
✅ Scaffold généré : $EXTENSION_NAME ($EXTENSION_TYPE)

Fichiers créés :
  package.json              → Manifest VSCode
  src/extension.ts          → Point d'entrée
  src/providers/            → Provider $EXTENSION_TYPE
  test/suite/               → Tests Mocha
  test/runTest.ts           → Runner @vscode/test-cli
  esbuild.js                → Build script
  tsconfig.json             → TypeScript config (strict)
  .vscodeignore             → Exclusions .vsix
  .vscode/launch.json       → Debug configurations
  CHANGELOG.md              → Changelog Marketplace

Prochaines étapes :
  1. npm install && npm install --save-dev esbuild
  2. npm run compile
  3. Ouvrir dans VSCode → F5 → "Run Extension"
  4. Implémenter la logique dans src/providers/
  5. /workflows/vscode-extension-dev pour le cycle complet
```

```bash
# Commandes initiales
npm install
npm install --save-dev esbuild
npm run compile
code .
```
