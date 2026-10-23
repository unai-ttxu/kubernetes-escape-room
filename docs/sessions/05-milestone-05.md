# Session 05 — Milestone 5: AI-Assisted Troubleshooting Best Practices

> **Date:** 2026-10-23  
> **Status:** 🔍 In review  
> **Branch:** `feat/M5`

---

## 🎯 Objectives

Teach a repeatable, evidence-based way to use AI during an incident, using the three existing scenarios to show **bad vs good practice**. Web copilots are the baseline; MCP servers and CLI agents are optional, read-only by default and scoped to `kind/.kube/config`. Mostly docs. The one harness change is the `ai-assist` command (added after the first review round); no `verify.sh` or manifest changed.

---

## 📦 Deliverables Created

| File | Purpose |
|---|---|
| `docs/ai-prompts-cheatsheet.md` | 5-stage workflow with a prompt per stage, nine bad/good tips tied to levels, six guardrails (incl. a fake prompt-injection example), tool tiers (chat, runbook retrieval, MCP, CLI agents), evaluation rubric |
| `docs/ai-exercises.md` | Instructor guide: bad/good prompts and facilitator notes per level, the required challenge-the-hypothesis exercise (Level 03), optional MCP/CLI-agent run |
| `docs/ai-research-notes.md` | Cited sources with access dates; established vs emerging; unverified items; source conflicts |
| `scenarios/*/ai-assist.md` | One attendee-facing AI tip per level (bad vs good, no fix) |
| `scripts/escape-room.sh` | New `ai-assist` command: prints the current level's `ai-assist.md`; does not touch `HINT_LEVEL`; listed in `start` and usage |
| `README.md`, `AGENTS.md` | Directory trees, command list and harness behaviour updated (rules 8, 16) |
| `docs/sessions/00-milestones.md` | M5 status set to 🔍 In review; deliverables list updated; checklist **not** ticked (rule 17) |
| `docs/design/plan.md` | Amendment 5 (facilitator notes outside `hints.md`) |

---

## 💡 Key Design Decisions

1. **Facilitator notes are not in `hints.md`.** `extract_hint` prints everything under a hint heading, so notes after Hint 3 would reach attendees. They live in `docs/ai-exercises.md` (Amendment 5, flagged for review). This deviates from the milestone's original "scenarios/*/hints.md" bullet.
2. **Attendee docs never contain fixes.** The cheatsheet describes symptoms and evidence only; answers are in the instructor file.
3. **Primary sources over summaries.** A search summary claimed `kubernetes-mcp-server` has `--read-only` CLI flags. The repo's own configuration doc says `read_only` is a TOML key and the CLI takes only bootstrap options, and that `$KUBECONFIG` is not a server option. The docs follow the primary source and tell readers to check the installed version. The same applies to opencode's `shell` vs older `bash` permission key.
4. **Rubric scores evidence, not only the verdict**, following the cited benchmark work (E6, E7).

---

## ✅ Verification & Smoke Test

Checks that **were** run (fresh kind cluster with Cilium, repo-local kubeconfig):

- Level 01 broken: `ImagePullBackOff`; Events show `nginx:1.27.99-alpine ... not found`.
- Level 02 broken: logs show only `KeyError: 'DATABASE_URL'` then the cache line; `describe` shows `OOMKilled` / exit 137; `logs --previous` returned *unable to retrieve container logs* once.
- Level 03 broken: pods `Running 1/1`; endpoints show backend on `8080`; DNS resolves; frontend error log shows `upstream timed out` and a `504`.
- Level 03 with only the NetworkPolicy fixed: the symptom changes from `504` to `502` (`Connection refused`), as the exercise claims.

- `ai-assist`: `shellcheck scripts/escape-room.sh` clean; on levels 01–03 it prints the level tip, leaves `HINT_LEVEL` at 0, and `hint` still shows only Hint 1; with no active level it exits 1 with the usual "No active level" message; listed in `help`. The attendee tips were written to avoid fixes, but need a human spoiler read.

Checks that were **not** run:

- **No LLM was prompted.** All "expected AI behavior" lines are unmeasured classes of answers. A dry run with at least one free copilot is needed before the workshop.
- **MCP server and opencode steps were not installed or run**, so they are flagged untested.
- k8sgpt: its docs page returned only a title; no claims are made about its flags.
- `kubectl-ai`, `kubernetes-mcp-server` and opencode details come from fetched pages, not from running the tools.
- Link check and path check: see the commands in the review checklist below.

### Finding for the repo owner (not changed here)

`incident.md` and `hints.md` for Level 03 say the frontend returns `502`. In the initial broken state the NetworkPolicy drops packets and the frontend returns **504**; `502` appears only after the policy is fixed. The exercise guide says so. Decide whether to update the scenario text (it is outside M5's scope).

### Environment note

The first `setup` found an old `escape-room` kind cluster whose only node had the `node-role.kubernetes.io/control-plane:NoSchedule` taint, so pods (including Hubble) could not schedule. With the owner's approval it was recreated with `cleanup` then `setup`; the fresh cluster worked. Cause of the taint on the old cluster is unknown.

---

## Review checklist for the human reviewer

- [ ] All cited links resolve and dates are accurate (`for u in $(grep -oE 'https://[^) >]+' docs/ai-research-notes.md | sort -u); do curl -s -o /dev/null -L -w '%{http_code} ' "$u"; echo "$u"; done`)
- [ ] Established practices are clearly separated from emerging ideas
- [ ] The challenge-the-hypothesis exercise has facilitator notes and expected findings
- [ ] Guardrails section covers all six rules
- [ ] MCP / opencode steps were tested, or are explicitly flagged as untested (flagged untested)
- [ ] Workflow is coherent with the existing level hints (Concept → Investigation → AI prompt)
- [ ] `./scripts/escape-room.sh ai-assist` on each level: tips are useful and give nothing away
- [ ] Dry-run the "bad" and "good" prompts with at least one free copilot and adjust the expected-behavior lines

---

## ⏭️ Next Step

Human review of Milestone 5. After approval, proceed to **Milestone 6**: pre-workshop checklist and the one-page A4 cheatsheet condensed from `docs/ai-prompts-cheatsheet.md`.
