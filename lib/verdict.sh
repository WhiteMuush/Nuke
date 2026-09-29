#!/usr/bin/env bash
# lib/verdict.sh — Turn a fault into a verdict.
# A resilience check probes a steady state, injects a fault, keeps probing
# through recovery, then decides: did the system hold and heal, or not? This is
# what lifts Nuke from "it breaks things" to "it tells you if you survived".
# The engine is layer-agnostic: callers pass a probe function and a fault
# function, so k8s, docker, network and host can all reuse it.

if [[ -n "${NUKE_VERDICT_LOADED:-}" ]]; then
    return 0
fi
NUKE_VERDICT_LOADED=1

# Tunables. Defaulted so a resilience check needs zero configuration; a caller
# or a saved experiment may override them.
NUKE_PROBE_INTERVAL="${NUKE_PROBE_INTERVAL:-2}"    # seconds between probes
NUKE_STEADY_MIN_SUCCESS="${NUKE_STEADY_MIN_SUCCESS:-95}"  # pass bar, percent
NUKE_RECOVER_WITHIN="${NUKE_RECOVER_WITHIN:-30}"   # seconds to heal after fault

# Integer percentage of success over total, guarding total == 0.
nuke_pct() {
    local success="$1" total="$2"
    (( total <= 0 )) && { printf '0'; return 0; }
    printf '%d' $(( success * 100 / total ))
}

# Decide the verdict from the measured numbers. Pure: no I/O, unit-testable.
# RESILIENT only if the steady state held above the bar AND the system recovered.
# Echoes RESILIENT or WEAK; returns 0 for RESILIENT, 1 otherwise.
nuke_verdict_compute() {
    local pct="$1" min="$2" recovered="$3"
    if (( pct >= min )) && (( recovered == 1 )); then
        printf 'RESILIENT'
        return 0
    fi
    printf 'WEAK'
    return 1
}

# Write a short, shareable report of the run under the session's output dir.
_nuke_verdict_report() {
    local label="$1" verdict="$2" pct="$3" min="$4" \
          recovered="$5" recover_time="$6" success="$7" total="$8"
    local dir="${NUKE_OUTPUT_DIR}/resilience"
    mkdir -p "${dir}"
    local file
    file="${dir}/$(date +%Y%m%d_%H%M%S)_${label//[^A-Za-z0-9]/_}.txt"
    {
        printf 'Nuke resilience report\n'
        printf 'date        : %s\n' "$(date -Is 2>/dev/null || date)"
        printf 'session     : %s\n' "${NUKE_SESSION_NAME:-none}"
        printf 'scope       : %s\n' "${NUKE_SCOPE:-none}"
        printf 'fault       : %s\n' "${label}"
        printf 'verdict     : %s\n' "${verdict}"
        printf 'steady state: %s%% healthy (bar %s%%)\n' "${pct}" "${min}"
        if (( recovered )); then
            printf 'recovery    : %ss\n' "${recover_time}"
        else
            printf 'recovery    : did not recover within the window\n'
        fi
        printf 'samples     : %s healthy / %s total\n' "${success}" "${total}"
    } > "${file}"
    log_info "Report: ${file}"
}

# nuke_resilience_run <probe_fn> <fault_fn> <level> <expected_dur> <label>
# Baseline -> inject -> observe -> verdict. probe_fn returns 0 when healthy;
# fault_fn is called as `fault_fn <level>`. expected_dur is the fault's own
# duration (0 for an instantaneous fault such as pod-kill).
nuke_resilience_run() {
    local probe_fn="$1" fault_fn="$2" level="$3" expected_dur="${4:-0}" label="${5:-fault}"
    local interval="${NUKE_PROBE_INTERVAL}"
    local min="${NUKE_STEADY_MIN_SUCCESS}"
    local recover_within="${NUKE_RECOVER_WITHIN}"

    # 1. Baseline: refuse to judge a system that is already unhealthy.
    log_step "Baseline: confirming the system is healthy first..."
    local i
    for i in 1 2 3; do
        if ! "${probe_fn}"; then
            log_error "System is already unhealthy. Fix it before a resilience check."
            return 2
        fi
        sleep 1
    done
    log_success "Baseline healthy."

    local window=$(( expected_dur + recover_within ))
    log_info "Steady state : ${probe_fn}"
    log_info "Probing every ${interval}s; pass bar ${min}%; window ${window}s"

    # 2. Inject the fault, then start the clock.
    log_step "Injecting: ${label} @ $(nuke_level_label "${level}")"
    "${fault_fn}" "${level}"
    local fault_at start_ts now elapsed
    fault_at="$(date +%s)"
    start_ts="${fault_at}"

    # 3. Observe: sample the steady state until the window closes.
    local total=0 success=0 streak=0 recovered=0 recover_time=0
    while : ; do
        now="$(date +%s)"
        elapsed=$(( now - start_ts ))
        (( elapsed >= window )) && break
        if "${probe_fn}"; then
            success=$(( success + 1 ))
            streak=$(( streak + 1 ))
            # Two clean samples in a row counts as recovered.
            if (( ! recovered )) && (( streak >= 2 )); then
                recovered=1
                recover_time=$(( now - fault_at ))
            fi
        else
            streak=0
        fi
        total=$(( total + 1 ))
        sleep "${interval}"
    done

    # 4. Verdict.
    local pct verdict rc
    pct="$(nuke_pct "${success}" "${total}")"
    verdict="$(nuke_verdict_compute "${pct}" "${min}" "${recovered}")"
    rc=$?

    printf '\n'
    if (( rc == 0 )); then
        printf '   %b%b✔ RESILIENT%b  ' "${BOLD}" "${BRIGHT_GREEN}" "${RESET}"
    else
        printf '   %b%b✘ WEAK SPOT%b  ' "${BOLD}" "${BRIGHT_RED}" "${RESET}"
    fi
    printf '%s%% healthy (bar %s%%)\n' "${pct}" "${min}"
    if (( recovered )); then
        printf '   recovered in %ss\n' "${recover_time}"
    else
        printf '   %bdid not recover within %ss%b\n' "${YELLOW}" "${window}" "${RESET}"
    fi
    printf '   %bsamples: %s healthy / %s total%b\n' "${DIM}" "${success}" "${total}" "${RESET}"

    _nuke_verdict_report "${label}" "${verdict}" "${pct}" "${min}" \
        "${recovered}" "${recover_time}" "${success}" "${total}"
    return "${rc}"
}
