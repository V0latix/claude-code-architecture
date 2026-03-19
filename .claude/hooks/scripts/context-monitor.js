#!/usr/bin/env node
/**
 * Context Monitor Hook — Inspired by gsd-build/get-shit-done
 *
 * Monitors token usage and injects warnings when context is running low.
 * Triggers: PostToolUse (any tool)
 *
 * Install: add to .claude/settings.json PostToolUse hooks
 * Anti-spam: only warns once per threshold crossing, resets on new session.
 */

const fs = require("fs");
const path = require("path");
const os = require("os");

// State file to prevent spam (persists across tool calls within a session)
const STATE_FILE = path.join(os.tmpdir(), "claude-context-monitor-state.json");

const THRESHOLDS = {
  WARNING: 0.35, // 35% remaining → gentle warning
  CRITICAL: 0.25, // 25% remaining → urgent warning
};

const MIN_CALLS_BETWEEN_WARNS = 5; // anti-spam: at least 5 tool calls between warnings

function loadState() {
  try {
    if (fs.existsSync(STATE_FILE)) {
      const raw = fs.readFileSync(STATE_FILE, "utf8");
      return JSON.parse(raw);
    }
  } catch {
    // ignore parse errors
  }
  return {
    warned_warning: false,
    warned_critical: false,
    calls_since_last_warn: 0,
  };
}

function saveState(state) {
  try {
    fs.writeFileSync(STATE_FILE, JSON.stringify(state), "utf8");
  } catch {
    // ignore write errors
  }
}

function main() {
  // Read hook input from stdin
  let input = "";
  try {
    input = fs.readFileSync("/dev/stdin", "utf8");
  } catch {
    process.exit(0);
  }

  let hookData;
  try {
    hookData = JSON.parse(input);
  } catch {
    process.exit(0);
  }

  // Extract token usage from hook data
  // Claude Code provides usage info in the hook payload
  const usage = hookData?.usage || hookData?.tool_result?.usage || null;
  if (!usage) {
    process.exit(0);
  }

  const inputTokens = usage.input_tokens || 0;
  const outputTokens = usage.output_tokens || 0;
  const cacheTokens = usage.cache_read_input_tokens || 0;
  const contextLimit = hookData?.context_window || 200000; // default 200k

  const usedTokens = inputTokens + outputTokens + cacheTokens;
  const remaining = 1 - usedTokens / contextLimit;

  if (remaining > THRESHOLDS.WARNING) {
    // No warning needed
    process.exit(0);
  }

  // Load anti-spam state
  const state = loadState();
  state.calls_since_last_warn = (state.calls_since_last_warn || 0) + 1;

  // Check thresholds
  let message = null;

  if (remaining <= THRESHOLDS.CRITICAL && !state.warned_critical) {
    if (state.calls_since_last_warn >= MIN_CALLS_BETWEEN_WARNS) {
      const pct = Math.round(remaining * 100);
      message = `🚨 CONTEXT CRITICAL — ${pct}% de contexte restant. Lance /tools/continue MAINTENANT pour sauvegarder l'état de la session avant que le contexte se réinitialise.`;
      state.warned_critical = true;
      state.calls_since_last_warn = 0;
    }
  } else if (remaining <= THRESHOLDS.WARNING && !state.warned_warning) {
    if (state.calls_since_last_warn >= MIN_CALLS_BETWEEN_WARNS) {
      const pct = Math.round(remaining * 100);
      message = `⚠️  CONTEXT WARNING — ${pct}% de contexte restant. Pense à lancer /tools/continue pour sauvegarder l'état si tu travailles sur une tâche longue.`;
      state.warned_warning = true;
      state.calls_since_last_warn = 0;
    }
  }

  saveState(state);

  if (message) {
    // Output to stdout — Claude Code will show this as a system message
    const response = {
      type: "warning",
      message: message,
    };
    process.stdout.write(JSON.stringify(response) + "\n");
  }

  process.exit(0);
}

main();
