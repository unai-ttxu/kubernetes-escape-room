# Session 04 — Milestone 4: Level 03: "The Silent Wall"

> **Date:** 2026-10-20  
> **Status:** 🔍 In review  
> **Branch:** `feat/M4`

---

## 🎯 Objectives

Implement Level 03 ("The Silent Wall") under `scenarios/level-03-silent-wall/` in namespace `escape-level-03`. All pods report `Running 1/1`, but the frontend returns `502` for `GET /api/data` because of two compound faults: a Service port mismatch and a NetworkPolicy label mismatch.

---

## 📦 Deliverables Created

| File | Purpose |
|---|---|
| `broken/frontend-deployment.yaml` | Frontend nginx (`nginx:1.27-alpine`), pod labelled `role: web-frontend` |
| `broken/frontend-config.yaml` | ConfigMap with the frontend proxy (`/api/*` → `backend-service`) |
| `broken/frontend-service.yaml` | ClusterIP `frontend-service` port 80 → 80 |
| `broken/backend-deployment.yaml` | Backend nginx listening on **9000** |
| `broken/backend-config.yaml` | ConfigMap serving `{"data":"backend-connected"}` at `/api/data` on port 9000 |
| `broken/backend-service.yaml` | ClusterIP `backend-service` port 80 with **`targetPort: 8080`** (bug 1) |
| `broken/networkpolicy.yaml` | `backend-firewall` allowing ingress only from `role: api-consumer` (bug 2) |
| `solution/*` | Same set with `targetPort: 9000` and the NetworkPolicy selecting `role: web-frontend` |
| `incident.md` | Pager alert `#INC-8103` describing symptoms only |
| `hints.md` | 3 tiered hints (concept → `get ep` / `get netpol` investigation → AI prompt recipe) |
| `verify.sh` | Rollout check for both Deployments, then a detached in-cluster probe of `/api/data` through the frontend that checks HTTP 200 **and** the backend payload (chmod 750) |

---

## 💡 Key Design Decisions

1. **End-to-end verification:** the probe goes through `frontend-service`, so it only passes when the frontend → backend hop works. A bare HTTP 200 is not enough: the body must contain `"data":"backend-connected"`, read from the probe pod's logs (no shell pipeline needed in the `curlimages/curl` probe).
2. **Frontend proxy uses a runtime resolver:** `proxy_pass` goes through a variable and `resolver kube-dns...`, so nginx does not fail at startup if the backend Service DNS record is not yet visible.
3. **Nginx-only workloads:** both tiers use pinned `nginx:1.27-alpine` with the configuration mounted from a ConfigMap, so no custom image has to be built or loaded into kind.
4. **Fix location for bug 2:** the NetworkPolicy is corrected to select `role: web-frontend` (the frontend's real label) rather than relabelling the frontend, so the policy still expresses the intended "only the frontend may call the backend" rule.
5. **Hint discipline:** Hints 1–2 name the places to look (Service port vs. container port, policy `from` selector vs. pod labels) without giving the corrected values. Hint 3 is the SRE copilot prompt.

---

## ⚠️ Known Gaps (not verified)

- **NetworkPolicy enforcement needs a policy-enforcing CNI.** kind's default CNI (kindnet) does **not** enforce NetworkPolicy, so the cluster now uses `networking.disableDefaultCNI: true` and `setup` installs a pinned Cilium 1.20.2 (`kind/cni/cilium.yaml`). See `plan.md` Amendment 3 (flagged for review). Not yet run on a cluster.
- **kubectl context safety (fixed in this change):** the harness previously ran `kubectl` against the *current* context. On the machine used for this session that was a remote EKS cluster, so `start level-03` could have applied the broken manifests there. `setup` now writes a repo-local kubeconfig, `kind/.kube/config`, with `kind export kubeconfig` (re-run on every `setup`, so certificates stay in sync). The harness exports `KUBECONFIG` to it and each `verify.sh` pins it too, so no `kubectl` call uses the current context. kind still updates `~/.kube/config` as usual. The file is gitignored and removed by `cleanup`.

---

## ✅ Verification & Smoke Test Lifecycle

> Nothing has been run against a cluster yet. Docker Desktop was not running and `shellcheck` is not installed on the agent machine, so the items below stay unticked (AGENTS.md rules 17–18).

Checks that **were** run locally:

- `bash -n scenarios/level-03-silent-wall/verify.sh`: syntax OK.
- All 14 level-03 manifests parse as YAML (`ruby -ryaml`); each container has `requests` and `limits`; every object sets `namespace: escape-level-03` and `level: "03"`.
- `kubectl apply --dry-run` was **not** usable: the current kubectl context points at a remote cluster and failed on credentials. No resources were applied anywhere.
- `scripts/escape-room.sh` and `scenarios/level-01-ghost-image/verify.sh` modes were corrected from `755` to `750` (AGENTS.md rule 7). Git tracks only the owner-executable bit, so this produces no diff.

Checklist for the human reviewer:

- [ ] **Linting**: `shellcheck scenarios/level-03-silent-wall/verify.sh` clean (not run: shellcheck not installed).
- [ ] **Broken state**: `kubectl get ep -n escape-level-03` shows backend endpoints on port `8080`.
- [ ] **Broken state**: `kubectl get netpol -n escape-level-03 -o yaml` shows `role: api-consumer` vs. frontend pod label `role: web-frontend`.
- [ ] **Broken state**: frontend `/api/data` returns `502` while all pods are `Running 1/1`.
- [ ] **Verification failure**: `./scripts/escape-room.sh verify` exits `1` while broken.
- [ ] **Hints**: `./scripts/escape-room.sh hint` renders Hints 1–3.
- [ ] **Solution**: `./scripts/escape-room.sh solve` applies cleanly; both rollouts reach `1/1`.
- [ ] **Verification success**: `./scripts/escape-room.sh verify` exits `0` after `solve`.
- [ ] **Reset**: `./scripts/escape-room.sh reset` restores broken state and clears the completed mark.
- [ ] **Cilium setup**: `./scripts/escape-room.sh setup` creates the cluster, installs Cilium, and reports all nodes `Ready`.
- [ ] **NetworkPolicy enforced**: on the Cilium cluster, fixing only the port still fails verify (both bugs required).

---

## ⏭️ Next Step

Human review of Milestone 4, including a decision on the NetworkPolicy/CNI gap and the kubectl context pinning. After approval, proceed to **Milestone 5**: workshop docs and the AI cheatsheet.
