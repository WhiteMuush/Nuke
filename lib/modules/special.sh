#!/usr/bin/env bash
# lib/modules/special.sh — Special module. Placeholder action + results viewer.
# See docs/ADDING_A_TOOL.md.

if [[ -n "${NUKE_MODULE_SPECIAL_LOADED:-}" ]]; then
    return 0
fi
NUKE_MODULE_SPECIAL_LOADED=1

special_action_one() {
    printf '\n%b%bSpecial Action One%b\n' "${BRIGHT_MAGENTA}" "${BOLD}" "${RESET}"
    require_target
    ensure_output_dir
    log_step "Not implemented yet. Chain your workflow here."
    log_info "See docs/ADDING_A_TOOL.md"
    press_enter_to_continue
}

special_view_results() {
    printf '\n%bResults Viewer%b\n' "${BRIGHT_MAGENTA}" "${RESET}"
    if [[ ! -d "${NUKE_OUTPUT_DIR}" ]]; then
        log_warn "No results directory found at ${NUKE_OUTPUT_DIR}"
    else
        log_info "Files in ${NUKE_OUTPUT_DIR}:"
        ls -lh "${NUKE_OUTPUT_DIR}"
    fi
    press_enter_to_continue
}

handle_special_menu() {
    local choice
    while true; do
        clear
        display_banner_with_menu "special"
        prompt_menu_choice "Special"
        read -r choice

        case "$choice" in
            1) special_action_one ;;
            2) special_view_results ;;
            0) return ;;
            *)
                printf '\n%bInvalid choice!%b\n' "${BRIGHT_RED}" "${RESET}"
                sleep 1
                ;;
        esac
    done
}
