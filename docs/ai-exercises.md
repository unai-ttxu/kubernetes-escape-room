# AI Exercises — Bad vs Good Prompting on the Real Scenarios (Instructor Guide)

> **Instructor material.** This file contains the answers to every level. Do not share it with attendees before they finish the level.
> Attendee-facing tips are in [`ai-prompts-cheatsheet.md`](ai-prompts-cheatsheet.md). Sources are in [`ai-research-notes.md`](ai-research-notes.md).
> (It is kept out of `hints.md` on purpose: `./scripts/escape-room.sh hint` prints everything under a hint heading.)

## How to run an exercise

1. Attendee starts the level and reads the incident.
2. **Round A, "bad":** they use the *bad* prompt below with a free copilot and note what comes back.
3. **Round B, "good":** they collect the listed evidence, use the *good* prompt and compare.
4. Debrief with the rubric (cheatsheet section 5).

**Important caveat:** model answers vary by model, version and day. This guide lists the **classes of answers** to expect, not exact text. The "observed in the cluster" blocks are real output from a fresh kind cluster, captured while writing this guide (2026-10-23). The "expected AI behavior" lines were **not** measured against any model; they are patterns consistent with the failure modes in [research notes E6/E7](ai-research-notes.md), and should be confirmed in a dry run (see the M5 session log).

---

## Level 01: The Ghost Image (`escape-level-01`)

**Lesson:** raw evidence beats paraphrase, and AI must not invent facts it cannot check.

**Observed in the cluster (broken state):** pod `ImagePullBackOff`; Events include
`Failed to pull image "nginx:1.27.99-alpine": ... docker.io/library/nginx:1.27.99-alpine: not found`.

### 🚫 Bad prompt
```text
My pod is stuck in ImagePullBackOff, what do I do?
```
Expected AI behavior (unmeasured): generic checklist: registry credentials, `imagePullSecrets`, network, rate limits, typo. Mostly plausible, none tied to *this* pod. Attendee may chase pull secrets that have nothing to do with it.

### ✅ Good prompt
```text
Namespace escape-level-01, Deployment payment-gateway. Expected: Running.
Actual: ImagePullBackOff. Full `kubectl describe pod` output below.
Quote the line that tells you WHY the pull failed, then say whether it is an auth,
network or "image does not exist" problem and what evidence separates them.
Do not invent a replacement tag: tell me how I can check which tags exist.
<PASTE describe pod>
```
Expected: the `not found` line is cited; auth/network ruled out; the tag is the suspect.

### Facilitator notes
- **Expected finding:** the tag in the Deployment (`1.27.99`) does not exist; the Events say `not found`, which rules out credentials and network.
- **Watch for:** the AI proposing a "valid" tag with confidence. Ask: "How do we know that tag exists?" (check the registry page or pull a known tag; do not trust memory).
- **Discussion:** what changed between "paraphrase" and "verbatim"? Which line carried the answer?
- **Rubric hint:** *time to useful evidence* is usually the big difference here.

---

## Level 02: The Crashing Config (`escape-level-02`)

**Lesson:** compound faults. The first visible error is not the only one. Ask for all causes and re-check after each fix.

**Observed in the cluster (broken state):**
```text
$ kubectl logs -n escape-level-02 -l app=order-processor
order-processor: loading configuration
ERROR config: KeyError: 'DATABASE_URL'
order-processor: warming 32MiB order cache

$ kubectl describe pod ... (excerpt)
    State:          Terminated
      Reason:       OOMKilled
      Exit Code:    137
```
Also: `kubectl logs --previous` can fail with *unable to retrieve container logs* between restarts, so a missing `--previous` is not always the attendee's fault.

The log shows the config error but stops at the cache line: the container is killed by the memory limit before it logs anything else. The kill itself appears only in `describe`.

### 🚫 Bad prompt (logs only, one cause)
```text
My pod keeps crashing. Logs:
<PASTE logs>
How do I fix it?
```
Expected AI behavior (unmeasured): confident diagnosis of the missing variable and a patch for it. An attendee applying only that fix will see the pod *still* crashing, because the second cause (the kernel kill) was never in the evidence.

### ✅ Good prompt
```text
Namespace escape-level-02, Deployment order-processor, config from ConfigMap order-config.
Expected: Running/Ready, /healthz on 8080 returns 200.
Symptom: restarts, status flips between Error/CrashLoopBackOff/OOMKilled.
Logs, `describe pod` (Last State + Limits) and the ConfigMap are below.
1. List EVERY distinct root cause you can see. For each, quote the evidence line.
2. Say which evidence you would still want to rule something out.
3. Give the order to fix them in and how I confirm each fix separately.
<PASTE logs, describe, configmap>
```
Expected: two causes, each with its own evidence (the name mismatch; exit code 137 against the memory limit).

### Facilitator notes
- **Expected findings:** (1) the ConfigMap key does not match the name the app reads; (2) memory limit lower than the app's working set, shown by `OOMKilled` / exit 137.
- **Teaching moment:** after fixing only one cause, have the attendee paste the *new* output back into the same chat and ask "what now?" This is stage 4 of the workflow.
- **Unsafe-advice check:** if the AI proposes a very large memory limit "to be safe", ask for the smallest value justified by evidence. Reject guesses with no evidence behind the number.
- **Watch for:** `--previous` logs being empty. Point attendees to `describe` for the Last State.

---

## Level 03: The Silent Wall (`escape-level-03`)

**Lesson:** topology problems need several related resources at once, and AI will happily "fix" an isolation problem by removing the isolation. This is the D4 pedagogical warning.

**Observed in the cluster (broken state):**
```text
$ kubectl get pods -n escape-level-03 --show-labels
backend-...    1/1  Running  ... app=backend,component=backend,level=03,...
frontend-...   1/1  Running  ... app=frontend,component=frontend,level=03,...,role=web-frontend

$ kubectl get endpoints -n escape-level-03
backend-service    10.10.0.167:8080
frontend-service   10.10.0.239:80

$ frontend access log / error log (excerpt)
[error] ... upstream timed out (110: Operation timed out) while connecting to upstream ...
"GET /api/data HTTP/1.1" 504

$ DNS from a pod in the namespace
10.11.142.156  backend-service.escape-level-03.svc.cluster.local     # resolves fine
```
**Heads-up (scenario text vs. reality):** `incident.md` and `hints.md` say `502`. In the initial broken state we observed **504** (the NetworkPolicy drops the packets, so the proxy times out). A `502`-style refusal appears only after the policy is fixed and the port mismatch remains. Both are the same faults; just do not tell attendees "you must see a 502". Logged in the session log for the owner to decide whether the scenario text should change.

### 🚫 Bad prompt
```text
Here is my Service YAML. The frontend can't reach the backend, but the pods are Running. Why?
<PASTE only backend-service YAML>
```
Expected AI behavior (unmeasured): a plausible but incomplete answer: port mismatch is *possible* (if it can be inferred), or DNS, or "check your readiness probe". It cannot see the NetworkPolicy or the labels. Likely unsafe suggestions: "temporarily delete the NetworkPolicy", "use `hostNetwork`", "run as privileged". Attendees applying them would remove the isolation the policy exists for, and the first symptom might even clear while leaving the second fault unfixed.

### ✅ Good prompt
```text
Namespace escape-level-03. Frontend Service (80) proxies /api/* to backend-service.
Pods are Running 1/1 but GET /api/data fails.
Evidence below: endpoints, backend-service YAML, backend Deployment (ports), the
NetworkPolicy YAML and `get pods --show-labels`.
1. Which fields disagree with each other? Quote both sides of each disagreement.
2. Give the MINIMAL change for each that keeps the intent "only the frontend may call
   the backend". Do not delete or loosen the policy.
3. How do I verify each fix separately before applying the other?
<PASTE evidence>
```
Expected: two disagreements (Service target port vs container port; policy `from` selector vs frontend labels), minimal patches, a separate check for each.

### Facilitator notes
- **Expected findings:** (1) Service `targetPort` does not match the port the backend container listens on (visible in endpoints and the backend Deployment); (2) the NetworkPolicy `from` selector does not match the frontend pod's `role` label.
- **Why order matters:** with the policy fixed first, the symptom changes (timeout → refusal). That change is *evidence*; have attendees paste it back to the AI.
- **Unsafe-advice check:** score 0 on "unsafe advice" if an attendee applied a policy deletion, `hostNetwork` or privileged workaround.
- **Teaching point:** Kubernetes docs list the NetworkPolicy and the selector/`targetPort` checks as separate steps ([research notes E2/E3](ai-research-notes.md)), and an AI answers only about what it sees.

---

## Challenge the AI's hypothesis (required exercise, run on Level 03)

**Goal:** practice stage 3 and 4: test a confident hypothesis with a read-only check, then correct the AI with new evidence.

### Setup (5 min)
Attendee starts `level-03` and gives the AI **only** this (incomplete) evidence:
```text
kubectl get pods -n escape-level-03     → all Running 1/1
Frontend returns an error for GET /api/data
Frontend error log: "upstream timed out (110: Operation timed out) while connecting to upstream"
```

### Step 1: capture the hypothesis
Ask: *"What is the most likely root cause? Give your confidence and one command that would disprove it."*
**Expected first hypotheses (classes, unmeasured):** backend not ready / crashing; DNS problem; app-level timeout; resource limits; "backend is overloaded".

### Step 2: try to disprove it with read-only checks
| Hypothesis | Read-only check | Observed result in the broken cluster |
|---|---|---|
| Backend is down | `kubectl get pods -n escape-level-03` | Backend `Running 1/1`: **contradicts** |
| DNS is broken | resolve `backend-service` from a pod in the namespace | Resolves to the Service IP: **contradicts** |
| Service has no backends | `kubectl get endpoints -n escape-level-03` | An endpoint exists, on a port worth comparing with the container: **partial lead** |
| Something drops traffic | `kubectl get netpol -n escape-level-03 -o yaml` and `--show-labels` | A policy selects the backend; the allowed `from` label is worth comparing with the frontend's labels: **strong lead** |

### Step 3: correct the AI
Attendee pastes the contradicting outputs and asks:
```text
Your hypothesis was <X>. Here is evidence that contradicts it: <PASTE>.
Which parts of your earlier answer are now wrong? What do you conclude now, with what confidence,
and which resources do you still need to see?
```

### Facilitator notes and expected findings
- **A good revision:** the AI abandons "backend down" and "DNS", says what is *still unknown*, and asks for the NetworkPolicy and the Service/Deployment port details. A poor revision: it doubles down, or reshuffles the same guess.
- **Discuss:** Who noticed the contradiction, the human or the AI? How many turns did it take? What would an agent with read-only tools have fetched on its own?
- **Score** with the rubric. Typical good result: correctness 2, missed signals 1–2 (depends on first prompt), unsafe advice 2.
- **Variation:** inject the fake instruction line from cheatsheet guardrail 5 into a pasted log and see whether the copilot follows it. **Do this only with the attendee's own pasted text, never in cluster data.** It demonstrates untrusted input without risk.

---

## Optional: tool-connected run (MCP or CLI agent), Level 02

Only if the instructor has the tooling set up **outside** the harness. Do not assume attendees have it.

1. Export `KUBECONFIG=kind/.kube/config` before starting the assistant.
2. Set it to read-only (MCP read-only setting, or CLI agent permissions per the cheatsheet section 4).
3. Prompt: *"Investigate the pod in escape-level-02 using read-only tools only. Report every root cause with the command output that proves it. Do not change anything."*
4. Compare with the copy-paste route: how many calls did it make, did it read `describe`, did it find both causes, did it try anything it should not have?

**Status: not run for this repo.** Mark results here after a dry run, and update the M5 session log.
