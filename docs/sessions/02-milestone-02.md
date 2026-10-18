# Session 02 — Milestone 2: Level 01: "The Ghost Image"

> **Date:** 2026-10-18  
> **Status:** ✅ Completed  
> **Branch:** `feat/M2`  

---

## 🎯 Objectives

Implement Level 01 ("The Ghost Image") under `scenarios/level-01-ghost-image/` to serve as the initial warm-up scenario. Attendees diagnose an `ImagePullBackOff` failure on a critical `payment-gateway` deployment in the `escape-level-01` namespace, using kubectl diagnostics, tiered hints, and AI copilots.

---

## 📦 Deliverables Created

| File | Purpose |
|---|---|
| [`scenarios/level-01-ghost-image/broken/deployment.yaml`](../../scenarios/level-01-ghost-image/broken/deployment.yaml) | Deployment manifest specifying non-existent tag `nginx:1.27.99-alpine` |
| [`scenarios/level-01-ghost-image/broken/service.yaml`](../../scenarios/level-01-ghost-image/broken/service.yaml) | ClusterIP Service routing port 80 to backend pods |
| [`scenarios/level-01-ghost-image/solution/deployment.yaml`](../../scenarios/level-01-ghost-image/solution/deployment.yaml) | Reference fix Deployment with valid `nginx:alpine` image |
| [`scenarios/level-01-ghost-image/solution/service.yaml`](../../scenarios/level-01-ghost-image/solution/service.yaml) | Reference Service matching the deployment |
| [`scenarios/level-01-ghost-image/incident.md`](../../scenarios/level-01-ghost-image/incident.md) | Realistic PagerDuty alert (`#INC-8021`) reporting 0 healthy endpoints |
| [`scenarios/level-01-ghost-image/hints.md`](../../scenarios/level-01-ghost-image/hints.md) | 3-tier progressive hints + AI copilot SRE prompt recipe |
| [`scenarios/level-01-ghost-image/verify.sh`](../../scenarios/level-01-ghost-image/verify.sh) | In-cluster verification probe testing pod readiness and HTTP 200 response (chmod 750) |

---

## 💡 Key Design Decisions & Iterations

1. **Deterministic & Quiet In-Cluster Probing**:
   - `verify.sh` first checks pod readiness via `jsonpath='{.items[0].status.containerStatuses[0].ready}'`.
   - Executes an in-cluster ephemeral probe (`curlimages/curl:latest`) against `http://payment-gateway.escape-level-01.svc.cluster.local:80/`.
   - Output and stderr redirected cleanly with probe cleanup trap (`trap cleanup EXIT`) to prevent lingering probe pods and suppress terminal noise during automated checks.
   - Idempotent and strictly exits `0` on success, `1` on failure.

2. **Strict Convention Adherence**:
   - Explicit `namespace: escape-level-01` set on all manifests.
   - Workload metadata includes required `app: payment-gateway`, `component: backend`, `level: "01"` labels and resource requests/limits.
   - Script permissions set to `chmod 750` (`-rwxr-x---`).

3. **Progressive AI Pedagogy**:
   - Hint 1 provides the conceptual mechanism (container runtime image pull).
   - Hint 2 provides exact `kubectl describe pod` and events triage commands.
   - Hint 3 provides a reusable SRE Copilot Prompt Pattern (Context + Symptom + kubectl output + Goal) for free AI assistants.

---

## ✅ Verification & Smoke Test Lifecycle

- [x] **Linting**: `shellcheck scenarios/level-01-ghost-image/verify.sh scripts/escape-room.sh` passed with 0 errors/warnings.
- [x] **Broken State**: `./scripts/escape-room.sh start level-01` injected broken manifests; pods reliably entered `ImagePullBackOff`.
- [x] **Verification Failure**: `./scripts/escape-room.sh verify` exited with code `1` while broken.
- [x] **Hint Parsing**: `./scripts/escape-room.sh hint` properly parsed and rendered Hints 1, 2, and 3 sequentially, warning on 4th invocation.
- [x] **Solution Rollout**: `./scripts/escape-room.sh solve` applied reference fix; deployment rolled out cleanly to `Running 1/1`.
- [x] **Verification Success**: `./scripts/escape-room.sh verify` passed with code `0` and rendered the celebration banner.
- [x] **Reset Idempotency**: `./scripts/escape-room.sh reset` restored broken state; subsequent verify failed as expected.

---

## ⏭️ Next Step

Proceed to **Milestone 3**: Level 02 — "The Crashing Config" (`scenarios/level-02-crashing-config/`).
