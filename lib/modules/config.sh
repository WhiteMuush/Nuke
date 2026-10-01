#!/usr/bin/env bash
# lib/modules/config.sh — Session, output and environment configuration.
# The active session (see lib/session.sh) owns the persisted config; the actions
# here edit it and save on every change.

if [[ -n "${NUKE_MODULE_CONFIG_LOADED:-}" ]]; then
    return 0
fi
NUKE_MODULE_CONFIG_LOADED=1

ensure_output_dir() {
    mkdir -p "${NUKE_OUTPUT_DIR}"
}

config_set_output_dir() {
    nuke_subview "OUTPUT DIRECTORY"
    printf '   %bWhere Nuke writes logs and results for this session.%b\n\n' "${DIM}" "${RESET}"
    local custom_dir
    custom_dir=$(prompt_value "Directory" "${NUKE_OUTPUT_DIR}")
    NUKE_OUTPUT_DIR="${custom_dir}"
    mkdir -p "${NUKE_OUTPUT_DIR}"
    nuke_session_save
    log_success "Output: ${NUKE_OUTPUT_DIR}"
    press_enter_to_continue
}

config_detect_environment() {
    nuke_subview "DETECT ENVIRONMENT"
    nuke_detect_env
    press_enter_to_continue
}

# Switch to another session, or start a new one. Reuses the boot picker's
# building blocks so the two entry points behave identically.
config_switch_session() {
    nuke_menu_screen "Nuke Switch Session" "Choice" \
        "${BRIGHT_RED}[1]${RESET}  New session" \
        "${BRIGHT_RED}[2]${RESET}  Continue an existing session" \
        "" \
        "${BRIGHT_RED}[0]${RESET}  Cancel"
    local choice
    read -r choice
    case "${choice}" in
        1) _nuke_session_new ;;
        2) _nuke_session_continue || return 0 ;;
        *) return 0 ;;
    esac
    press_enter_to_continue
}

# Rename the active session on disk and in memory.
config_rename_session() {
    nuke_subview "RENAME SESSION"
    printf '   %bCurrent name:%b %s\n\n' "${DIM}" "${RESET}" "${NUKE_SESSION_NAME}"
    local raw new
    raw="$(prompt_value "New name" "${NUKE_SESSION_NAME}")"
    new="$(nuke_session_sanitize "${raw}")"
    if [[ -z "${new}" || "${new}" == "${NUKE_SESSION_NAME}" ]]; then
        log_info "No change."
        press_enter_to_continue
        return 0
    fi

    local old_dir new_dir
    old_dir="$(nuke_session_dir "${NUKE_SESSION_NAME}")"
    new_dir="$(nuke_session_dir "${new}")"
    if [[ -e "${new_dir}" ]]; then
        log_error "A session named '${new}' already exists."
        press_enter_to_continue
        return 1
    fi

    mv "${old_dir}" "${new_dir}"
    NUKE_SESSION_NAME="${new}"
    NUKE_OUTPUT_DIR="${new_dir}/output"
    nuke_session_save
    log_success "Renamed to: ${new}"
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
            1) config_switch_session ;;
            2) config_rename_session ;;
            3) config_set_output_dir ;;
            4) config_detect_environment ;;
            0) return ;;
            *)
                printf '\n%bInvalid choice!%b\n' "${BRIGHT_RED}" "${RESET}"
                sleep 1
                ;;
        esac
    done
}
