#!/usr/bin/env bash
# lib/modules/network.sh — Host network chaos layer.
# Scope is a network interface. Faults will be driven by tc/netem (latency,
# loss, bandwidth, corruption) and iptables (blackhole). Only the menu and
# safety scaffold ship today; each fault is a stub that states what it will do.

if [[ -n "${NUKE_MODULE_NETWORK_LOADED:-}" ]]; then
    return 0
fi
NUKE_MODULE_NETWORK_LOADED=1

# Interface this layer targets (empty = not set).
NUKE_NET_IFACE="${NUKE_NET_IFACE:-}"

# Guess a sensible default interface (the one with the default route).
_net_default_iface() {
    ip route show default 2>/dev/null | awk '/default/{print $5; exit}'
}

# Set the layer scope to a network interface and record it in NUKE_SCOPE.
net_set_scope() {
    nuke_subview "SET SCOPE"
    printf '   %bTarget one network interface. tc rules apply to it directly,%b\n' "${DIM}" "${RESET}"
    printf '   %bso pick a test interface, not your only link out.%b\n\n' "${DIM}" "${RESET}"

    local default_iface iface
    default_iface="${NUKE_NET_IFACE:-$(_net_default_iface)}"
    iface="$(prompt_value "Interface" "${default_iface:-eth0}")"
    if [[ -z "${iface}" ]]; then
        log_error "Interface cannot be empty."
        press_enter_to_continue
        return 1
    fi

    NUKE_NET_IFACE="${iface}"
    NUKE_SCOPE="net:${NUKE_NET_IFACE}"
    nuke_session_save
    log_success "Scope set: ${NUKE_SCOPE}"
    press_enter_to_continue
}

# Show the interface and any tc qdisc already attached.
net_status() {
    nuke_subview "STATUS"
    log_info "Scope : ${NUKE_SCOPE:-<not set>}"
    if [[ -z "${NUKE_NET_IFACE}" ]]; then
        log_warn "No interface scope set yet."
        press_enter_to_continue
        return 0
    fi
    printf '%b---- interface ----%b\n' "${DIM}" "${RESET}"
    ip -brief addr show "${NUKE_NET_IFACE}" 2>&1 | head -10
    printf '%b---- active tc qdisc ----%b\n' "${DIM}" "${RESET}"
    tc qdisc show dev "${NUKE_NET_IFACE}" 2>&1 | head -10
    press_enter_to_continue
}

_net_run_fault() {
    local label="$1" tool="$2" effect="$3" level
    nuke_require_scope || { press_enter_to_continue; return 1; }
    level="$(nuke_pick_level "Intensity for ${label}")" || return 0
    nuke_fault_stub "${label}" "${tool}" "${effect}" "${level}"
}

handle_network_menu() {
    local choice
    while true; do
        clear
        display_banner_with_menu "network"
        prompt_menu_choice "Network"
        read -r choice

        case "$choice" in
            1)  net_set_scope ;;
            2)  net_status ;;
            3)  _net_run_fault "Latency"    "tc netem delay"    "Add latency + jitter on the interface." ;;
            4)  _net_run_fault "Loss"       "tc netem loss"     "Drop a share of egress packets." ;;
            5)  _net_run_fault "Throttle"   "tc tbf"            "Cap bandwidth to a low ceiling." ;;
            6)  _net_run_fault "Corrupt"    "tc netem corrupt"  "Flip random bits in a share of packets." ;;
            7)  _net_run_fault "Blackhole"  "iptables DROP"     "Drop traffic to a port or host." ;;
            99) _net_run_fault "NUKE network" "tc + iptables"   "Every network vector at once, full force." ;;
            0)  return ;;
            *)
                printf '\n%bInvalid choice!%b\n' "${BRIGHT_RED}" "${RESET}"
                sleep 1
                ;;
        esac
    done
}
