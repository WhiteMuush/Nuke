#!/usr/bin/env bash
# lib/modules/docker.sh — Docker / container chaos layer.
# Scope is a container name or filter. Faults will be driven by pumba (pause,
# kill, netem) plus docker's own controls. Only the menu and safety scaffold
# ship today; each fault is a stub that states what it will do.

if [[ -n "${NUKE_MODULE_DOCKER_LOADED:-}" ]]; then
    return 0
fi
NUKE_MODULE_DOCKER_LOADED=1

# Container name or filter this layer targets (empty = not set).
NUKE_DOCKER_SCOPE="${NUKE_DOCKER_SCOPE:-}"

# True if docker is present and its daemon answers.
docker_available() {
    nuke_have docker || { log_error "docker not found. Install Docker Engine first."; return 1; }
    if ! docker info >/dev/null 2>&1; then
        log_error "Docker daemon not reachable. Is it running / do you have access?"
        return 1
    fi
    return 0
}

# Set the layer scope to a container name (or name filter) and record it in
# NUKE_SCOPE so the safety gate recognises it.
docker_set_scope() {
    nuke_subview "SET SCOPE"
    docker_available || { press_enter_to_continue; return 1; }

    printf '   %bTarget a single container by name, or a name substring.%b\n\n' "${DIM}" "${RESET}"
    local target
    target="$(prompt_value "Container name or filter" "${NUKE_DOCKER_SCOPE}")"
    if [[ -z "${target}" ]]; then
        log_error "Scope cannot be empty."
        press_enter_to_continue
        return 1
    fi

    NUKE_DOCKER_SCOPE="${target}"
    NUKE_SCOPE="docker:${NUKE_DOCKER_SCOPE}"
    nuke_session_save
    log_success "Scope set: ${NUKE_SCOPE}"
    press_enter_to_continue
}

# Show the containers currently matching the scope.
docker_status() {
    nuke_subview "STATUS"
    docker_available || { press_enter_to_continue; return 1; }

    log_info "Scope : ${NUKE_SCOPE:-<not set>}"
    if [[ -z "${NUKE_DOCKER_SCOPE}" ]]; then
        log_warn "No scope set yet."
        press_enter_to_continue
        return 0
    fi
    printf '%b---- containers in scope ----%b\n' "${DIM}" "${RESET}"
    docker ps --filter "name=${NUKE_DOCKER_SCOPE}" \
        --format 'table {{.Names}}\t{{.Status}}\t{{.Image}}' 2>&1 | head -40
    press_enter_to_continue
}

# Pick an intensity, then run the fault stub for it.
_docker_run_fault() {
    local label="$1" tool="$2" effect="$3" level
    docker_available || { press_enter_to_continue; return 1; }
    nuke_require_scope || { press_enter_to_continue; return 1; }
    level="$(nuke_pick_level "Intensity for ${label}")" || return 0
    nuke_fault_stub "${label}" "${tool}" "${effect}" "${level}"
}

handle_docker_menu() {
    local choice
    while true; do
        clear
        display_banner_with_menu "docker"
        prompt_menu_choice "Docker"
        read -r choice

        case "$choice" in
            1)  docker_set_scope ;;
            2)  docker_status ;;
            3)  _docker_run_fault "Pause"     "pumba pause"        "Freeze the container's processes for the fault window." ;;
            4)  _docker_run_fault "Stop"      "docker stop"        "Graceful stop; restart policy decides recovery." ;;
            5)  _docker_run_fault "Kill"      "docker kill"        "Hard SIGKILL, no graceful shutdown." ;;
            6)  _docker_run_fault "Net delay" "pumba netem delay"  "Add latency + jitter on the container's interface." ;;
            7)  _docker_run_fault "Net loss"  "pumba netem loss"   "Drop a share of the container's packets." ;;
            8)  _docker_run_fault "Stress"    "pumba stress"       "Burn CPU / memory inside the container." ;;
            99) _docker_run_fault "NUKE docker" "pumba (all)"      "Every container vector at once, full force." ;;
            0)  return ;;
            *)
                printf '\n%bInvalid choice!%b\n' "${BRIGHT_RED}" "${RESET}"
                sleep 1
                ;;
        esac
    done
}
