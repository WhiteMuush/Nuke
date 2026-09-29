#!/usr/bin/env bash
# lib/verdict.sh — Turn a fault into a verdict.
# A resilience check probes a steady state, injects a fault, keeps probing
# through recovery, then decides: did the system hold and heal, or not? This is
# what lifts Nuke from "it breaks things" to "it tells you if you survived".
# The engine is layer-agnostic: callers pass a probe function and a fault
# function, so k8s, docker, network and host can all reuse it.
#
# The verdict is driven by the longest continuous outage, measured on the clock,
# not by a share of samples. A count of samples is flaky when an outage is short
# (it lands on two probes one run, three the next); "the service was down for Ns"
# is stable and it is the number a team actually cares about.

if [[ -n "${NUKE_VERDICT_LOADED:-}" ]]; then
    return 0
fi
NUKE_VERDICT_LOADED=1

# Tunables. Defaulted so a resilience check needs zero configuration; a caller
# or a saved experiment may override them.
NUKE_PROBE_INTERVAL="${NUKE_PROBE_INTERVAL:-2}"   # seconds between probes
NUKE_MAX_DOWNTIME="${NUKE_MAX_DOWNTIME:-5}"       # allowed continuous outage, s
NUKE_RECOVER_WITHIN="${NUKE_RECOVER_WITHIN:-30}"  # seconds to heal after fault

# Integer percentage of success over total, guarding total == 0. Informational.
nuke_pct() {
    local success="$1" total="$2"
    (( total <= 0 )) && { printf '0'; return 0; }
    printf '%d' $(( success * 100 / total ))
}

# Decide the verdict from the measured numbers. Pure: no I/O, unit-testable.
# RESILIENT only if the system recovered AND its longest outage stayed within
# the budget. Echoes RESILIENT or WEAK; returns 0 for RESILIENT, 1 otherwise.
nuke_verdict_compute() {
    local max_down="$1" budget="$2" recovered="$3"
    if (( recovered == 1 )) && (( max_down <= budget )); then
        printf 'RESILIENT'
        return 0
    fi
    printf 'WEAK'
    return 1
}

# Write a short, shareable report of the run under the session's output dir.
_nuke_verdict_report() {
    local label="$1" verdict="$2" max_down="$3" budget="$4" \
          recovered="$5" recover_time="$6" pct="$7" success="$8" total="$9"
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
        printf 'max outage  : %ss (budget %ss)\n' "${max_down}" "${budget}"
        if (( recovered )); then
            printf 'recovery    : back to healthy %ss after the fault\n' "${recover_time}"
        else
            printf 'recovery    : did not recover within the window\n'
        fi
        printf 'availability: %s%% of probes healthy (%s/%s)\n' "${pct}" "${success}" "${total}"
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
    local budget="${NUKE_MAX_DOWNTIME}"
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
    log_info "Probing every ${interval}s; outage budget ${budget}s; window ${window}s"

    # 2. Inject the fault, then start the clock.
    log_step "Injecting: ${label} @ $(nuke_level_label "${level}")"
    "${fault_fn}" "${level}"
    local fault_at start_ts now elapsed
    fault_at="$(date +%s)"
    start_ts="${fault_at}"

    # 3. Observe: sample the steady state until the window closes. Track the
    #    longest continuous outage on the clock (down_since -> first healthy).
    local total=0 success=0
    local down_since=0 max_down=0 recovered=0 recover_time=0
    while : ; do
        now="$(date +%s)"
        elapsed=$(( now - start_ts ))
        (( elapsed >= window )) && break
        if "${probe_fn}"; then
            success=$(( success + 1 ))
            if (( down_since != 0 )); then
                local d=$(( now - down_since ))
                (( d > max_down )) && max_down=$d
                down_since=0
            fi
            if (( ! recovered )); then
                recovered=1
                recover_time=$(( now - fault_at ))
            fi
        else
            (( down_since == 0 )) && down_since="${now}"
        fi
        total=$(( total + 1 ))
        sleep "${interval}"
    done

    # Still down when the window closed: count that outage and mark not-recovered.
    if (( down_since != 0 )); then
        now="$(date +%s)"
        local d=$(( now - down_since ))
        (( d > max_down )) && max_down=$d
        recovered=0
    fi

    # 4. Verdict.
    local pct verdict rc
    pct="$(nuke_pct "${success}" "${total}")"
    verdict="$(nuke_verdict_compute "${max_down}" "${budget}" "${recovered}")"
    rc=$?

    printf '\n'
    if (( rc == 0 )); then
        printf '   %b%b✔ RESILIENT%b\n' "${BOLD}" "${BRIGHT_GREEN}" "${RESET}"
    else
        printf '   %b%b✘ WEAK SPOT%b\n' "${BOLD}" "${BRIGHT_RED}" "${RESET}"
    fi
    if (( max_down == 0 )); then
        printf '   no full outage (budget %ss)\n' "${budget}"
    else
        printf '   worst outage %ss (budget %ss)\n' "${max_down}" "${budget}"
    fi
    if (( recovered )); then
        printf '   recovered %ss after the fault\n' "${recover_time}"
    else
        printf '   %bdid not recover within %ss%b\n' "${YELLOW}" "${window}" "${RESET}"
    fi
    printf '   %bavailability: %s%% of probes healthy (%s/%s)%b\n' \
        "${DIM}" "${pct}" "${success}" "${total}" "${RESET}"

    _nuke_verdict_report "${label}" "${verdict}" "${max_down}" "${budget}" \
        "${recovered}" "${recover_time}" "${pct}" "${success}" "${total}"
    return "${rc}"
}
