#!/usr/bin/env bash
# lib/modules/active.sh — Active module. Placeholder actions.
# Each function shows the canonical module shape; replace the body with a real
# tool invocation. See docs/ADDING_A_TOOL.md.

if [[ -n "${NUKE_MODULE_ACTIVE_LOADED:-}" ]]; then
    return 0
fi
NUKE_MODULE_ACTIVE_LOADED=1

active_action_one() {
    printf '\n%bActive Action One%b\n' "${BRIGHT_MAGENTA}" "${RESET}"
    require_target
    ensure_output_dir
    log_step "Not implemented yet. Wire your tool here."
    log_info "See docs/ADDING_A_TOOL.md"
    press_enter_to_continue
}

active_action_two() {
    printf '\n%bActive Action Two%b\n' "${BRIGHT_MAGENTA}" "${RESET}"
    require_target
    ensure_output_dir
    log_step "Not implemented yet. Wire your tool here."
    log_info "See docs/ADDING_A_TOOL.md"
    press_enter_to_continue
}

handle_active_menu() {
    local choice
    while true; do
        clear
        display_banner_with_menu "active"
        prompt_menu_choice "Active"
        read -r choice

        case "$choice" in
            1) active_action_one ;;
            2) active_action_two ;;
            0) return ;;
            *)
                printf '\n%bInvalid choice!%b\n' "${BRIGHT_RED}" "${RESET}"
                sleep 1
                ;;
        esac
    done
}
