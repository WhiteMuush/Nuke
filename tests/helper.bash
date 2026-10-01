# Shared test helper: load the Nuke library with terminal side effects stubbed.
_nuke_load() {
    # Neutralize terminal-affecting commands so tests are deterministic.
    clear() { :; }
    tput() { case "$1" in cols) echo 100 ;; lines) echo 40 ;; *) echo 0 ;; esac; }
    export -f clear tput 2>/dev/null || true
    export NUKE_NO_TRUECOLOR=1

    local root
    root="$(cd "$(dirname "${BATS_TEST_FILENAME}")/.." && pwd)"
    local lib
    for lib in core installer runner safety intensity toolbox ui; do
        # shellcheck disable=SC1090
        source "${root}/lib/${lib}.sh"
    done
    # shellcheck disable=SC1090
    source "${root}/lib/modules/config.sh"
    # shellcheck disable=SC1090
    source "${root}/lib/modules/kubernetes.sh"
}

# Strip ANSI escapes from $1, echo the visible text.
strip_ansi() {
    printf '%s' "$1" | sed -E 's/\x1B\[[0-9;?]*[ -/]*[@-~]//g'
}
