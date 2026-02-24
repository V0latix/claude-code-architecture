---
name: vscode-extension
description: "Patterns pour développer des extensions VSCode production-ready : API namespaces (commands, window, workspace, languages, debug, lm), TreeView, WebviewPanel, Language Server Protocol, Chat Participants Copilot, bundling esbuild, tests @vscode/test-cli et publication vsce/ovsx. Activer pour tout développement d'extension VSCode, du scaffold initial à la publication Marketplace."
license: MIT
sources: "microsoft/vscode-extension-samples, code.visualstudio.com/api"
---

# VSCode Extension

## Quand utiliser cette skill

- Développer une extension VSCode : commande, TreeView, Webview, support langage, thème, Chat Participant
- Intégrer des namespaces VSCode API (workspace, languages, debug, lm, scm, tasks)
- Configurer le bundling esbuild et les tests Extension Host
- Publier sur le Marketplace (vsce) ou Open VSX Registry (ovsx)

---

## 1. Structure de projet standard

```
mon-extension/
├── package.json              # Manifest VSCode (contributes, engines, activationEvents)
├── src/
│   ├── extension.ts          # Point d'entrée : activate() + deactivate()
│   ├── commands/             # Handlers de commandes
│   ├── providers/            # TreeDataProvider, CompletionProvider, WebviewProvider...
│   └── utils/                # Helpers, constantes
├── test/
│   ├── suite/
│   │   └── extension.test.ts # Suites Mocha
│   └── runTest.ts            # Runner @vscode/test-cli
├── .vscode/
│   └── launch.json           # Debug "Run Extension" + "Run Tests"
├── esbuild.js                # Script de bundling
├── tsconfig.json
├── .vscodeignore             # Fichiers exclus du .vsix
└── CHANGELOG.md              # Format Keep a Changelog (affiché sur Marketplace)
```

```json
// package.json — champs VSCode spécifiques
{
  "name": "mon-extension",
  "displayName": "Mon Extension",
  "version": "0.0.1",
  "publisher": "mon-publisher",
  "engines": { "vscode": "^1.85.0" },
  "categories": ["Other"],
  "icon": "images/icon.png",
  "repository": { "type": "git", "url": "https://github.com/..." },
  "activationEvents": [
    "onCommand:monext.helloWorld",
    "workspaceContains:**/.monconfig"
  ],
  "main": "./dist/extension.js",
  "contributes": {
    "commands": [
      { "command": "monext.helloWorld", "title": "Hello World", "category": "MonExt" }
    ],
    "configuration": {
      "title": "Mon Extension",
      "properties": {
        "monext.apiKey": { "type": "string", "default": "", "markdownDescription": "Clé API" }
      }
    }
  }
}
```

```typescript
// src/extension.ts — point d'entrée obligatoire
import * as vscode from 'vscode'

export function activate(context: vscode.ExtensionContext): void {
  // Enregistrer toutes les disposables dans context.subscriptions
  // pour éviter les fuites mémoire
  const disposable = vscode.commands.registerCommand('monext.helloWorld', () => {
    vscode.window.showInformationMessage('Hello World!')
  })
  context.subscriptions.push(disposable)
}

export function deactivate(): void {
  // Cleanup synchrone si nécessaire (les subscriptions sont auto-disposées)
}
```

---

## 2. Commands — registerCommand, withProgress, keybindings

```typescript
// Commande simple
const cmd = vscode.commands.registerCommand('monext.action', async () => {
  vscode.window.showInformationMessage('Action déclenchée')
})
context.subscriptions.push(cmd)

// Commande avec opération longue + CancellationToken
const longCmd = vscode.commands.registerCommand('monext.longAction', async () => {
  await vscode.window.withProgress(
    {
      location: vscode.ProgressLocation.Notification,
      title: 'Traitement en cours...',
      cancellable: true,
    },
    async (progress, token) => {
      token.onCancellationRequested(() => {
        vscode.window.showWarningMessage('Opération annulée')
      })

      for (let i = 0; i <= 100; i += 10) {
        if (token.isCancellationRequested) break
        progress.report({ increment: 10, message: `${i}% terminé` })
        await new Promise(resolve => setTimeout(resolve, 200))
      }
    }
  )
})
context.subscriptions.push(longCmd)

// Keybinding dans package.json contributes
// "keybindings": [{ "command": "monext.action", "key": "ctrl+shift+h", "when": "editorFocus" }]

// Commande avec sélection actuelle
const selCmd = vscode.commands.registerCommand('monext.processSelection', async () => {
  const editor = vscode.window.activeTextEditor
  if (!editor) return

  const selection = editor.selection
  const text = editor.document.getText(selection)
  if (!text) {
    vscode.window.showWarningMessage('Sélectionnez du texte d\'abord')
    return
  }

  // Modifier le texte sélectionné
  await editor.edit(editBuilder => {
    editBuilder.replace(selection, text.toUpperCase())
  })
})
context.subscriptions.push(selCmd)
```

---

## 3. TreeView — TreeDataProvider

```typescript
// src/providers/tree-provider.ts
import * as vscode from 'vscode'
import * as path from 'path'

export interface TreeNodeData {
  id: string
  label: string
  children?: TreeNodeData[]
  icon?: string
}

export class MyTreeItem extends vscode.TreeItem {
  constructor(
    public readonly data: TreeNodeData,
    public readonly collapsibleState: vscode.TreeItemCollapsibleState,
  ) {
    super(data.label, collapsibleState)
    this.id = data.id
    this.tooltip = data.label
    this.contextValue = data.children ? 'folder' : 'item'

    if (data.icon) {
      this.iconPath = new vscode.ThemeIcon(data.icon)  // Icônes built-in VSCode
    }

    // Commande exécutée au clic sur l'item (si feuille)
    if (!data.children) {
      this.command = {
        command: 'monext.openItem',
        title: 'Ouvrir',
        arguments: [this],
      }
    }
  }
}

export class MyTreeProvider implements vscode.TreeDataProvider<MyTreeItem> {
  // EventEmitter pour notifier VSCode des changements de données
  private readonly _onDidChangeTreeData = new vscode.EventEmitter<MyTreeItem | undefined | null>()
  readonly onDidChangeTreeData = this._onDidChangeTreeData.event

  private data: TreeNodeData[] = []

  refresh(newData?: TreeNodeData[]): void {
    if (newData) this.data = newData
    this._onDidChangeTreeData.fire(undefined)  // undefined = tout rafraîchir
  }

  getTreeItem(element: MyTreeItem): vscode.TreeItem {
    return element
  }

  getChildren(element?: MyTreeItem): vscode.ProviderResult<MyTreeItem[]> {
    const nodes = element ? element.data.children ?? [] : this.data
    return nodes.map(
      node => new MyTreeItem(
        node,
        node.children?.length
          ? vscode.TreeItemCollapsibleState.Collapsed
          : vscode.TreeItemCollapsibleState.None
      )
    )
  }

  // Optionnel : parent lookup pour reveal()
  getParent(element: MyTreeItem): vscode.ProviderResult<MyTreeItem> {
    return undefined
  }
}

// Enregistrement dans activate()
const provider = new MyTreeProvider()
const treeView = vscode.window.createTreeView('monext.myView', {
  treeDataProvider: provider,
  showCollapseAll: true,
  canSelectMany: false,
})
context.subscriptions.push(treeView)

// package.json contributes
// "views": { "explorer": [{ "id": "monext.myView", "name": "Mon View" }] }
// "viewsContainers": { "activitybar": [{ "id": "monext", "title": "MonExt", "icon": "$(symbol-misc)" }] }
```

---

## 4. WebviewPanel — CSP, postMessage, ressources

```typescript
// src/providers/webview-provider.ts
import * as vscode from 'vscode'
import * as crypto from 'crypto'

export class MyWebviewPanel {
  public static currentPanel: MyWebviewPanel | undefined
  private readonly _panel: vscode.WebviewPanel
  private _disposables: vscode.Disposable[] = []

  static createOrShow(extensionUri: vscode.Uri): void {
    const column = vscode.window.activeTextEditor?.viewColumn

    if (MyWebviewPanel.currentPanel) {
      MyWebviewPanel.currentPanel._panel.reveal(column)
      return
    }

    const panel = vscode.window.createWebviewPanel(
      'monext.webview',
      'Mon Webview',
      column ?? vscode.ViewColumn.One,
      {
        enableScripts: true,
        localResourceRoots: [vscode.Uri.joinPath(extensionUri, 'media')],
        retainContextWhenHidden: true,  // Garde l'état quand l'onglet est caché
      }
    )

    MyWebviewPanel.currentPanel = new MyWebviewPanel(panel, extensionUri)
  }

  private constructor(panel: vscode.WebviewPanel, extensionUri: vscode.Uri) {
    this._panel = panel
    this._update(extensionUri)

    // Nettoyage quand le panel est fermé
    this._panel.onDidDispose(() => this.dispose(), null, this._disposables)

    // Messages entrants depuis le webview
    this._panel.webview.onDidReceiveMessage(
      (message: { command: string; payload: unknown }) => {
        switch (message.command) {
          case 'alert':
            vscode.window.showInformationMessage(String(message.payload))
            break
          case 'getData':
            // Répondre au webview
            void this._panel.webview.postMessage({ command: 'data', payload: { value: 42 } })
            break
        }
      },
      null,
      this._disposables
    )
  }

  // Envoyer un message vers le webview
  sendMessage(command: string, payload: unknown): void {
    void this._panel.webview.postMessage({ command, payload })
  }

  private _update(extensionUri: vscode.Uri): void {
    const nonce = crypto.randomBytes(16).toString('hex')
    const styleUri = this._panel.webview.asWebviewUri(
      vscode.Uri.joinPath(extensionUri, 'media', 'main.css')
    )

    this._panel.webview.html = /* html */ `<!DOCTYPE html>
<html lang="fr">
<head>
  <meta charset="UTF-8" />
  <!-- CSP : nonce obligatoire pour chaque script inline -->
  <meta http-equiv="Content-Security-Policy" content="
    default-src 'none';
    style-src ${this._panel.webview.cspSource};
    script-src 'nonce-${nonce}';
    img-src ${this._panel.webview.cspSource} https:;
  "/>
  <meta name="viewport" content="width=device-width, initial-scale=1.0" />
  <link href="${styleUri}" rel="stylesheet" />
  <title>Mon Webview</title>
</head>
<body>
  <h1>Mon Extension</h1>
  <button id="btn">Envoyer un message</button>
  <script nonce="${nonce}">
    const vscode = acquireVsCodeApi();
    document.getElementById('btn').addEventListener('click', () => {
      vscode.postMessage({ command: 'alert', payload: 'Bonjour depuis le webview !' });
    });
    // Recevoir des messages de l'extension
    window.addEventListener('message', event => {
      const { command, payload } = event.data;
      if (command === 'data') console.log('Reçu:', payload);
    });
  </script>
</body>
</html>`
  }

  dispose(): void {
    MyWebviewPanel.currentPanel = undefined
    this._panel.dispose()
    this._disposables.forEach(d => d.dispose())
    this._disposables = []
  }
}
```

---

## 5. Language Server Protocol (LSP)

```typescript
// Utiliser vscode-languageclient pour les features riches
// npm install --save vscode-languageclient

import {
  LanguageClient,
  LanguageClientOptions,
  ServerOptions,
  TransportKind,
} from 'vscode-languageclient/node'
import * as path from 'path'

let client: LanguageClient

export async function startLanguageServer(context: vscode.ExtensionContext): Promise<void> {
  const serverModule = context.asAbsolutePath(path.join('dist', 'server.js'))

  const serverOptions: ServerOptions = {
    run: { module: serverModule, transport: TransportKind.ipc },
    debug: {
      module: serverModule,
      transport: TransportKind.ipc,
      options: { execArgv: ['--nolazy', '--inspect=6009'] },
    },
  }

  const clientOptions: LanguageClientOptions = {
    documentSelector: [{ scheme: 'file', language: 'myLanguage' }],
    synchronize: {
      fileEvents: vscode.workspace.createFileSystemWatcher('**/.myconfigrc'),
    },
  }

  client = new LanguageClient('myLanguageServer', 'My Language Server', serverOptions, clientOptions)
  await client.start()
  context.subscriptions.push({ dispose: () => client.stop() })
}

// Providers inline (sans LSP — pour cas simples)
const completionProvider = vscode.languages.registerCompletionItemProvider(
  { language: 'myLanguage', scheme: 'file' },
  {
    provideCompletionItems(document, position) {
      const linePrefix = document.lineAt(position).text.slice(0, position.character)
      if (!linePrefix.endsWith('keyword.')) return undefined

      return [
        new vscode.CompletionItem('property1', vscode.CompletionItemKind.Property),
        Object.assign(new vscode.CompletionItem('method1', vscode.CompletionItemKind.Method), {
          documentation: new vscode.MarkdownString('Description de method1'),
          insertText: new vscode.SnippetString('method1(${1:param})'),
        }),
      ]
    },
  },
  '.'  // Trigger character
)
context.subscriptions.push(completionProvider)
```

---

## 6. Diagnostics & CodeActions

```typescript
// Diagnostics — signaler des erreurs/warnings dans le code
const diagnosticCollection = vscode.languages.createDiagnosticCollection('monext')
context.subscriptions.push(diagnosticCollection)

function validateDocument(document: vscode.TextDocument): void {
  if (document.languageId !== 'myLanguage') return

  const diagnostics: vscode.Diagnostic[] = []
  const text = document.getText()
  const pattern = /\bDEPRECATED\b/g

  let match: RegExpExecArray | null
  while ((match = pattern.exec(text)) !== null) {
    const startPos = document.positionAt(match.index)
    const endPos = document.positionAt(match.index + match[0].length)
    const range = new vscode.Range(startPos, endPos)

    diagnostics.push(
      Object.assign(
        new vscode.Diagnostic(range, 'Mot-clé déprécié', vscode.DiagnosticSeverity.Warning),
        { source: 'monext', code: 'deprecated-keyword' }
      )
    )
  }

  diagnosticCollection.set(document.uri, diagnostics)
}

// CodeAction — proposer des corrections
const codeActionProvider = vscode.languages.registerCodeActionsProvider(
  { language: 'myLanguage' },
  {
    provideCodeActions(document, range, context) {
      const relevantDiagnostics = context.diagnostics.filter(d => d.code === 'deprecated-keyword')
      if (!relevantDiagnostics.length) return []

      return relevantDiagnostics.map(diag => {
        const action = new vscode.CodeAction('Remplacer par le nouveau mot-clé', vscode.CodeActionKind.QuickFix)
        action.edit = new vscode.WorkspaceEdit()
        action.edit.replace(document.uri, diag.range, 'NOUVEAU_MOT_CLE')
        action.diagnostics = [diag]
        action.isPreferred = true
        return action
      })
    },
  }
)
context.subscriptions.push(codeActionProvider)
```

---

## 7. Configuration — getConfiguration, onDidChangeConfiguration

```typescript
// Lire la configuration
interface MyExtConfig {
  apiKey: string
  maxItems: number
  enabled: boolean
}

function getConfig(): MyExtConfig {
  const config = vscode.workspace.getConfiguration('monext')
  return {
    apiKey:   config.get<string>('apiKey', ''),
    maxItems: config.get<number>('maxItems', 50),
    enabled:  config.get<boolean>('enabled', true),
  }
}

// Réagir aux changements
const configWatcher = vscode.workspace.onDidChangeConfiguration(event => {
  if (event.affectsConfiguration('monext')) {
    const newConfig = getConfig()
    // Recharger les composants qui dépendent de la config
    treeProvider.refresh()
  }
})
context.subscriptions.push(configWatcher)

// package.json contributes.configuration
// "properties": {
//   "monext.apiKey": { "type": "string", "markdownDescription": "...", "scope": "machine-overridable" },
//   "monext.maxItems": { "type": "number", "default": 50, "minimum": 1, "maximum": 500 },
//   "monext.enabled": { "type": "boolean", "default": true }
// }
```

---

## 8. ExtensionContext — State, Secrets, Storage

```typescript
// État persistant (key-value, sérialisé JSON)
// globalState : partagé entre workspaces (settings utilisateur)
// workspaceState : spécifique au workspace courant
const lastSync = context.globalState.get<number>('lastSync', 0)
await context.globalState.update('lastSync', Date.now())

// Secrets (chiffré, ne jamais utiliser globalState pour des tokens)
const token = await context.secrets.get('auth.token')
if (!token) {
  const inputToken = await vscode.window.showInputBox({
    prompt: 'Entrez votre token API',
    password: true,
    ignoreFocusOut: true,
  })
  if (inputToken) await context.secrets.store('auth.token', inputToken)
}

// Réagir aux changements de secrets (ex: rotation de token)
const secretWatcher = context.secrets.onDidChange(event => {
  if (event.key === 'auth.token') void reinitializeClient()
})
context.subscriptions.push(secretWatcher)

// Stockage de fichiers (pour données volumineuses)
const dataPath = vscode.Uri.joinPath(context.globalStorageUri, 'cache.json')
await vscode.workspace.fs.writeFile(dataPath, Buffer.from(JSON.stringify(data)))

// Ressources bundlées avec l'extension
const iconUri = vscode.Uri.joinPath(context.extensionUri, 'images', 'icon.png')
```

---

## 9. Chat Participant (Copilot Chat API)

```typescript
// package.json contributes
// "chatParticipants": [{
//   "id": "monext.assistant",
//   "name": "monext",
//   "description": "Assistant pour mon domaine",
//   "isSticky": true
// }]

import * as vscode from 'vscode'

export function registerChatParticipant(context: vscode.ExtensionContext): void {
  const handler: vscode.ChatRequestHandler = async (
    request: vscode.ChatRequest,
    chatContext: vscode.ChatContext,
    stream: vscode.ChatResponseStream,
    token: vscode.CancellationToken
  ): Promise<vscode.ChatResult> => {

    // Accéder aux modèles de langage disponibles
    const models = await vscode.lm.selectChatModels({
      vendor: 'copilot',
      family: 'gpt-4o',
    })

    if (!models.length) {
      stream.markdown('Aucun modèle de langage disponible.')
      return {}
    }

    const [model] = models

    // Construire le contexte (historique de conversation)
    const messages = [
      vscode.LanguageModelChatMessage.User(
        `Tu es un assistant spécialisé dans mon domaine. Réponds en français.`
      ),
      ...chatContext.history.flatMap(h =>
        'prompt' in h
          ? [vscode.LanguageModelChatMessage.User(h.prompt)]
          : [vscode.LanguageModelChatMessage.Assistant(
              h.response.map(r => ('value' in r ? r.value : '')).join('')
            )]
      ),
      vscode.LanguageModelChatMessage.User(request.prompt),
    ]

    // Streamer la réponse
    stream.progress('Analyse en cours...')
    const response = await model.sendRequest(messages, {}, token)

    for await (const chunk of response.text) {
      if (token.isCancellationRequested) break
      stream.markdown(chunk)
    }

    // Suggestions de follow-up
    return {
      metadata: { command: request.command },
    }
  }

  const participant = vscode.chat.createChatParticipant('monext.assistant', handler)
  participant.iconPath = vscode.Uri.joinPath(context.extensionUri, 'images', 'icon.png')
  participant.followupProvider = {
    provideFollowups: () => [
      { prompt: 'Explique plus en détail', label: 'Plus de détails' },
      { prompt: 'Donne un exemple concret', label: 'Exemple' },
    ],
  }

  context.subscriptions.push(participant)
}
```

---

## 10. Bundling esbuild + Tests @vscode/test-cli

```javascript
// esbuild.js
const esbuild = require('esbuild')

const isProduction = process.argv.includes('--production')
const isWatch = process.argv.includes('--watch')

const buildOptions = {
  entryPoints: ['src/extension.ts'],
  bundle: true,
  outfile: 'dist/extension.js',
  external: ['vscode'],          // vscode est fourni par l'hôte Extension
  format: 'cjs',                 // CommonJS obligatoire pour extension host
  platform: 'node',
  target: 'node20',
  sourcemap: !isProduction,
  minify: isProduction,
  logLevel: 'info',
}

if (isWatch) {
  esbuild.context(buildOptions).then(ctx => {
    void ctx.watch()
    console.log('Watching...')
  })
} else {
  esbuild.build(buildOptions).catch(() => process.exit(1))
}
```

```
# .vscodeignore — fichiers exclus du .vsix
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
!node_modules/**  (si pas bundlé)
```

```typescript
// test/runTest.ts — runner @vscode/test-cli
import { run } from '@vscode/test-cli'
run({
  files: 'test/suite/**/*.test.js',  // Après compilation TypeScript
  workspaceFolder: '.',
}).catch(err => {
  console.error('Tests failed:', err)
  process.exit(1)
})

// test/suite/extension.test.ts — Mocha + vscode
import * as assert from 'assert'
import * as vscode from 'vscode'

suite('Extension Test Suite', () => {
  suiteSetup(async () => {
    // Activer l'extension avant les tests
    const ext = vscode.extensions.getExtension('publisher.mon-extension')
    if (ext && !ext.isActive) await ext.activate()
  })

  test('Extension should be active', () => {
    const ext = vscode.extensions.getExtension('publisher.mon-extension')
    assert.ok(ext?.isActive, 'Extension should be active')
  })

  test('Command should be registered', async () => {
    const commands = await vscode.commands.getCommands(true)
    assert.ok(commands.includes('monext.helloWorld'), 'Command should be registered')
  })

  test('Configuration should have default values', () => {
    const config = vscode.workspace.getConfiguration('monext')
    assert.strictEqual(config.get<boolean>('enabled'), true)
    assert.strictEqual(config.get<number>('maxItems'), 50)
  })
})
```

```json
// package.json scripts
{
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

---

## 11. Publishing — vsce & Open VSX

```bash
# Installer vsce (outil officiel Microsoft)
npm install -g @vscode/vsce

# Vérifier ce qui sera inclus dans le package
vsce ls

# Créer le package .vsix (sans publier)
vsce package

# Publier sur le Marketplace VS Code
# (nécessite un PAT Azure DevOps avec scope Marketplace > Manage)
vsce publish --pat $VSCE_PAT
vsce publish patch        # Incrémente la version patch automatiquement
vsce publish minor        # Incrémente la version minor
vsce publish 1.2.0        # Version explicite

# Publier sur Open VSX (pour VSCodium, Theia, Gitpod)
npm install -g ovsx
ovsx publish *.vsix --pat $OVSX_PAT

# Vérifier la publication
# https://marketplace.visualstudio.com/manage/publishers/[publisher-id]
```

```
# Checklist pré-publication
□ publisher défini dans package.json
□ repository.url défini (obligatoire Marketplace)
□ icon.png 128×128px présente
□ .vscodeignore à jour (exclut src/, test/, *.map)
□ CHANGELOG.md mis à jour (format Keep a Changelog)
□ Version bumped dans package.json
□ Extension testée dans VSCode Stable (pas seulement Insiders)
□ README avec captures d'écran ou GIF
□ vsce ls vérifié (pas de node_modules si bundlé)
```

---

## Anti-patterns à éviter

```typescript
// ❌ Activation event * (charge au démarrage de VSCode — ralentit tout)
"activationEvents": ["*"]

// ✅ Activation spécifique
"activationEvents": ["onCommand:monext.hello", "workspaceContains:**/.monconfig"]

// ❌ Oublier de push dans context.subscriptions (fuite mémoire)
vscode.commands.registerCommand('monext.cmd', () => { ... })  // ❌ pas de push

// ✅ Toujours push
context.subscriptions.push(vscode.commands.registerCommand('monext.cmd', () => { ... }))

// ❌ Chemin hardcodé
const iconPath = '/Users/me/.vscode/extensions/monext/images/icon.png'  // ❌

// ✅ Utiliser extensionUri
const iconPath = vscode.Uri.joinPath(context.extensionUri, 'images', 'icon.png')

// ❌ CSP désactivée dans le Webview (injection XSS possible)
webviewPanel.webview.html = `<script>eval('${userInput}')</script>`  // ❌ dangereux

// ✅ Toujours nonce + CSP stricte
const nonce = crypto.randomBytes(16).toString('hex')
// <meta http-equiv="Content-Security-Policy" content="script-src 'nonce-${nonce}';">

// ❌ Stocker des tokens dans globalState (non chiffré)
context.globalState.update('token', secretToken)  // ❌ stocké en clair

// ✅ Utiliser SecretStorage
context.secrets.store('auth.token', secretToken)

// ❌ workspaceFolders sans vérification de nullité
const rootPath = vscode.workspace.workspaceFolders[0].uri.fsPath  // crash si pas de workspace

// ✅ Toujours vérifier
const folders = vscode.workspace.workspaceFolders
if (!folders?.length) {
  vscode.window.showWarningMessage('Ouvrez un dossier dans VSCode')
  return
}
const rootPath = folders[0].uri.fsPath
```
