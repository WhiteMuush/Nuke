#!/usr/bin/env bash
# scripts/ci.sh — all pre-merge checks in one place.
# Run by the pre-push hook (.githooks/pre-push) and by GitHub Actions, so the
# local gate and CI are identical by construction.
#
#   lint   : ShellCheck every shell script (warnings and up)
#   syntax : bash -n every shell script
#   smoke  : source the whole library chain and assert key functions exist

set -uo pipefail
cd "$(dirname "${BASH_SOURCE[0]}")/.." || exit 2

fail=0
step() { printf '\n\033[1m==> %s\033[0m\n' "$1"; }

# ---------------------------------------------------------------------------
# 1. shellcheck (skipped with a warning when not installed locally; CI has it)
# ---------------------------------------------------------------------------
step "shellcheck"
mapfile -d '' -t sh_files < <(find . -name '*.sh' -not -path './.git/*' -print0)
sc_opts=(-S warning -e SC1091 -e SC2034 -e SC2154)
sc_img="docker.io/koalaman/shellcheck:stable"
if command -v shellcheck >/dev/null 2>&1; then
    shellcheck "${sc_opts[@]}" "${sh_files[@]}" && echo "shellcheck OK" || { echo "shellcheck FAILED"; fail=1; }
elif command -v podman >/dev/null 2>&1; then
    podman run --rm -v "${PWD}:/mnt:ro,z" -w /mnt "${sc_img}" "${sc_opts[@]}" "${sh_files[@]#./}" \
        && echo "shellcheck OK (podman)" || { echo "shellcheck FAILED"; fail=1; }
elif command -v docker >/dev/null 2>&1; then
    docker run --rm -v "${PWD}:/mnt:ro" -w /mnt "${sc_img}" "${sc_opts[@]}" "${sh_files[@]#./}" \
        && echo "shellcheck OK (docker)" || { echo "shellcheck FAILED"; fail=1; }
else
    echo "shellcheck unavailable (no binary, no podman/docker) — skipped; CI enforces it"
fi

# ---------------------------------------------------------------------------
# 2. syntax: bash -n
# ---------------------------------------------------------------------------
step "bash -n (syntax)"
syntax_ok=1
while IFS= read -r -d '' file; do
    if ! bash -n "$file"; then
        echo "SYNTAX ERROR: $file"
        syntax_ok=0
        fail=1
    fi
done < <(find . -name '*.sh' -not -path './.git/*' -print0)
(( syntax_ok )) && echo "syntax OK"

# ---------------------------------------------------------------------------
# 3. smoke: source chain + expected functions (runs in a subshell)
# ---------------------------------------------------------------------------
step "smoke (source chain + functions)"
if bash -c '
    set -uo pipefail
    for lib in core installer runner safety intensity toolbox ui verdict session; do
        source "./lib/${lib}.sh"
    done
    source ./lib/modules/config.sh
    source ./lib/modules/kubernetes.sh
    source ./lib/modules/docker.sh
    source ./lib/modules/network.sh
    source ./lib/modules/host.sh

    expected=(
        log_step log_info log_warn log_error log_success
        prompt_value prompt_password prompt_yesno press_enter_to_continue
        ensure_command resolve_command
        clone_or_pull pip_install pipx_install apt_install
        install_pip_requirements require_root
        nuke_run
        nuke_arm_rollback nuke_panic nuke_rollback_add nuke_rollback_run
        nuke_require_scope nuke_capped nuke_confirm_detonation
        nuke_level_index nuke_level_profile nuke_level_requires_confirm
        nuke_level_label nuke_pick_level
        nuke_have nuke_pkg_manager nuke_os_arch nuke_download
        nuke_install_binary nuke_detect_env
        render_banner_with_lines display_banner_with_menu display_title_middle_screen
        prompt_menu_choice nuke_subview nuke_prompt _menu_row2 _menu_key
        nuke_fault_stub nuke_menu_screen
        generate_main_menu generate_config_menu generate_kubernetes_menu
        generate_docker_menu generate_network_menu generate_host_menu
        nuke_sessions_root nuke_session_dir nuke_session_sanitize
        nuke_session_names nuke_session_save nuke_session_load
        nuke_session_use nuke_session_init nuke_session_summary_lines
        ensure_output_dir config_set_output_dir config_detect_environment
        config_switch_session config_rename_session handle_config_menu
        nuke_pct nuke_verdict_compute nuke_resilience_run
        k8s_available k8s_set_scope k8s_status k8s_pod_kill
        k8s_steady_probe k8s_resilience_check
        k8s_setup_chaos_mesh k8s_cm_net_delay k8s_cm_net_loss k8s_cm_stress_cpu
        k8s_cm_pod_failure k8s_cm_dns k8s_cm_time k8s_node_drain
        k8s_nuke_all k8s_recover handle_kubernetes_menu
        docker_available docker_set_scope docker_status handle_docker_menu
        net_set_scope net_status handle_network_menu
        host_set_scope host_status handle_host_menu
    )

    missing=0
    for fn in "${expected[@]}"; do
        if ! declare -F "$fn" >/dev/null; then
            echo "MISSING: $fn"
            missing=$((missing + 1))
        fi
    done
    if (( missing > 0 )); then
        echo "smoke FAILED: ${missing} function(s) missing"
        exit 1
    fi

    # Verdict math (pure functions, no cluster needed).
    check() { [[ "$2" == "$3" ]] || { echo "ASSERT FAIL: $1 -> got '\''$2'\'' want '\''$3'\''"; exit 1; }; }
    check "pct 95/100"  "$(nuke_pct 95 100)" "95"
    check "pct 0/0"     "$(nuke_pct 0 0)"    "0"
    check "pct 1/3"     "$(nuke_pct 1 3)"    "33"
    check "verdict pass"      "$(nuke_verdict_compute 96 95 1)" "RESILIENT"
    check "verdict low"       "$(nuke_verdict_compute 90 95 1)" "WEAK"
    check "verdict norecover" "$(nuke_verdict_compute 99 95 0)" "WEAK"
    nuke_verdict_compute 96 95 1 >/dev/null || { echo "ASSERT FAIL: RESILIENT rc"; exit 1; }
    nuke_verdict_compute 90 95 1 >/dev/null && { echo "ASSERT FAIL: WEAK rc"; exit 1; }
    echo "verdict assertions OK"

    echo "smoke OK — ${#expected[@]} functions present"
'; then
    :
else
    fail=1
fi

# ---------------------------------------------------------------------------
step "result"
if (( fail )); then
    printf '\033[31mchecks FAILED\033[0m\n'
    exit 1
fi
printf '\033[32mall checks passed\033[0m\n'
