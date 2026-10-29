# Session 10 — `k8s-troubleshooting` AI Plugin

> **Date:** 2026-10-29  
> **Status:** 🔍 In review (human sign-off pending)  
> **Branch:** `feat/marketplace`

---

## 🎯 Objectives

1. Ship one plugin, `k8s-troubleshooting`, with a read-only troubleshooting skill and a guarded MCP config.
2. Load it locally during the workshop (Claude Code, GitHub Copilot CLI, opencode).

## 📦 Deliverables

| File | Change |
|---|---|
| `plugins/k8s-troubleshooting/.claude-plugin/plugin.json` | Plugin manifest (0.1.0) |
| `plugins/k8s-troubleshooting/skills/k8s-troubleshooting/SKILL.md` | Evidence-first, read-only loop distilled from `docs/ai-prompts-cheatsheet.md` |
| `plugins/k8s-troubleshooting/.mcp.json` + `config/mcp-config.toml` | `kubernetes-mcp-server@0.0.69`, read-only, Secrets denied, no hardcoded kubeconfig |
| `docs/plugin-installation.md` | Local load steps and doc links for Claude Code, Copilot CLI, opencode |
| `README.md`, `AGENTS.md` | Trees, plugin section, plugin rules |

## 🧠 Learnings

1. **No kubeconfig in the plugin.** The MCP server inherits the session's `KUBECONFIG`, so the plugin carries no absolute path (rule 6) and works for any cluster. `${CLAUDE_PLUGIN_ROOT}` locates the shipped toml.
2. **No marketplace, on purpose.** The plugin is used locally in the workshop, so a marketplace only added a registration step (and a default-branch dependency). A first iteration shipped one with `make plugin-install`; both were removed. Claude Code loads the directory per session with `--plugin-dir`; Copilot CLI installs from a local path.
3. **Start the agent outside the repo.** `--plugin-dir` points at the repo but the session's working directory must be a scratch directory, otherwise the agent reads `AGENTS.md`, `hints.md` and `solution/`.
4. **Other CLIs diverge.** Copilot CLI reads `skills/` and legacy `.mcp.json`, but its docs describe `${PLUGIN_ROOT}` expansion only for the newer `mcp.json` format, so `${CLAUDE_PLUGIN_ROOT}` there is unverified. opencode needs the skill copied and an `mcp` entry with a `<repo-root>` placeholder.

## ✅ Verification

- `claude plugin validate plugins/k8s-troubleshooting` passes; `make validate` passes.
- Not run (left unchecked): `claude --plugin-dir`, the MCP server connecting to the cluster, the skill triggering, the Copilot CLI and opencode setups.

## Review checklist

- [ ] `claude --plugin-dir` loads the plugin and `/mcp` shows `k8s-readonly` connected
- [ ] Skill triggers on a failing-pod prompt against a running level
- [ ] Copilot CLI local install works (or the `${CLAUDE_PLUGIN_ROOT}` caveat is confirmed)
- [ ] opencode manual setup works after replacing `<repo-root>`
