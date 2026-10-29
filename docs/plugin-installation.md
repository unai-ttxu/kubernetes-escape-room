# Using the `k8s-troubleshooting` plugin

The plugin (`plugins/k8s-troubleshooting/`) bundles a read-only troubleshooting skill and a guarded `kubernetes-mcp-server` config (read-only, Secrets denied). `.claude-plugin/marketplace.json` makes this checkout a local marketplace, so `make plugin-install` installs it from disk (nothing is fetched from GitHub).

For every tool: from the repository root, run `make plugin-install` (Claude Code and Copilot CLI, whichever are installed; `make plugin-uninstall` removes it), export an **absolute** `KUBECONFIG` and the plugin path, then start the agent from a scratch directory **outside** the repository (it would otherwise read `hints.md` and `solution/`). `npx` is required for the MCP server.

```bash
export KUBECONFIG="$(pwd)/kind/.kube/config"
export K8S_PLUGIN="$(pwd)/plugins/k8s-troubleshooting"
mkdir -p ~/escape-room-agent && cd ~/escape-room-agent
```

## Claude Code

`make plugin-install` runs `claude plugin install k8s-troubleshooting --marketplace "$(pwd)"` (user scope). To load it for one session without installing:

```bash
claude --plugin-dir "$K8S_PLUGIN"
```

Restart Claude Code, then check `/plugin` (plugin loaded) and `/mcp` (`k8s-readonly` connected). Check the plugin files before a session with `claude plugin validate "$K8S_PLUGIN"`.

## GitHub Copilot CLI

Copilot CLI reads the same `.claude-plugin/marketplace.json`, `skills/` and legacy `.mcp.json`. `make plugin-install` runs:

```bash
copilot plugin marketplace add "$(pwd)"
copilot plugin install k8s-troubleshooting@escape-room-marketplace
```

(Direct installs from a local path work but print a deprecation warning, so the marketplace form is used.) Restart Copilot afterwards: a running session does not pick up new plugins.

> **Not verified:** the Copilot docs describe `${PLUGIN_ROOT}` expansion only for Agent Plugins 1.0 `mcp.json`, not for the legacy `.mcp.json` this plugin uses (`${CLAUDE_PLUGIN_ROOT}`). If `k8s-readonly` fails to start, use the manual MCP setup under opencode below.

Docs: [Finding and installing plugins](https://docs.github.com/en/copilot/how-tos/copilot-cli/customize-copilot/plugins-finding-installing), [CLI plugin reference](https://docs.github.com/en/copilot/reference/copilot-cli-reference/cli-plugin-reference).

## opencode

opencode has no plugin system for this format, so install the two pieces by hand.

**1. Skill.** opencode discovers `SKILL.md` under `~/.config/opencode/skills/<name>/` (the directory name must match the skill `name`):

```bash
mkdir -p ~/.config/opencode/skills
cp -R "$K8S_PLUGIN/skills/k8s-troubleshooting" ~/.config/opencode/skills/
```

**2. MCP server.** Add this to `opencode.json` in your scratch directory (or `~/.config/opencode/opencode.json`). `${CLAUDE_PLUGIN_ROOT}` does not exist here, so use the absolute path of the plugin config (replace `<repo-root>` with the output of `pwd` in the repository root):

```json
{
  "$schema": "https://opencode.ai/config.json",
  "mcp": {
    "k8s-readonly": {
      "type": "local",
      "command": [
        "npx", "-y", "kubernetes-mcp-server@0.0.69",
        "--config", "<repo-root>/plugins/k8s-troubleshooting/config/mcp-config.toml"
      ],
      "enabled": true
    }
  }
}
```

The server inherits `KUBECONFIG` from the shell that launches opencode. To also restrict shell commands, see the `opencode.json` permissions in [`pre-workshop-checklist.md`](pre-workshop-checklist.md).

Docs: [Agent skills](https://opencode.ai/docs/skills/), [MCP servers](https://opencode.ai/docs/mcp-servers/), [Config](https://opencode.ai/docs/config/).
