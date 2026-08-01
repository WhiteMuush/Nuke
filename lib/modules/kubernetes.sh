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
    k8s_available || { press_enter_to_continue; return 1; }

    printf '\n%bKubernetes scope%b\n' "${BRIGHT_MAGENTA}" "${RESET}"
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
    k8s_available || { press_enter_to_continue; return 1; }

    printf '\n%bKubernetes status%b\n' "${BRIGHT_MAGENTA}" "${RESET}"
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

    if nuke_level_requires_confirm "${level}"; then
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

# ---------------------------------------------------------------------------
# Menu.
# ---------------------------------------------------------------------------
k8s_run_pod_kill() {
    local level
    level="$(nuke_pick_level)" || { log_info "Cancelled."; sleep 1; return 0; }
    k8s_pod_kill "${level}"
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
            1) k8s_set_scope ;;
            2) k8s_status ;;
            3) k8s_run_pod_kill ;;
            0) return ;;
            *)
                printf '\n%bInvalid choice!%b\n' "${BRIGHT_RED}" "${RESET}"
                sleep 1
                ;;
        esac
    done
}
