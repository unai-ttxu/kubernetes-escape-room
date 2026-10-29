# Session 10 — `k8s-troubleshooting` AI Plugin

> **Date:** 2026-10-29  
> **Status:** 🔍 In review (human sign-off pending)  
> **Branch:** `feat/marketplace`

---

## 🎯 Objectives

1. Ship one plugin, `k8s-troubleshooting`, with a read-only troubleshooting skill and a guarded MCP config.
2. Install it locally with `make plugin-install` during the workshop (Claude Code, GitHub Copilot CLI; opencode by hand).

## 📦 Deliverables

| File | Change |
|---|---|
| `.claude-plugin/marketplace.json` | Local-only marketplace `escape-room-marketplace`, the vehicle for installs |
| `Makefile` | `plugin-install` / `plugin-uninstall` for Claude Code and Copilot CLI |
| `plugins/k8s-troubleshooting/.claude-plugin/plugin.json` | Plugin manifest (0.1.0) |
| `plugins/k8s-troubleshooting/skills/k8s-troubleshooting/SKILL.md` | Evidence-first, read-only loop distilled from `docs/ai-prompts-cheatsheet.md` |
| `plugins/k8s-troubleshooting/.mcp.json` + `config/mcp-config.toml` | `kubernetes-mcp-server@0.0.69`, read-only, Secrets denied, no hardcoded kubeconfig |
| `docs/plugin-installation.md` | Local load steps and doc links for Claude Code, Copilot CLI, opencode |
| `README.md`, `AGENTS.md` | Trees, plugin section, plugin rules |

## 🧠 Learnings

1. **No kubeconfig in the plugin.** The MCP server inherits the session's `KUBECONFIG`, so the plugin carries no absolute path (rule 6) and works for any cluster. `${CLAUDE_PLUGIN_ROOT}` locates the shipped toml.
2. **Persistent install needs a marketplace.** `claude plugin install` only installs from a marketplace, and `--plugin-dir` is per session. A first iteration dropped the marketplace; it came back as a local-path marketplace so `make plugin-install` works. Copilot CLI warns that direct local-path installs are deprecated, so it uses the same marketplace.
3. **Start the agent outside the repo.** The installed plugin is read live from the checkout, but the session's working directory must be a scratch directory, otherwise the agent reads `AGENTS.md`, `hints.md` and `solution/`.
4. **Other CLIs diverge.** Copilot CLI reads `skills/` and legacy `.mcp.json`, but its docs describe `${PLUGIN_ROOT}` expansion only for the newer `mcp.json` format, so `${CLAUDE_PLUGIN_ROOT}` there is unverified. opencode needs the skill copied and an `mcp` entry with a `<repo-root>` placeholder.

## ✅ Verification

- `claude plugin validate plugins/k8s-troubleshooting` passes; `make validate` passes.
- `make plugin-install` ran: Claude Code and Copilot CLI both list the plugin as installed/enabled.
- Not run (left unchecked): the MCP server connecting to the cluster, the skill triggering in a session, the opencode setup.

## Review checklist

- [ ] After `make plugin-install` and a restart, `/mcp` shows `k8s-readonly` connected
- [ ] Skill triggers on a failing-pod prompt against a running level
- [ ] Copilot CLI starts `k8s-readonly` (or the `${CLAUDE_PLUGIN_ROOT}` caveat is confirmed)
- [ ] opencode manual setup works after replacing `<repo-root>`
