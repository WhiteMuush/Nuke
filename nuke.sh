#!/usr/bin/env bash
# Nuke — Interactive bash toolkit skeleton.
# Entry point: load the library, then drive the interactive menu loop.

set -uo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
readonly SCRIPT_DIR

# shellcheck source=lib/core.sh
source "${SCRIPT_DIR}/lib/core.sh"
# shellcheck source=lib/installer.sh
source "${SCRIPT_DIR}/lib/installer.sh"
# shellcheck source=lib/runner.sh
source "${SCRIPT_DIR}/lib/runner.sh"
# shellcheck source=lib/safety.sh
source "${SCRIPT_DIR}/lib/safety.sh"
# shellcheck source=lib/intensity.sh
source "${SCRIPT_DIR}/lib/intensity.sh"
# shellcheck source=lib/toolbox.sh
source "${SCRIPT_DIR}/lib/toolbox.sh"
# shellcheck source=lib/ui.sh
source "${SCRIPT_DIR}/lib/ui.sh"
# shellcheck source=lib/modules/config.sh
source "${SCRIPT_DIR}/lib/modules/config.sh"
# shellcheck source=lib/modules/kubernetes.sh
source "${SCRIPT_DIR}/lib/modules/kubernetes.sh"
# shellcheck source=lib/modules/passive.sh
source "${SCRIPT_DIR}/lib/modules/passive.sh"
# shellcheck source=lib/modules/active.sh
source "${SCRIPT_DIR}/lib/modules/active.sh"
# shellcheck source=lib/modules/special.sh
source "${SCRIPT_DIR}/lib/modules/special.sh"

main_loop() {
    local choice
    nuke_arm_rollback
    display_title_middle_screen
    sleep 2

    while true; do
        clear
        display_banner_with_menu "main"
        echo -ne "                                                             ${BOLD}${RED}▪ No mercy, no retreat. Pick your move : ${RESET}"
        read -r choice

        case "$choice" in
            1) handle_config_menu ;;
            2) handle_passive_menu ;;
            3) handle_active_menu ;;
            4) handle_special_menu ;;
            5) handle_kubernetes_menu ;;
            0)
                printf '\n%bExiting Nuke...%b\n' "${BRIGHT_MAGENTA}" "${RESET}"
                exit 0
                ;;
            *)
                printf '\n%bInvalid choice!%b\n' "${BRIGHT_RED}" "${RESET}"
                sleep 1
                ;;
        esac
    done
}

main_loop "$@"
