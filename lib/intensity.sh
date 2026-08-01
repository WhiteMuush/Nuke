#!/usr/bin/env bash
# lib/intensity.sh — The NUKE intensity ladder.
# One shared scale, POKE -> STRESS -> HAVOC -> NUKE!, that every layer maps
# onto its own tool parameters. Keeps the crescendo consistent across host,
# container, network and kubernetes chaos.

if [[ -n "${NUKE_INTENSITY_LOADED:-}" ]]; then
    return 0
fi
NUKE_INTENSITY_LOADED=1

# Ordered levels, weakest to strongest.
NUKE_LEVEL_NAMES=(POKE STRESS HAVOC NUKE)

# 1-based index of a level name, or 0 if unknown.
nuke_level_index() {
    local name="$1" i
    for i in "${!NUKE_LEVEL_NAMES[@]}"; do
        if [[ "${NUKE_LEVEL_NAMES[i]}" == "${name}" ]]; then
            printf '%d' $(( i + 1 ))
            return 0
        fi
    done
    printf '0'
    return 1
}

# nuke_level_profile <level> <field>
# Normalized knobs each layer interprets for its own tools:
#   duration  seconds the fault runs (before auto-heal)
#   blast     how many targets to hit (9999 = every target in scope)
#   magnitude fault strength 0..100 (cpu workers, latency ms, loss %, ...)
#   vectors   how many fault types run at once (99 = all available)
# Unknown level or field echoes nothing and returns 1.
nuke_level_profile() {
    local level="$1" field="$2"
    local duration blast magnitude vectors
    case "${level}" in
        POKE)   duration=10;  blast=1;    magnitude=20;  vectors=1  ;;
        STRESS) duration=30;  blast=2;    magnitude=50;  vectors=1  ;;
        HAVOC)  duration=60;  blast=5;    magnitude=80;  vectors=3  ;;
        NUKE)   duration=120; blast=9999; magnitude=100; vectors=99 ;;
        *) return 1 ;;
    esac
    case "${field}" in
        duration)  printf '%d' "${duration}"  ;;
        blast)     printf '%d' "${blast}"     ;;
        magnitude) printf '%d' "${magnitude}" ;;
        vectors)   printf '%d' "${vectors}"   ;;
        *) return 1 ;;
    esac
}

# Return 0 if the level requires a typed detonation confirmation (NUKE only).
nuke_level_requires_confirm() {
    [[ "$1" == "NUKE" ]]
}

# Short human label for a level, colored by escalation.
nuke_level_label() {
    case "$1" in
        POKE)   printf '%bPOKE%b'   "${GREEN}"      "${RESET}" ;;
        STRESS) printf '%bSTRESS%b' "${YELLOW}"     "${RESET}" ;;
        HAVOC)  printf '%bHAVOC%b'  "${BRIGHT_RED}" "${RESET}" ;;
        NUKE)   printf '%b%bNUKE!%b' "${BOLD}" "${BRIGHT_RED}" "${RESET}" ;;
        *)      printf '%s' "$1" ;;
    esac
}

# Interactive level picker rendered as a full cleared sub-view (so it replaces
# the current menu instead of stacking below it). The screen goes to stderr;
# only the chosen level name is echoed on stdout for capture. Empty on cancel.
nuke_pick_level() {
    local title="${1:-Choose intensity}"
    {
        clear
        local -a lines=(
            "${NUKE_BRAND_HEADER[@]}"
            "${BOLD}${BRIGHT_RED}${title}${RESET}"
            ""
            "$(printf '%b[1]%b  %b   single, brief probe'    "${BRIGHT_RED}" "${RESET}" "$(nuke_level_label POKE)")"
            "$(printf '%b[2]%b  %b sustained, moderate'      "${BRIGHT_RED}" "${RESET}" "$(nuke_level_label STRESS)")"
            "$(printf '%b[3]%b  %b  multi-fault, wide blast' "${BRIGHT_RED}" "${RESET}" "$(nuke_level_label HAVOC)")"
            "$(printf '%b[4]%b  %b everything, full force'   "${BRIGHT_RED}" "${RESET}" "$(nuke_level_label NUKE)")"
            "$(printf '%b[0]%b  cancel'                      "${BRIGHT_RED}" "${RESET}")"
        )
        render_banner_with_lines "${lines[@]}"
        nuke_prompt "Intensity"
    } >&2
    local choice
    read -r choice
    case "${choice}" in
        1) printf 'POKE'   ;;
        2) printf 'STRESS' ;;
        3) printf 'HAVOC'  ;;
        4) printf 'NUKE'   ;;
        *) return 1 ;;
    esac
}
