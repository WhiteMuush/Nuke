#!/usr/bin/env bash
# test/up.sh — Bring up a local kind cluster with the demo workload so Nuke can
# be exercised against a real Kubernetes. Idempotent: safe to re-run.
set -euo pipefail

CLUSTER="${NUKE_TEST_CLUSTER:-nuke-test}"
HERE="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
CTX="kind-${CLUSTER}"

if kind get clusters 2>/dev/null | grep -qx "${CLUSTER}"; then
    echo "Cluster '${CLUSTER}' already exists."
else
    echo "Creating kind cluster '${CLUSTER}'..."
    kind create cluster --name "${CLUSTER}" --config "${HERE}/kind.yaml"
fi

echo "Applying demo workload..."
kubectl --context "${CTX}" apply -f "${HERE}/manifests/demo.yaml"
kubectl --context "${CTX}" -n nuke-demo rollout status deploy/whoami --timeout=180s

cat <<EOF

Ready.
  Context   : ${CTX}
  Namespace : nuke-demo   (3 replicas, PDB minAvailable=2)

Try it:
  ./nuke.sh                 then set scope to namespace nuke-demo, Resilience check
  NUKE_EXPERIMENTS_DIR=test/experiments ./nuke.sh run whoami-pod-kill

Tear down:
  test/down.sh
EOF
