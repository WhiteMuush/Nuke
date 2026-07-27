#!/usr/bin/env bash
# lib/modules/passive.sh — Passive module. Placeholder actions.
# Each function shows the canonical module shape; replace the body with a real
# tool invocation. See docs/ADDING_A_TOOL.md.

if [[ -n "${NUKE_MODULE_PASSIVE_LOADED:-}" ]]; then
    return 0
fi
NUKE_MODULE_PASSIVE_LOADED=1

passive_action_one() {
    printf '\n%bPassive Action One%b\n' "${BRIGHT_MAGENTA}" "${RESET}"
    require_target
    ensure_output_dir
    log_step "Not implemented yet. Wire your tool here."
    log_info "Pattern: ensure_command \"<binary>\" \"<hint>\" || return 0"
    log_info "See docs/ADDING_A_TOOL.md"
    press_enter_to_continue
}

passive_action_two() {
    printf '\n%bPassive Action Two%b\n' "${BRIGHT_MAGENTA}" "${RESET}"
    require_target
    ensure_output_dir
    log_step "Not implemented yet. Wire your tool here."
    log_info "See docs/ADDING_A_TOOL.md"
    press_enter_to_continue
}

handle_passive_menu() {
    local choice
    while true; do
        clear
        display_banner_with_menu "passive"
        prompt_menu_choice "Passive"
        read -r choice

        case "$choice" in
            1) passive_action_one ;;
            2) passive_action_two ;;
            0) return ;;
            *)
                printf '\n%bInvalid choice!%b\n' "${BRIGHT_RED}" "${RESET}"
                sleep 1
                ;;
        esac
    done
}
