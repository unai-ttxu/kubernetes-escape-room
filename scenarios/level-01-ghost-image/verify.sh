#!/usr/bin/env bash
set -euo pipefail

readonly NAMESPACE="escape-level-01"
readonly APP_LABEL="app=payment-gateway"
readonly SERVICE_URL="http://payment-gateway.${NAMESPACE}.svc.cluster.local:80/"
readonly PROBE_POD="verify-probe-$$"
readonly PROBE_IMAGE="curlimages/curl:8.11.1"

echo "🔍 Verifying Level 01..."

# Step 1: Check the rollout is complete (new pods Ready, old pods gone)
if ! kubectl rollout status deployment/payment-gateway -n "${NAMESPACE}" --timeout=5s > /dev/null 2>&1; then
  echo "❌ Pod is not ready. Run: kubectl get pods -n ${NAMESPACE} -l ${APP_LABEL}"
  exit 1
fi

# Step 2: In-cluster HTTP probe
PROBE_OUT=""
if ! PROBE_OUT=$(kubectl run "${PROBE_POD}" \
  --image="${PROBE_IMAGE}" \
  --restart=Never \
  --rm \
  -i \
  --pod-running-timeout=60s \
  -n "${NAMESPACE}" \
  -- curl -fsS --max-time 5 "${SERVICE_URL}" 2>&1 > /dev/null); then
  if [[ "${PROBE_OUT}" == *"curl: ("* ]]; then
    echo "❌ Endpoint probe failed: service at ${SERVICE_URL} did not return HTTP 200"
  else
    echo "⚠️  Could not run the probe pod (image pull or scheduling issue). Retry in a moment."
  fi
  exit 1
fi

echo "✅ Level 01 complete! You escaped!"
exit 0
