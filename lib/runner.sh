#!/usr/bin/env bash
# lib/runner.sh — Run external chaos tools from inside the toolkit.
# Every tool is launched here so the user never leaves Nuke to drive it.
# Combined output is streamed live to the terminal and mirrored to a
# per-run log under the output dir. The tool's exit code is returned.

if [[ -n "${NUKE_RUNNER_LOADED:-}" ]]; then
    return 0
fi
NUKE_RUNNER_LOADED=1

# Directory holding per-run logs, under the configured output dir.
nuke_log_dir() {
    printf '%s/logs' "${NUKE_OUTPUT_DIR}"
}

# Turn an arbitrary label into a safe filename slug.
_nuke_slug() {
    printf '%s' "$1" | tr -c '[:alnum:]' '_' | tr -s '_' | sed 's/^_//; s/_$//'
}

# nuke_run <label> [--] <command> [args...]
# Runs the command, mirrors combined stdout+stderr to a timestamped log,
# and reports the exit code. The user stays in the toolkit throughout.
nuke_run() {
    local label="$1"; shift
    [[ "${1:-}" == "--" ]] && shift

    if [[ $# -eq 0 ]]; then
        log_error "nuke_run: no command given"
        return 2
    fi

    local dir stamp slug log
    dir="$(nuke_log_dir)"
    mkdir -p "$dir"
    slug="$(_nuke_slug "$label")"
    stamp="$(date +%Y%m%d_%H%M%S)"
    log="${dir}/${slug:-run}_${stamp}.log"

    log_step "Running: ${label}"
    log_info "Command: $*"
    log_info "Log: ${log}"
    printf '%b----------------------------------------%b\n' "${DIM}" "${RESET}"

    local rc=0
    "$@" 2>&1 | tee "$log"
    rc=${PIPESTATUS[0]}

    printf '%b----------------------------------------%b\n' "${DIM}" "${RESET}"
    if [[ $rc -eq 0 ]]; then
        log_success "${label} finished (exit ${rc})"
    else
        log_warn "${label} exited ${rc}"
    fi
    return "$rc"
}
