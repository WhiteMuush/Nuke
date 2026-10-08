#!/usr/bin/env bats
# Behavior of the Chaos Mesh manifest builder (offline, no cluster).

setup() {
    load helper
    _nuke_load
    NUKE_K8S_NAMESPACE="demo-ns"
    NUKE_K8S_LABEL="app=web"
    NUKE_SCOPE="k8s:test/demo-ns"
    NUKE_OUTPUT_DIR="${BATS_TEST_TMPDIR}/out"
    # Make the apply path echo the manifest instead of hitting a cluster.
    k8s_available() { return 0; }
    k8s_chaos_mesh_ready() { return 0; }
    nuke_run() { shift; [[ "${1:-}" == "--" ]] && shift; "$@"; }
    kubectl() { cat; }
}

@test "mode maps blast radius: one / fixed N / all" {
    [[ "$(_k8s_cm_mode POKE)" == *"mode: one"* ]]
    [[ "$(_k8s_cm_mode NUKE)" == *"mode: all"* ]]
    run _k8s_cm_mode STRESS
    [[ "$output" == *"mode: fixed"* ]]
    [[ "$output" == *'value: "2"'* ]]
}

@test "selector includes namespace and split label" {
    run _k8s_cm_selector
    [[ "$output" == *"namespaces:"* ]]
    [[ "$output" == *"- demo-ns"* ]]
    [[ "$output" == *"labelSelectors:"* ]]
    [[ "$output" == *'app: "web"'* ]]
}

@test "generated NetworkChaos manifest is well-formed YAML indentation" {
    run k8s_cm_net_delay HAVOC
    [[ "$output" == *"kind: NetworkChaos"* ]]
    [[ "$output" == *"action: delay"* ]]
    # selector, mode and duration must each be on their own line (regression:
    # command-substitution once concatenated them).
    [[ "$output" == *$'app: "web"\n'* ]]
    [[ "$output" == *$'  mode: fixed'* ]]
    [[ "$output" == *$'  duration: "60s"'* ]]
}

@test "manifest parses as YAML when a parser is available" {
    if ! command -v python3 >/dev/null; then skip "python3 not available"; fi
    python3 -c "import yaml" 2>/dev/null || skip "pyyaml not available"
    run k8s_cm_stress_cpu STRESS
    printf '%s\n' "$output" | python3 -c 'import sys,yaml; yaml.safe_load(sys.stdin)'
}

@test "NUKE level manifest uses mode all" {
    # NUKE is the only level that demands a typed detonation code. Bypass it the
    # way the headless path does, otherwise the builder reads EOF at the prompt
    # and returns before emitting the manifest.
    NUKE_SKIP_CONFIRM=1
    run k8s_cm_pod_failure NUKE
    [[ "$output" == *"kind: PodChaos"* ]]
    [[ "$output" == *"mode: all"* ]]
}
