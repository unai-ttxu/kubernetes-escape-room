# AI Research Notes — LLM-Assisted Kubernetes Troubleshooting

> Sources behind [`ai-prompts-cheatsheet.md`](ai-prompts-cheatsheet.md) and [`ai-exercises.md`](ai-exercises.md).
> Every link below was fetched on **2026-10-23** (access date). Where a page shows no publication date it is marked "n/d".
> Claims are paraphrased from the fetched page, not from memory. Re-check version-sensitive items (MCP server config, opencode keys) before the event.

---

## Established practices

These are stable, documented by primary sources, and the workshop teaches them as the baseline.

| # | Practice | Source | Date | What it supports |
|---|---|---|---|---|
| E1 | Troubleshoot from evidence: `describe` first (state + events), then logs (`--previous` for restarted containers), then compare the stored manifest with what you applied | [Kubernetes: Debug Pods](https://kubernetes.io/docs/tasks/debug/debug-application/debug-pods/) | n/d | The evidence an AI needs for Level 01 and 02 is the same evidence a human collects. Hint 2 of each level follows this order. |
| E2 | Debug a Service in order: Service exists → NetworkPolicy ingress → DNS → ClusterIP → selector and `targetPort` → EndpointSlices → Pod IPs | [Kubernetes: Debug Services](https://kubernetes.io/docs/tasks/debug/debug-application/debug-service/) | n/d | Level 03: the checklist an AI must be given the *inputs* for (Service, endpoints, NetworkPolicy, pod labels). |
| E3 | NetworkPolicy is additive and allow-only; a pod is isolated for a direction only once a policy selects it; policies have no effect without a plugin that implements them | [Kubernetes: Network Policies](https://kubernetes.io/docs/concepts/services-networking/network-policies/) | n/d | Level 03 and why `kind/cni/cilium.yaml` exists. Also why "delete the policy" is an unsafe AI suggestion. |
| E4 | Prompt injection is LLM01 in the OWASP list; *indirect* injection comes from external content (files, web pages). Mitigations: least privilege, human approval for high-risk actions, separate and label untrusted content, filter input/output | [OWASP GenAI: LLM01:2025 Prompt Injection](https://genai.owasp.org/llmrisk/llm01-prompt-injection/) | 2025 (copyright line; no publication date shown) | Guardrail: logs, events and ConfigMap values are untrusted input to the model. |
| E5 | MCP hosts must get explicit user consent before invoking any tool; tools represent arbitrary code execution; tool annotations are untrusted unless from a trusted server; the protocol itself cannot enforce this | [MCP specification 2025-11-25, Security and Trust & Safety](https://modelcontextprotocol.io/specification/2025-11-25/index) | spec version 2025-11-25 (other versions listed on the site; the quoted section is present in the version fetched) | Guardrail: review every tool call; read-only by default. |
| E6 | Final-answer accuracy overstates diagnosis quality: best agents reached 0.76 / 0.68 joint RCA accuracy but only 0.38 / 0.15 evidence closure (conclusions backed by evidence) | [Cloud-OpsBench, arXiv 2603.00468](https://arxiv.org/abs/2603.00468) | submitted 2026-02-28 (v1); v2 2026-08-22 | Why the rubric scores *evidence*, not only "got the right answer". Benchmark numbers are on microservice demo systems, not on this workshop. |
| E7 | Commonest agent failures across five models: hallucinated data interpretation and incomplete exploration; prompt engineering alone did not remove them | [Why Do AI Agents Systematically Fail at Cloud Root Cause Analysis?, arXiv 2602.09937](https://arxiv.org/abs/2602.09937) | submitted 2026-02-10; v2 2026-03-04 | Level 02 (incomplete exploration: finds one of two causes) and the "ask for all causes" tip. Also the reason humans verify. |

## Emerging practices

Useful, widely discussed, but tool- and version-dependent. Presented as optional.

| # | Practice | Source | Date | Notes |
|---|---|---|---|---|
| M1 | Kubernetes MCP server, read-only | [containers/kubernetes-mcp-server](https://github.com/containers/kubernetes-mcp-server) and its [configuration doc](https://github.com/containers/kubernetes-mcp-server/blob/main/docs/configuration.md) (Apache-2.0) | n/d (main branch) | Per the configuration doc, `read_only`, `disable_destructive`, `kubeconfig` and `[[denied_resources]]` are **TOML config keys; the CLI only takes `--config`, `--config-dir`, `--version`**. It also states `$KUBECONFIG` is not a server option, though client-go reads it when `kubeconfig` is empty. See "Conflicts" below. Read-only mode limits the *server's* actions; it does not reduce what the kubeconfig credentials could do. |
| M2 | CLI agent permission modes (opencode) | [opencode: Permissions](https://opencode.ai/docs/permissions/) | n/d | Values `allow` / `ask` / `deny`; most permissions default to `allow`; last matching pattern wins (catch-all `*` first); `--auto` approves requests that would ask but explicit `deny` still applies. The shell permission key on the current page is `shell`. Older docs/mirrors used `bash`, so check the installed version. |
| M3 | CLI agent confirmation prompts (kubectl-ai) | [GoogleCloudPlatform/kubectl-ai](https://github.com/GoogleCloudPlatform/kubectl-ai) (Apache-2.0, "not an officially supported Google product") | n/d | Confirmation for resource-modifying commands is on by default (`skipPermissions` default `false`). No read-only mode is documented. Its HTTP MCP endpoint is unauthenticated by default, so do not expose it. |
| M4 | Analyzer + LLM explanation (k8sgpt) | [k8sgpt.ai docs](https://k8sgpt.ai/docs/getting-started/overview) | n/d | The fetched page returned only its title, so no claims about flags (`--explain`, `--anonymize`) are made here. Mentioned only as an example of "analyzers first, LLM second". **Unverified.** |
| M5 | Retrieval over runbooks | No primary source gathered | — | **Unverified.** The cheatsheet treats it as a design pattern (runbook text supplied as context), not as a measured result. Stale runbooks are a stated risk, not a cited finding. |

## Unverified / flagged

- **Typical LLM failure outputs in the exercises** (wrong first hypothesis, tag hallucinations, `hostNetwork`, deleting the NetworkPolicy, missing the OOM cause) are *expected classes*, consistent with E7, but model outputs vary. They were **not** measured for this workshop; see the test notes in [`docs/sessions/05-milestone-05.md`](sessions/05-milestone-05.md).
- **MCP and opencode steps in the cheatsheet** were not run end to end unless the session log says so.
- **k8sgpt** claims: see M4.
- A search summary claimed `kubernetes-mcp-server` has `--read-only` / `--disable-destructive` CLI flags. The primary documentation fetched above says otherwise (see below).

## Conflicts between sources

| Topic | Source A | Source B | Decision |
|---|---|---|---|
| How to enable read-only in `kubernetes-mcp-server` | Secondary search summaries (mirrors, older READMEs): `--read-only` CLI flag | Current repo README and `docs/configuration.md`: TOML key `read_only = true`; CLI limited to bootstrap flags | Docs show the TOML key, with a note to check `kubernetes-mcp-server --help` for the installed version. |
| opencode shell permission key | Older docs/mirrors: `bash` | Current docs: `shell` | Docs show `shell` and say to check the installed version. |

## How to re-verify before the event

```bash
# every URL above should return 200 (OWASP may return 403 to curl due to Cloudflare; verify in browser)
for u in $(grep -oE 'https://[a-zA-Z0-9][^) >]+' docs/ai-research-notes.md | sort -u); do
  printf '%s %s\n' "$(curl -s -o /dev/null -L -w '%{http_code}' "$u")" "$u"
done
```
