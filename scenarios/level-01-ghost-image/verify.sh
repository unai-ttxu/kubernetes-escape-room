#!/usr/bin/env bash
set -euo pipefail

readonly NAMESPACE="escape-level-01"
readonly APP_LABEL="app=payment-gateway"
readonly SERVICE_URL="http://payment-gateway.${NAMESPACE}.svc.cluster.local:80/"
readonly PROBE_POD="verify-probe-$$"

# shellcheck disable=SC2329
cleanup() {
  kubectl delete pod "${PROBE_POD}" -n "${NAMESPACE}" --ignore-not-found=true --wait=false > /dev/null 2>&1 || true
}
trap cleanup EXIT

echo "🔍 Verifying Level 01..."

# Step 1: Check pod readiness
READY=$(kubectl get pods -n "${NAMESPACE}" -l "${APP_LABEL}" \
  -o jsonpath='{.items[0].status.containerStatuses[0].ready}' 2>/dev/null || echo "false")

if [[ "${READY}" != "true" ]]; then
  echo "❌ Pod is not ready. Run: kubectl get pods -n ${NAMESPACE}"
  exit 1
fi

# Step 2: In-cluster HTTP probe
if ! kubectl run "${PROBE_POD}" \
  --image=curlimages/curl:latest \
  --restart=Never \
  --rm \
  -i \
  -n "${NAMESPACE}" \
  -- curl -fsS --max-time 5 "${SERVICE_URL}" > /dev/null 2>&1; then
  echo "❌ Endpoint probe failed: service at ${SERVICE_URL} did not return HTTP 200"
  exit 1
fi

echo "✅ Level 01 complete! You escaped!"
exit 0
