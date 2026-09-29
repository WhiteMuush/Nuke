#!/usr/bin/env bash
# lib/modules/kubernetes.sh — Kubernetes chaos layer (flagship).
# k8s is the safest place to be brutal: Deployments reschedule killed pods, so
# a full NUKE self-heals. Scope is a namespace (+ optional label selector).

if [[ -n "${NUKE_MODULE_K8S_LOADED:-}" ]]; then
    return 0
fi
NUKE_MODULE_K8S_LOADED=1

# Layer scope state.
NUKE_K8S_NAMESPACE="${NUKE_K8S_NAMESPACE:-}"
NUKE_K8S_LABEL="${NUKE_K8S_LABEL:-}"

# True if kubectl is present and a cluster is reachable.
k8s_available() {
    nuke_have kubectl || { log_error "kubectl not found. Install it or let Nuke set up a kind cluster."; return 1; }
    if ! kubectl version >/dev/null 2>&1 && ! kubectl cluster-info >/dev/null 2>&1; then
        log_error "No reachable cluster. Check your kubeconfig/context."
        return 1
    fi
    return 0
}

k8s_current_context() {
    kubectl config current-context 2>/dev/null || printf 'unknown'
}

# Set the layer scope: namespace (required) and an optional label selector.
# Records it in NUKE_SCOPE so the safety gate recognizes it.
k8s_set_scope() {
    nuke_subview "SET SCOPE"
    k8s_available || { press_enter_to_continue; return 1; }

    log_info "Context: $(k8s_current_context)"

    local ns
    ns="$(prompt_value "Namespace" "${NUKE_K8S_NAMESPACE:-default}")"
    NUKE_K8S_NAMESPACE="${ns}"

    local label
    label="$(prompt_value "Label selector (optional, e.g. app=web)" "${NUKE_K8S_LABEL}")"
    NUKE_K8S_LABEL="${label}"

    NUKE_SCOPE="k8s:$(k8s_current_context)/${NUKE_K8S_NAMESPACE}"
    [[ -n "${NUKE_K8S_LABEL}" ]] && NUKE_SCOPE="${NUKE_SCOPE} (${NUKE_K8S_LABEL})"

    log_success "Scope set: ${NUKE_SCOPE}"
    press_enter_to_continue
}

# kubectl args honoring the current namespace and label selector.
_k8s_selector_args() {
    local -a args=(-n "${NUKE_K8S_NAMESPACE}")
    [[ -n "${NUKE_K8S_LABEL}" ]] && args+=(-l "${NUKE_K8S_LABEL}")
    printf '%s\n' "${args[@]}"
}

# Show cluster + scope status and the pods currently in range.
k8s_status() {
    nuke_subview "STATUS"
    k8s_available || { press_enter_to_continue; return 1; }

    log_info "Context   : $(k8s_current_context)"
    log_info "Namespace : ${NUKE_K8S_NAMESPACE:-<not set>}"
    log_info "Label     : ${NUKE_K8S_LABEL:-<none>}"

    if [[ -z "${NUKE_K8S_NAMESPACE}" ]]; then
        log_warn "No namespace scope set yet."
        press_enter_to_continue
        return 0
    fi

    local -a sel
    mapfile -t sel < <(_k8s_selector_args)
    printf '%b---- pods in scope ----%b\n' "${DIM}" "${RESET}"
    kubectl get pods "${sel[@]}" -o wide 2>&1 | head -40
    press_enter_to_continue
}

# ---------------------------------------------------------------------------
# Fault: pod-kill. Deletes pods in scope; Deployments/StatefulSets reschedule
# them, so this is destructive but self-healing. Blast radius scales with the
# chosen intensity; NUKE! wipes every pod in scope and requires confirmation.
# ---------------------------------------------------------------------------
k8s_pod_kill() {
    local level="$1"
    k8s_available || return 1
    nuke_require_scope || return 1

    local -a sel
    mapfile -t sel < <(_k8s_selector_args)

    local -a pods
    mapfile -t pods < <(kubectl get pods "${sel[@]}" \
        --field-selector=status.phase=Running \
        -o jsonpath='{range .items[*]}{.metadata.name}{"\n"}{end}' 2>/dev/null)

    if [[ ${#pods[@]} -eq 0 ]]; then
        log_warn "No running pods in scope (${NUKE_SCOPE})."
        return 0
    fi

    # How many to kill: blast radius from the intensity profile, capped to the
    # number of pods actually in scope. Selection is randomized.
    local blast total want
    blast="$(nuke_level_profile "${level}" blast)"
    total=${#pods[@]}
    want=$(( blast < total ? blast : total ))

    if nuke_level_requires_confirm "${level}" && [[ -z "${NUKE_SKIP_CONFIRM:-}" ]]; then
        nuke_confirm_detonation "kill ALL ${total} pod(s) in ${NUKE_SCOPE}" || return 1
    fi

    local -a victims
    if nuke_have shuf; then
        mapfile -t victims < <(printf '%s\n' "${pods[@]}" | shuf | head -n "${want}")
    else
        mapfile -t victims < <(printf '%s\n' "${pods[@]}" | head -n "${want}")
    fi

    # Delete by explicit name (a selector cannot be combined with names).
    # Higher intensity kills harder (no graceful shutdown).
    local -a kill_args=(delete pod -n "${NUKE_K8S_NAMESPACE}" "${victims[@]}")
    local magnitude
    magnitude="$(nuke_level_profile "${level}" magnitude)"
    if (( magnitude >= 80 )); then
        kill_args+=(--grace-period=0 --force)
    fi

    log_step "pod-kill [$(nuke_level_label "${level}")]: ${want}/${total} pod(s)"
    nuke_run "k8s pod-kill ${level}" -- kubectl "${kill_args[@]}"
    log_info "Deployments will reschedule killed pods automatically."
}

# Steady-state probe: healthy when every Deployment in scope has all its desired
# replicas ready. Zero-config, derived straight from the target: no health URL
# to write, and it holds for any workload. Returns 0 when healthy, 1 otherwise.
k8s_steady_probe() {
    local -a sel
    mapfile -t sel < <(_k8s_selector_args)

    local data
    data="$(kubectl get deploy "${sel[@]}" \
        -o jsonpath='{range .items[*]}{.spec.replicas} {.status.readyReplicas}{"\n"}{end}' \
        2>/dev/null)" || return 1
    # No deployments in scope: nothing to judge, treat as not-healthy so the
    # baseline check aborts with a clear message rather than passing vacuously.
    [[ -z "${data//[$'\n'[:space:]]/}" ]] && return 1

    local desired ready
    while read -r desired ready; do
        [[ -z "${desired}" ]] && continue
        ready="${ready:-0}"
        (( desired > 0 ))     || return 1
        (( ready >= desired )) || return 1
    done <<< "${data}"
    return 0
}

# Run a full resilience check: probe the steady state, kill pods, watch it heal,
# and print a verdict. pod-kill is instantaneous, so the fault duration is 0 and
# the whole window is the recovery budget.
k8s_resilience_check() {
    k8s_available     || { press_enter_to_continue; return 1; }
    nuke_require_scope || { press_enter_to_continue; return 1; }

    local level
    level="$(nuke_pick_level "Intensity for the resilience check")" || return 0
    nuke_subview "RESILIENCE CHECK @ $(nuke_level_label "${level}")"
    nuke_resilience_run k8s_steady_probe k8s_pod_kill "${level}" 0 "k8s pod-kill"

    printf '\n'
    if prompt_yesno "Save this as a reusable experiment (replayable in CI)"; then
        local expname
        expname="$(nuke_session_sanitize "$(prompt_value "Experiment name" "k8s-pod-kill")")"
        [[ -n "${expname}" ]] && nuke_experiment_save "${expname}" kubernetes pod-kill "${level}"
    fi
    press_enter_to_continue
}

# ===========================================================================
# Chaos Mesh — the real k8s fault arsenal (network, stress, io, dns, time).
# Faults are applied as Chaos Mesh CRDs scoped to the current namespace/label.
# Each carries a native `duration` so it auto-recovers, and registers a delete
# in the rollback stack as a second safety net.
# ===========================================================================

# True if Chaos Mesh CRDs are installed in the cluster.
k8s_chaos_mesh_ready() {
    kubectl get crd networkchaos.chaos-mesh.org >/dev/null 2>&1
}

# Install Chaos Mesh via Helm. Uses containerd settings that match kind; on a
# managed cluster the defaults apply. Idempotent-ish (helm upgrade --install).
k8s_setup_chaos_mesh() {
    nuke_subview "SETUP CHAOS MESH"
    k8s_available || { press_enter_to_continue; return 1; }
    if k8s_chaos_mesh_ready; then
        log_success "Chaos Mesh already installed."
        press_enter_to_continue
        return 0
    fi
    if ! nuke_have helm; then
        log_error "helm not found. Install helm or set up Chaos Mesh manually."
        press_enter_to_continue
        return 1
    fi

    log_step "Installing Chaos Mesh via Helm..."
    nuke_run "helm add repo" -- helm repo add chaos-mesh https://charts.chaos-mesh.org
    nuke_run "helm repo update" -- helm repo update chaos-mesh
    kubectl create ns chaos-mesh --dry-run=client -o yaml | kubectl apply -f - >/dev/null 2>&1
    nuke_run "helm install chaos-mesh" -- helm upgrade --install chaos-mesh chaos-mesh/chaos-mesh \
        -n chaos-mesh \
        --set chaosDaemon.runtime=containerd \
        --set chaosDaemon.socketPath=/run/containerd/containerd.sock \
        --set dashboard.create=false \
        --version 2.6.3
    log_info "Give the pods a moment: kubectl get pods -n chaos-mesh"
    press_enter_to_continue
}

# Emit the CRD selector block (2-space indent, under spec).
_k8s_cm_selector() {
    printf '  selector:\n'
    printf '    namespaces:\n'
    printf '      - %s\n' "${NUKE_K8S_NAMESPACE}"
    if [[ -n "${NUKE_K8S_LABEL}" ]]; then
        printf '    labelSelectors:\n'
        printf '      %s: "%s"\n' "${NUKE_K8S_LABEL%%=*}" "${NUKE_K8S_LABEL#*=}"
    fi
}

# Emit the CRD mode block from the intensity blast radius.
_k8s_cm_mode() {
    local blast
    blast="$(nuke_level_profile "$1" blast)"
    if (( blast <= 1 )); then
        printf '  mode: one\n'
    elif (( blast >= 9999 )); then
        printf '  mode: all\n'
    else
        printf '  mode: fixed\n  value: "%d"\n' "${blast}"
    fi
}

# _k8s_cm_run <label> <kind> <level> <spec-fragment>
# Assemble and apply a Chaos Mesh CRD, then register its rollback.
_k8s_cm_run() {
    local label="$1" kind="$2" level="$3" spec="$4"
    k8s_available || return 1
    if ! k8s_chaos_mesh_ready; then
        log_error "Chaos Mesh not installed. Run 'Setup Chaos Mesh' first."
        return 1
    fi
    nuke_require_scope || return 1
    if nuke_level_requires_confirm "${level}" && [[ -z "${NUKE_SKIP_CONFIRM:-}" ]]; then
        nuke_confirm_detonation "${label} on ${NUKE_SCOPE}" || return 1
    fi

    local name dur
    name="nuke-${label//[^a-z0-9]/-}-$(date +%s)"
    dur="$(nuke_level_profile "${level}" duration)s"

    local manifest
    manifest="apiVersion: chaos-mesh.org/v1alpha1
kind: ${kind}
metadata:
  name: ${name}
  namespace: ${NUKE_K8S_NAMESPACE}
spec:
$(_k8s_cm_selector)
$(_k8s_cm_mode "${level}")
  duration: \"${dur}\"
${spec}"

    log_step "Chaos Mesh: ${label} [$(nuke_level_label "${level}")] for ${dur} -> ${name}"
    printf '%s\n' "${manifest}" | nuke_run "cm ${label} ${level}" -- kubectl apply -f -
    nuke_rollback_add "kubectl delete ${kind} ${name} -n ${NUKE_K8S_NAMESPACE} --ignore-not-found >/dev/null 2>&1"
    log_info "Auto-recovers after ${dur}; rollback registered (${kind}/${name})."
}

# --- Network faults --------------------------------------------------------
k8s_cm_net_delay() {
    local level="$1" mag lat jit
    mag="$(nuke_level_profile "${level}" magnitude)"
    lat=$(( mag * 5 )); jit=$(( lat / 4 ))
    _k8s_cm_run "netdelay" NetworkChaos "${level}" \
"  action: delay
  delay:
    latency: \"${lat}ms\"
    jitter: \"${jit}ms\"
    correlation: \"50\""
}

k8s_cm_net_loss() {
    local level="$1" mag
    mag="$(nuke_level_profile "${level}" magnitude)"
    _k8s_cm_run "netloss" NetworkChaos "${level}" \
"  action: loss
  loss:
    loss: \"${mag}\"
    correlation: \"50\""
}

k8s_cm_net_partition() {
    _k8s_cm_run "partition" NetworkChaos "$1" \
"  action: partition
  direction: both"
}

# --- Stress faults ---------------------------------------------------------
k8s_cm_stress_cpu() {
    local level="$1" mag workers
    mag="$(nuke_level_profile "${level}" magnitude)"
    workers=$(( mag / 25 )); (( workers < 1 )) && workers=1
    _k8s_cm_run "stresscpu" StressChaos "${level}" \
"  stressors:
    cpu:
      workers: ${workers}
      load: ${mag}"
}

k8s_cm_stress_mem() {
    local level="$1" mag
    mag="$(nuke_level_profile "${level}" magnitude)"
    _k8s_cm_run "stressmem" StressChaos "${level}" \
"  stressors:
    memory:
      workers: 1
      size: \"${mag}%\""
}

# --- Pod, DNS and time faults ----------------------------------------------
k8s_cm_pod_failure() {
    _k8s_cm_run "podfailure" PodChaos "$1" "  action: pod-failure"
}

k8s_cm_dns() {
    _k8s_cm_run "dns" DNSChaos "$1" \
"  action: error
  patterns:
    - \"*\""
}

k8s_cm_time() {
    local level="$1" mag
    mag="$(nuke_level_profile "${level}" magnitude)"
    _k8s_cm_run "timeskew" TimeChaos "${level}" \
"  timeOffset: \"-${mag}m\""
}

# --- Node drain (kubectl, not Chaos Mesh) ----------------------------------
# Cordons and drains nodes; rollback uncordons them. Recovery is manual (via
# the layer's Recover action) since a drain has no built-in expiry.
k8s_node_drain() {
    local level="$1"
    k8s_available || return 1

    local -a nodes
    mapfile -t nodes < <(kubectl get nodes -o name 2>/dev/null | sed 's#node/##')
    [[ ${#nodes[@]} -eq 0 ]] && { log_warn "No nodes found."; return 0; }

    local blast total want
    blast="$(nuke_level_profile "${level}" blast)"
    total=${#nodes[@]}
    want=$(( blast < total ? blast : total ))

    log_warn "Draining ${want}/${total} node(s). On a single-node cluster this evicts everything."
    if nuke_level_requires_confirm "${level}" && [[ -z "${NUKE_SKIP_CONFIRM:-}" ]]; then
        nuke_confirm_detonation "drain ${want} node(s)" || return 1
    fi

    local -a victims
    mapfile -t victims < <(printf '%s\n' "${nodes[@]}" | head -n "${want}")
    local n
    for n in "${victims[@]}"; do
        nuke_run "cordon ${n}" -- kubectl cordon "${n}"
        nuke_rollback_add "kubectl uncordon ${n} >/dev/null 2>&1"
        nuke_run "drain ${n}" -- kubectl drain "${n}" \
            --ignore-daemonsets --delete-emptydir-data --force --timeout=60s
    done
    log_info "Nodes stay drained until you Recover (rollback) or exit Nuke."
}

# --- All-out NUKE: every vector at once ------------------------------------
k8s_nuke_all() {
    nuke_subview "NUKE k8s"
    k8s_available || return 1
    k8s_chaos_mesh_ready || { log_error "Chaos Mesh not installed. Run 'Setup Chaos Mesh' first."; return 1; }
    nuke_require_scope || return 1
    nuke_confirm_detonation "ALL fault vectors on ${NUKE_SCOPE}" || return 1

    log_warn "Detonating every vector at NUKE intensity..."
    NUKE_SKIP_CONFIRM=1
    k8s_cm_pod_failure  NUKE
    k8s_cm_net_delay    NUKE
    k8s_cm_net_loss     NUKE
    k8s_cm_stress_cpu   NUKE
    k8s_cm_stress_mem   NUKE
    k8s_cm_dns          NUKE
    k8s_cm_time         NUKE
    unset NUKE_SKIP_CONFIRM
    log_success "All vectors launched. They auto-recover; use Recover to stop early."
}

# Stop everything now: run every registered rollback (delete CRDs, uncordon).
k8s_recover() {
    nuke_subview "RECOVER"
    log_step "Recovering: clearing all active chaos..."
    nuke_rollback_run
    press_enter_to_continue
}

# ---------------------------------------------------------------------------
# Menu.
# ---------------------------------------------------------------------------
# Pick an intensity (full sub-view), then run the fault on a clean screen.
_k8s_run_fault() {
    local fn="$1" label="$2" level
    level="$(nuke_pick_level "Intensity for ${label}")" || return 0
    nuke_subview "${label} @ $(nuke_level_label "${level}")"
    "${fn}" "${level}"
    press_enter_to_continue
}

handle_kubernetes_menu() {
    local choice
    while true; do
        clear
        display_banner_with_menu "kubernetes"
        prompt_menu_choice "Kubernetes"
        read -r choice

        case "$choice" in
            1)  k8s_set_scope ;;
            2)  k8s_status ;;
            3)  k8s_setup_chaos_mesh ;;
            14) k8s_resilience_check ;;
            4)  _k8s_run_fault k8s_pod_kill        "Pod-kill" ;;
            5)  _k8s_run_fault k8s_cm_pod_failure  "Pod-failure" ;;
            6)  _k8s_run_fault k8s_cm_net_delay    "Net delay" ;;
            7)  _k8s_run_fault k8s_cm_net_loss     "Net loss" ;;
            8)  _k8s_run_fault k8s_cm_net_partition "Net partition" ;;
            9)  _k8s_run_fault k8s_cm_stress_cpu   "Stress CPU" ;;
            10) _k8s_run_fault k8s_cm_stress_mem   "Stress memory" ;;
            11) _k8s_run_fault k8s_cm_dns          "DNS chaos" ;;
            12) _k8s_run_fault k8s_cm_time         "Time skew" ;;
            13) _k8s_run_fault k8s_node_drain      "Node drain" ;;
            99) k8s_nuke_all; press_enter_to_continue ;;
            r|R) k8s_recover ;;
            0)  return ;;
            *)
                printf '\n%bInvalid choice!%b\n' "${BRIGHT_RED}" "${RESET}"
                sleep 1
                ;;
        esac
    done
}
