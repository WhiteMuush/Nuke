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
# shellcheck source=lib/verdict.sh
source "${SCRIPT_DIR}/lib/verdict.sh"
# shellcheck source=lib/recap.sh
source "${SCRIPT_DIR}/lib/recap.sh"
# shellcheck source=lib/session.sh
source "${SCRIPT_DIR}/lib/session.sh"
# shellcheck source=lib/modules/config.sh
source "${SCRIPT_DIR}/lib/modules/config.sh"
# shellcheck source=lib/modules/kubernetes.sh
source "${SCRIPT_DIR}/lib/modules/kubernetes.sh"
# shellcheck source=lib/modules/docker.sh
source "${SCRIPT_DIR}/lib/modules/docker.sh"
# shellcheck source=lib/modules/network.sh
source "${SCRIPT_DIR}/lib/modules/network.sh"
# shellcheck source=lib/experiment.sh
source "${SCRIPT_DIR}/lib/experiment.sh"
# shellcheck source=lib/modules/host.sh
source "${SCRIPT_DIR}/lib/modules/host.sh"

# Headless entry for CI: `nuke.sh run <experiment>` replays a saved resilience
# check with no menu and exits with its verdict code (0 resilient, 1 weak,
# 2 could not run). Everything below the dispatch is the interactive path.
nuke_headless_run() {
    local ref="${1:-}"
    if [[ -z "${ref}" ]]; then
        log_error "usage: nuke.sh run <experiment>"
        return 2
    fi
    nuke_arm_rollback
    export NUKE_SKIP_CONFIRM=1   # never block a pipeline on a typed prompt
    nuke_experiment_run "${ref}"
}

main_loop() {
    local choice
    nuke_arm_rollback
    display_title_middle_screen
    sleep 2

    # Pick or create the session before anything else, so its config is loaded.
    nuke_session_init

    while true; do
        clear
        display_banner_with_menu "main"
        echo -ne "   ${BOLD}${RED}▪ No mercy, no retreat. Pick your move : ${RESET}"
        read -r choice

        case "$choice" in
            1) handle_config_menu ;;
            2) handle_kubernetes_menu ;;
            3) handle_docker_menu ;;
            4) handle_network_menu ;;
            5) handle_host_menu ;;
            0)
                nuke_session_save
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

if [[ "${1:-}" == "run" ]]; then
    shift
    nuke_headless_run "$@"
    exit $?
fi

main_loop "$@"
