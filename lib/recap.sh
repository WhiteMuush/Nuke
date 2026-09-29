#!/usr/bin/env bash
# lib/recap.sh — Ansible-style output contract for the headless / CI path.
# TASK headers, one issue per line on the Ansible palette, and a PLAY RECAP with
# counters named in the tool's own words. The exit code stays the machine
# interface; this is the human-readable side. Used by `nuke run` and, later, by
# GameDay to sum up several experiments at a glance.

if [[ -n "${NUKE_RECAP_LOADED:-}" ]]; then
    return 0
fi
NUKE_RECAP_LOADED=1

_NUKE_RULE_W=72   # width the TASK / PLAY RECAP banners fill with '*'

# Verdict counters for the current play. Updated by direct call only (a $()
# subshell would lose them), summed by nuke_recap_print.
NUKE_RECAP_RESILIENT=0
NUKE_RECAP_WEAK=0
NUKE_RECAP_ERRORED=0

# Print "TASK [<text>] ****...", padded to the rule width.
nuke_task() {
    local head="TASK [$1] "
    local pad=$(( _NUKE_RULE_W - ${#head} ))
    (( pad < 0 )) && pad=0
    printf '\n%s%s\n' "${head}" "$(printf '%*s' "${pad}" '' | tr ' ' '*')"
}

# nuke_issue <kind> <text...> — one issue line on the Ansible palette.
# kinds: ok (green), changed (yellow), skipping (cyan), unreachable (bright
# red), fatal (red). WARN/ERROR-grade issues (unreachable/fatal) go to stderr.
nuke_issue() {
    local kind="$1"; shift
    local color label out=1
    case "${kind}" in
        ok)          color="${GREEN}";      label="ok"          ;;
        changed)     color="${YELLOW}";     label="changed"     ;;
        skipping)    color="${CYAN}";       label="skipping"    ;;
        unreachable) color="${BRIGHT_RED}"; label="unreachable"; out=2 ;;
        fatal)       color="${RED}";        label="fatal";       out=2 ;;
        *)           color="";              label="${kind}"     ;;
    esac
    printf '%b%-12s%b %s\n' "${color}" "${label}:" "${RESET}" "$*" >&"${out}"
}

nuke_recap_reset() {
    NUKE_RECAP_RESILIENT=0
    NUKE_RECAP_WEAK=0
    NUKE_RECAP_ERRORED=0
}

# nuke_recap_add <resilient|weak|errored> — tally one experiment's outcome.
nuke_recap_add() {
    case "$1" in
        resilient) NUKE_RECAP_RESILIENT=$(( NUKE_RECAP_RESILIENT + 1 )) ;;
        weak)      NUKE_RECAP_WEAK=$(( NUKE_RECAP_WEAK + 1 ))           ;;
        *)         NUKE_RECAP_ERRORED=$(( NUKE_RECAP_ERRORED + 1 ))     ;;
    esac
}

# Map a run's exit code to a verdict word: 0 resilient, 1 weak, else errored.
nuke_recap_word() {
    case "$1" in
        0) printf 'resilient' ;;
        1) printf 'weak'      ;;
        *) printf 'errored'   ;;
    esac
}

# Print "PLAY RECAP ****..." plus the counters, colored on the palette.
nuke_recap_print() {
    local name="$1"
    local head="PLAY RECAP "
    local pad=$(( _NUKE_RULE_W - ${#head} ))
    (( pad < 0 )) && pad=0
    printf '\n%s%s\n' "${head}" "$(printf '%*s' "${pad}" '' | tr ' ' '*')"
    printf '%-18s: %bresilient=%d%b  %bweak=%d%b  %berrored=%d%b\n' \
        "${name}" \
        "${GREEN}"      "${NUKE_RECAP_RESILIENT}" "${RESET}" \
        "${RED}"        "${NUKE_RECAP_WEAK}"      "${RESET}" \
        "${BRIGHT_RED}" "${NUKE_RECAP_ERRORED}"   "${RESET}"
}
