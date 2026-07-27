#!/usr/bin/env bash
# lib/modules/config.sh — Target and output configuration.

if [[ -n "${NUKE_MODULE_CONFIG_LOADED:-}" ]]; then
    return 0
fi
NUKE_MODULE_CONFIG_LOADED=1

# ---------------------------------------------------------------------------
# Quick checks used by the action modules. Each prompts if the corresponding
# global is empty.
# ---------------------------------------------------------------------------
require_target() {
    if [[ -z "${NUKE_TARGET}" ]]; then
        log_warn "No target set."
        NUKE_TARGET=$(prompt_value "Enter target IP/hostname")
    fi
}

ensure_output_dir() {
    mkdir -p "${NUKE_OUTPUT_DIR}"
}

# ---------------------------------------------------------------------------
# Configuration menu actions.
# ---------------------------------------------------------------------------
config_set_target() {
    printf '\n%bSetting Target%b\n' "${BRIGHT_MAGENTA}" "${RESET}"
    NUKE_TARGET=$(prompt_value "Target IP/hostname")
    log_success "Target set: ${NUKE_TARGET}"
    press_enter_to_continue
}

config_set_output_dir() {
    printf '\n%bSetting Output Directory%b\n' "${BRIGHT_MAGENTA}" "${RESET}"
    local custom_dir
    custom_dir=$(prompt_value "Directory name" "${NUKE_OUTPUT_DIR}")
    NUKE_OUTPUT_DIR="${custom_dir}"
    mkdir -p "${NUKE_OUTPUT_DIR}"
    log_success "Output: ${NUKE_OUTPUT_DIR}"
    press_enter_to_continue
}

handle_config_menu() {
    local choice
    while true; do
        clear
        display_banner_with_menu "config"
        prompt_menu_choice "Configure"
        read -r choice

        case "$choice" in
            1) config_set_target ;;
            2) config_set_output_dir ;;
            0) return ;;
            *)
                printf '\n%bInvalid choice!%b\n' "${BRIGHT_RED}" "${RESET}"
                sleep 1
                ;;
        esac
    done
}
