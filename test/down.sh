#!/usr/bin/env bash
# test/down.sh — Delete the local kind test cluster.
set -euo pipefail
CLUSTER="${NUKE_TEST_CLUSTER:-nuke-test}"
if kind get clusters 2>/dev/null | grep -qx "${CLUSTER}"; then
    kind delete cluster --name "${CLUSTER}"
else
    echo "No cluster '${CLUSTER}' to delete."
fi
