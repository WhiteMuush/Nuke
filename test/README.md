# Test environment

A throwaway local Kubernetes for exercising Nuke against a real cluster.

## What it is

- A `kind` cluster (one control-plane, one worker), see `kind.yaml`.
- A demo workload in namespace `nuke-demo`: three `nginx` replicas behind a
  Service, with a readiness probe and a PodDisruptionBudget (`minAvailable: 2`),
  see `manifests/demo.yaml`.

The demo is deliberately resilient: killing pods should keep the Service healthy
and recover fast, so a resilience check comes back `RESILIENT`. Drop the PDB or
scale to one replica to watch it turn into a `WEAK SPOT`.

## Requirements

`docker` (running), `kind`, `kubectl`. `helm` too if you want to install Chaos
Mesh for the network / stress faults.

## Use

```bash
test/up.sh          # create the cluster + demo workload (idempotent)

# interactive: set scope to namespace nuke-demo, then Resilience check
./nuke.sh

# headless, the CI path:
NUKE_EXPERIMENTS_DIR=test/experiments ./nuke.sh run whoami-pod-kill
echo "exit: $?"    # 0 resilient, 1 weak spot

test/down.sh        # delete the cluster
```

The cluster name defaults to `nuke-test`; override with `NUKE_TEST_CLUSTER`.
