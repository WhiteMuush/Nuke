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

# Layer not built yet: show a clear notice instead of a broken placeholder.
handle_coming_soon() {
    local name="$1"
    clear
    display_banner_with_menu "main"
    printf '\n%b%s layer is coming soon.%b\n' "${BOLD}${BRIGHT_RED}" "${name}" "${RESET}"
    printf '%bAlready available: Kubernetes. Next up per the roadmap.%b\n' "${DIM}" "${RESET}"
    press_enter_to_continue
}

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
            2) handle_kubernetes_menu ;;
            3) handle_coming_soon "Docker" ;;
            4) handle_coming_soon "Network" ;;
            5) handle_coming_soon "Host" ;;
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
