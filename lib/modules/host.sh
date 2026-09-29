#!/usr/bin/env bash
# lib/modules/host.sh — Local host chaos layer.
# Scope is THIS machine, so it carries the most weight: an explicit typed
# acknowledgement gates the scope. Faults will be driven by stress-ng (cpu,
# memory, io, disk fill) and a bounded clock skew. Only the menu and safety
# scaffold ship today; each fault is a stub that states what it will do.

if [[ -n "${NUKE_MODULE_HOST_LOADED:-}" ]]; then
    return 0
fi
NUKE_MODULE_HOST_LOADED=1

# The host in scope (empty = not set). Set only after an explicit acknowledgement.
NUKE_HOST_NAME="${NUKE_HOST_NAME:-}"

# Set the layer scope to the local machine. Host chaos cannot be aimed
# elsewhere, so require the operator to type the hostname to confirm intent.
host_set_scope() {
    nuke_subview "SET SCOPE"
    local this_host
    this_host="$(hostname 2>/dev/null || printf 'localhost')"

    printf '   %bHost chaos hits THIS machine (%s). There is no remote target.%b\n' \
        "${YELLOW}" "${this_host}" "${RESET}"
    printf '   %bType the hostname to confirm you mean to stress this box.%b\n\n' "${DIM}" "${RESET}"

    local answer
    answer="$(prompt_value "Confirm hostname")"
    if [[ "${answer}" != "${this_host}" ]]; then
        log_error "Mismatch. Scope not set."
        press_enter_to_continue
        return 1
    fi

    NUKE_HOST_NAME="${this_host}"
    NUKE_SCOPE="host:${NUKE_HOST_NAME}"
    nuke_session_save
    log_success "Scope set: ${NUKE_SCOPE}"
    press_enter_to_continue
}

# Show a quick load snapshot for the host.
host_status() {
    nuke_subview "STATUS"
    log_info "Scope : ${NUKE_SCOPE:-<not set>}"
    printf '%b---- load / memory ----%b\n' "${DIM}" "${RESET}"
    uptime 2>&1 | head -1
    free -h 2>&1 | head -2
    press_enter_to_continue
}

_host_run_fault() {
    local label="$1" tool="$2" effect="$3" level
    nuke_require_scope || { press_enter_to_continue; return 1; }
    level="$(nuke_pick_level "Intensity for ${label}")" || return 0
    nuke_fault_stub "${label}" "${tool}" "${effect}" "${level}"
}

handle_host_menu() {
    local choice
    while true; do
        clear
        display_banner_with_menu "host"
        prompt_menu_choice "Host"
        read -r choice

        case "$choice" in
            1)  host_set_scope ;;
            2)  host_status ;;
            3)  _host_run_fault "CPU stress"    "stress-ng --cpu"     "Saturate CPU cores for the fault window." ;;
            4)  _host_run_fault "Memory stress" "stress-ng --vm"      "Allocate and touch memory to pressure the box." ;;
            5)  _host_run_fault "IO stress"     "stress-ng --io"      "Hammer the storage layer with sync I/O." ;;
            6)  _host_run_fault "Disk fill"     "fallocate"           "Fill a bounded scratch file, freed on recover." ;;
            7)  _host_run_fault "Clock skew"    "date / libfaketime"  "Shift the clock within a bounded offset." ;;
            99) _host_run_fault "NUKE host"     "stress-ng (all)"     "Every host vector at once, full force." ;;
            0)  return ;;
            *)
                printf '\n%bInvalid choice!%b\n' "${BRIGHT_RED}" "${RESET}"
                sleep 1
                ;;
        esac
    done
}
