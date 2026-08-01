#!/usr/bin/env bash
# lib/safety.sh — Guardrails for destructive experiments.
# A rollback registry that auto-runs on interrupt/exit, a scope gate, a hard
# duration cap, and the typed confirmation required before an all-out NUKE.
# Chaos must always be able to heal itself; these helpers make that the default.

if [[ -n "${NUKE_SAFETY_LOADED:-}" ]]; then
    return 0
fi
NUKE_SAFETY_LOADED=1

# Scope of the current experiment (namespace / container filter / host).
# Empty means "not set" and blocks any destructive action.
NUKE_SCOPE="${NUKE_SCOPE:-}"

# LIFO stack of undo commands. Each entry is a string eval'd on rollback.
declare -a NUKE_ROLLBACK_STACK=()

# ---------------------------------------------------------------------------
# Rollback registry.
# ---------------------------------------------------------------------------

# Arm the auto-rollback trap. Any registered undo runs on INT/TERM so chaos
# (tc rules, iptables, paused containers) never outlives the toolkit.
nuke_arm_rollback() {
    trap 'nuke_rollback_run' INT TERM
}

nuke_rollback_reset() {
    NUKE_ROLLBACK_STACK=()
}

# nuke_rollback_add <undo command string>
# Register an undo action; runs later in reverse (LIFO) order.
nuke_rollback_add() {
    NUKE_ROLLBACK_STACK+=( "$*" )
}

# Run every registered undo, most recent first, then clear the stack.
nuke_rollback_run() {
    local n=${#NUKE_ROLLBACK_STACK[@]}
    (( n == 0 )) && return 0
    log_step "Rolling back ${n} chaos action(s)..."
    local i undo
    for (( i = n - 1; i >= 0; i-- )); do
        undo="${NUKE_ROLLBACK_STACK[i]}"
        log_info "undo: ${undo}"
        eval "${undo}" || log_warn "rollback step failed: ${undo}"
    done
    nuke_rollback_reset
    log_success "Rollback complete."
}

# ---------------------------------------------------------------------------
# Scope gate.
# ---------------------------------------------------------------------------

# Refuse to proceed unless a scope is set. Every destructive action calls this.
nuke_require_scope() {
    if [[ -z "${NUKE_SCOPE}" ]]; then
        log_error "No scope set. Define a scope (namespace / container / host filter) before running chaos."
        return 1
    fi
    return 0
}

# ---------------------------------------------------------------------------
# Duration cap.
# ---------------------------------------------------------------------------

# nuke_capped <seconds> [--] <command...>
# Run a command with a hard time limit so even a maxed-out run self-terminates.
nuke_capped() {
    local secs="$1"; shift
    [[ "${1:-}" == "--" ]] && shift

    if command -v timeout >/dev/null 2>&1; then
        timeout --signal=TERM "${secs}" "$@"
        return $?
    fi

    # Fallback when coreutils timeout is unavailable.
    "$@" &
    local pid=$!
    ( sleep "${secs}"; kill -TERM "${pid}" 2>/dev/null ) &
    local watcher=$!
    wait "${pid}" 2>/dev/null
    local rc=$?
    kill "${watcher}" 2>/dev/null
    return "${rc}"
}

# ---------------------------------------------------------------------------
# Detonation confirmation (level NUKE!).
# ---------------------------------------------------------------------------

# Require an explicit typed confirmation before an all-out detonation.
# Refuses unless a scope is set. Returns 0 only if the user types NUKE.
nuke_confirm_detonation() {
    local what="${1:-maximum destruction}"
    nuke_require_scope || return 1

    printf '\n%b%s ☢  DETONATION WARNING  ☢ %b\n' "${BOLD}" "${BRIGHT_RED}" "${RESET}"
    printf '%bScope:%b  %s\n' "${DIM}" "${RESET}" "${NUKE_SCOPE}"
    printf '%bAction:%b %s\n' "${DIM}" "${RESET}" "${what}"
    printf '%bAll fault vectors, full force. Only proceed on infra you own or are cleared to test.%b\n' \
        "${YELLOW}" "${RESET}"

    local answer
    read -rp "Type NUKE to confirm (anything else aborts): " answer
    if [[ "${answer}" == "NUKE" ]]; then
        log_warn "Detonation confirmed."
        return 0
    fi
    log_info "Aborted. No chaos launched."
    return 1
}
