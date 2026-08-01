#!/usr/bin/env bash
# lib/modules/config.sh — Target and output configuration.

if [[ -n "${NUKE_MODULE_CONFIG_LOADED:-}" ]]; then
    return 0
fi
NUKE_MODULE_CONFIG_LOADED=1

# ---------------------------------------------------------------------------
# Shared check used by the layers.
# ---------------------------------------------------------------------------
ensure_output_dir() {
    mkdir -p "${NUKE_OUTPUT_DIR}"
}

# ---------------------------------------------------------------------------
# Configuration menu actions.
# ---------------------------------------------------------------------------
config_detect_environment() {
    nuke_subview "DETECT ENVIRONMENT"
    nuke_detect_env
    press_enter_to_continue
}

config_set_output_dir() {
    nuke_subview "OUTPUT DIRECTORY"
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
            1) config_set_output_dir ;;
            2) config_detect_environment ;;
            0) return ;;
            *)
                printf '\n%bInvalid choice!%b\n' "${BRIGHT_RED}" "${RESET}"
                sleep 1
                ;;
        esac
    done
}
