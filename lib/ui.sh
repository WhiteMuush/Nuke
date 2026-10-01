#!/usr/bin/env bash
# lib/ui.sh — ASCII art, menus and banner rendering.

if [[ -n "${NUKE_UI_LOADED:-}" ]]; then
    return 0
fi
NUKE_UI_LOADED=1

# ---------------------------------------------------------------------------
# Decorative ASCII art displayed alongside each menu. Swap for your own.
# ---------------------------------------------------------------------------
NUKE_ASCII_ART=$(cat <<'ASCII'

⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⣀⡤⠤⠴⠾⠋⠉⠛⢾⡏⠙⠿⠦⠤⢤⣀⡀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀
⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢀⡤⢶⣿⠉⢀⣀⡠⠆⠀⠀⠀⠀⠀⠀⠀⢤⣀⣀⠈⢹⣦⢤⡀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀
⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢀⣴⣿⠁⢋⡙⠁⠀⡝⠀⠀⠀⠀⣀⡸⠋⠁⠀⠀⠹⡀⠀⠈⠈⠆⢹⢦⡀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀
⠀⠀⠀⠀⠀⠀⠀⠀⢀⣠⣤⣿⣁⡡⣴⡏⠀⠀⠀⢀⠀⢧⣀⠄⠀⠀⠀⣀⣰⠆⢀⠁⠀⠀⢈⣶⡤⣀⢹⣦⣄⡀⠀⠀⠀⠀⠀⠀⠀⠀
⠀⠀⠀⠀⠀⠀⣠⢴⠟⢁⡝⠀⠁⠀⠃⠉⠀⠀⠘⣯⠀⡀⠾⣤⣄⣠⢤⠾⠄⠀⣸⠖⠀⠀⠈⠀⠃⠀⠀⠹⡄⠙⣶⢤⡀⠀⠀⠀⠀⠀
⠀⠀⠀⠀⣠⠾⡇⠈⣀⡞⠀⠀⠀⠀⡀⠀⢀⣠⣄⣇⠀⣳⠴⠃⠀⠀⠀⠣⢴⠉⣰⣇⣀⣀⠀⠀⡄⠀⠀⠀⢹⣄⡘⠈⡷⣦⠀⠀⠀⠀
⠀⢠⠞⠉⢻⡄⠀⠀⠈⠙⠀⠀⠀⠀⠙⣶⣏⣤⣤⠟⠉⠁⠀⠀⠀⠀⠀⠀⠀⠉⠙⢦⣱⣌⣷⠊⠀⠀⠀⠀⠈⠁⠀⠀⠀⡝⠉⠻⣄⠀
⣴⠛⢀⡠⢼⡇⠀⠀⢀⡄⠀⢀⣀⡽⠚⠁⠀⠀⠀⢠⡀⢠⣀⠠⣔⢁⡀⠀⣄⠀⡄⠀⠀⠀⠈⠑⠺⣄⡀⠀⠠⡀⠀⠀⢠⡧⠄⠀⠘⢧
⣿⡶⠋⠀⠀⠈⣠⣈⣩⠗⠒⠋⠀⠀⠀⠀⣀⣠⣆⡼⣷⣞⠛⠻⡉⠉⡟⠒⡛⣶⠧⣀⣀⣀⠀⠀⠀⠀⠈⠓⠺⢏⣉⣠⠋⠀⠀⠀⢢⣸
⣿⠇⠐⠤⠤⠖⠁⣿⣀⣀⠀⠀⠀⠀⠀⠉⠁⠈⠉⠙⠛⢿⣷⡄⢣⡼⠀⣾⣿⠧⠒⠓⠚⠛⠉⠀⠀⠀⠀⠀⢀⣀⣾⡉⠓⠤⡤⠄⠸⢿
⠹⣆⣤⠀⠀⠠⠀⠈⠓⠈⠓⠤⡀⠀⠀⠀⠀⠀⠀⠀⠀⠈⣿⣿⢸⠀⢸⣿⠇⠀⠀⠀⠀⠀⠀⠀⠀⢀⡤⠒⠁⠰⠃⠀⠠⠀⠀⢀⣀⠞
⠀⠀⠉⠓⢲⣄⡈⢀⣠⠀⠀⠀⡸⠶⠂⠀⠀⢀⠀⠀⠤⠞⢻⡇⠀⠀⢘⡟⠑⠤⠄⠀⢀⠀⠀⠐⠲⢿⡀⠀⠀⢤⣀⢈⣀⡴⠖⠋⠀⠀
⠀⠀⠀⠀⠀⠈⠉⠉⠙⠓⠒⣾⣁⣀⣴⠀⣀⠙⢧⠂⢀⣆⣀⣷⣤⣀⣾⣇⣀⡆⠀⢢⠛⢁⠀⢰⣀⣀⣹⠒⠒⠛⠉⠉⠉⠀⠀⠀⠀⠀
⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠉⠁⠈⠉⠉⠛⠉⠙⠉⠀⠀⣿⡟⣿⣿⠀⠀⠈⠉⠉⠙⠋⠉⠉⠀⠉⠁⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀
⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⣿⡇⢻⣿⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀
⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⣀⣤⣶⣾⣿⣿⠁⠀⢹⡛⣟⡶⢤⣀⡀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀
⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⣴⠛⢯⣽⡟⢿⣿⠛⠿⠳⠞⠻⣿⠻⣆⢽⠟⣶⡀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀
⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠛⠃⠲⠯⠴⣦⣼⣷⣤⣤⣶⣤⣩⡧⠽⠷⠐⠛⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀
⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢀⣿⡇⠀⣿⡆⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀
⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢀⣀⣄⡀⢀⣀⣠⡾⡿⢡⢐⠻⣿⣄⣀⡀⠀⣀⣄⡀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀
⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢀⣤⢴⡏⠁⠀⠝⠉⣡⠟⣰⠃⢸⣿⠀⣷⠙⢧⡉⠻⡅⠀⠙⡷⢤⣀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀
⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢀⣴⡟⠀⠈⣿⢄⡴⠞⠻⣄⣰⣡⠤⣞⣸⡤⢬⣧⣀⡿⠛⠦⣤⣶⡃⠀⢹⣦⡀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀
⠀⠀⠀⠀⠀⠀⠀⢀⣴⣶⡿⠃⠉⢺⠁⠙⠒⠀⠀⣠⡉⠀⠉⠚⠉⠉⠑⠈⠀⠈⣧⠀⠀⠒⠋⠀⡹⠋⠀⢻⡶⠶⡄⠀⠀⠀⠀⠀⠀⠀
⠀⠀⠀⠀⠀⠀⣠⣾⣿⣇⠁⢈⡦⠀⡍⠋⠁⡀⠸⡋⠀⠀⠀⢘⠏⠉⡏⠀⠀⠀⢉⡷⠀⡌⠉⠋⡇⠠⣏⠈⢁⣦⣿⣦⠀⠀⠀⠀⠀⠀
⠀⠀⠀⠀⠀⠀⠉⣁⠀⠉⠉⠉⠙⠛⠛⠒⠚⠳⠤⢼⣤⣠⠤⣮⣠⣤⣼⠦⢤⣤⣿⠤⠾⠓⠒⠛⢓⠛⠉⠉⠉⠀⠈⠉⠀⠀⠀⠀⠀⠀
ASCII
)

BORDER_MENU=$(cat <<'BORDER'

    ⣿⣿⣿⠟⡇
    ⡇⡿⠃⣰⡇
    ⡇⢁⣼⣿⡇
    ⡇⣾⣿⡟⡇
    ⡇⡿⠋⣠⡇
    ⣿⢡⣾⣿⡇
    ⣿⣿⣿⠟⡇
    ⣿⡿⠁⣠⡇
    ⣿⣠⣾⣿⡇
    ⡟⣿⣿⠏⡇
    ⡇⠟⢁⣴⡇
    ⠧⣰⣿⡿⡇
    ⠧⣰⣿⡿⡇
    ⡇⣿⣿⠏⡁
    ⡇⡿⠃⣰⡇
    ⡇⢁⣼⣿⡇
    ⡇⣾⣿⡟⡇
    ⡇⡿⠋⣠⡇
    ⣿⢡⣾⣿⡇
    ⣿⣿⣿⠟⡇
    ⣿⡿⠁⣠⡇
    ⣿⣠⣾⣿⡇
    ⡟⣿⣿⠏⡇
    ⡇⠟⢁⣴⡇
    ⠧⣰⣿⡿⡇
BORDER
)


# ---------------------------------------------------------------------------
# Shared NUKE brand header (logo). Shown on the main menu and every sub-menu so
# the toolkit identity stays visible throughout.
# ---------------------------------------------------------------------------
_NUKE_LOGO=(
    ' _____  ___       ____  ____      __   ___       _______  '
    '(\"   \|"  \     ("  _||_ " |    |/"| /  ")     /"     "| '
    '|.\\   \    |    |   (  ) : |    (: |/   /     (: ______) '
    '|: \.   \\  |    (:  |  | . )    |    __/       \/    |   '
    '|.  \    \. |     \\ \__/ //     (// _  \       // ___)_  '
    '|    \    \ |     /\\ __ //\     |: | \  \     (:      "| '
    ' \___|\____\)    (__________)    (__|  \__)     \_______) '
)

# Logo lines with a vertical all-yellow gradient (pale -> deep yellow).
# Backslashes are doubled because the renderer prints lines through %b.
# Falls back to plain YELLOW without truecolor, and to no color at all when
# colors are off.
_nuke_logo_lines() {
    local n=${#_NUKE_LOGO[@]} i color line
    for (( i = 0; i < n; i++ )); do
        color=""
        if [[ -n "${RESET}" && -n "${NUKE_NO_TRUECOLOR:-}" ]]; then
            color="${YELLOW}"
        elif [[ -n "${RESET}" ]]; then
            # 255,245,140 -> 255,195,0
            printf -v color '\033[38;2;255;%d;%dm' \
                $(( 245 - 50 * i / (n - 1) )) $(( 140 - 140 * i / (n - 1) ))
        fi
        line="${_NUKE_LOGO[i]}"
        printf '%s%s%s\n' "${color}${BOLD}" "${line//\\/\\\\}" "${RESET}"
    done
}

mapfile -t NUKE_BRAND_HEADER < <(_nuke_logo_lines)
# Hazard-tape warning under the logo.
NUKE_BRAND_HEADER+=(
    ""
    "${BOLD}${BRIGHT_RED}WARNING${RESET} ${BRIGHT_RED}Live ordnance. Authorized targets only.${RESET}"
    ""
)

# Two-column menu row: "[ln]  ltext        [rn]  rtext".
# The number sits in a fixed-width slot so names start at the same column
# whether the key is 1, 2 or 3 characters ([4], [10], [99], [r]). The left cell
# is then padded on its VISIBLE width so the right column always lines up and
# colors never break alignment. Pass an empty rn to render a single left cell.
_NUKE_KEY_W=4    # visible width reserved for the "[n]" slot (fits up to [99])
_NUKE_CELL_W=24  # visible width of the left cell (>= longest label + gap)

# Emit one colored "[key]" + padding so the text after it starts at _NUKE_KEY_W.
_menu_key() {
    local key="$1"
    local slot=$(( _NUKE_KEY_W - ${#key} - 2 ))   # 2 = the two brackets
    (( slot < 0 )) && slot=0
    printf '%b[%s]%b%*s' "${BRIGHT_RED}" "${key}" "${RESET}" "${slot}" ""
}

_menu_row2() {
    local ln="$1" lt="$2" rn="$3" rt="$4"
    # Visible left content = key slot + 2-space gap + label.
    local lvis=$(( _NUKE_KEY_W + 2 + ${#lt} ))
    local pad=$(( _NUKE_CELL_W - lvis ))
    (( pad < 0 )) && pad=0
    printf '%s  %s%*s' "$(_menu_key "${ln}")" "${lt}" "${pad}" ""
    [[ -n "${rn}" ]] && printf '%s  %s' "$(_menu_key "${rn}")" "${rt}"
}

# ---------------------------------------------------------------------------
# Open an action screen: clear, draw the brand banner and a section title.
# Every action/prompt calls this first so sub-views stay consistent with the
# menus and the input always sits right under its own titled screen.
# ---------------------------------------------------------------------------
nuke_subview() {
    local title="$1"
    clear
    local -a lines=( "${NUKE_BRAND_HEADER[@]}" )
    [[ -n "${title}" ]] && lines+=( "${BOLD}${BRIGHT_RED}${title}${RESET}" "" )
    render_banner_with_lines "${lines[@]}"
}

# Styled, indented prompt line used across sub-views for consistency.
nuke_prompt() {
    printf '   %b▪ %s : %b' "${BOLD}${BRIGHT_RED}" "$1" "${RESET}"
}

# Full menu screen for choice-style views (session picker, switch, continue):
# banner on the left, the given option lines in the right column, cursor left at
# a prompt. Keeps these screens aligned with the main menus instead of printing
# plain left-aligned text.
#   nuke_menu_screen <title> <prompt> <line>...
nuke_menu_screen() {
    local title="$1" prompt="$2"
    shift 2
    clear
    local -a box
    mapfile -t box < <(nuke_menu_box "${title}" "$@")
    render_banner_with_lines "${NUKE_BRAND_HEADER[@]}" "${box[@]}"
    nuke_prompt "${prompt}"
}

# Repeat "─" n times.
_nuke_hbar() {
    local bar
    printf -v bar '%*s' "$1" ''
    printf '%s' "${bar// /─}"
}

# Wrap the given lines in a thin box (red edges, yellow corners), one output
# line per row, padded to the widest visible line. A smaller tab holding the
# title is attached to the box: top-left with -t, bottom-right with -b. Feed
# the result to nuke_menu_screen / render_banner_with_lines.
#   mapfile -t boxed < <(nuke_box_lines [-t|-b title] <line>...)
nuke_box_lines() {
    local title="" pos=""
    if [[ "${1:-}" == "-t" || "${1:-}" == "-b" ]]; then
        pos="$1"
        title="$2"
        shift 2
    fi
    local w=0 line raw
    for line in "$@"; do
        raw=$(printf '%b' "${line}" | _strip_ansi)
        (( ${#raw} > w )) && w=${#raw}
    done
    local tw=$(( ${#title} + 2 ))
    [[ -n "${title}" ]] && (( tw > w + 2 )) && w=$(( tw - 2 ))
    local Y="${YELLOW}" R="${BRIGHT_RED}" Z="${RESET}"
    local tab_row
    printf -v tab_row '%b│%b %b%s%b %b│%b' "${R}" "${Z}" "${BOLD}${Y}" "${title}" "${Z}" "${R}" "${Z}"

    if [[ "${pos}" == "-t" ]]; then
        printf '%b┌%b%s%b┐%b\n' "${Y}" "${R}" "$(_nuke_hbar "${tw}")" "${Y}" "${Z}"
        printf '%s\n' "${tab_row}"
        if (( tw == w + 2 )); then
            printf '%b├%b%s%b┤%b\n' "${Y}" "${R}" "$(_nuke_hbar "${tw}")" "${Y}" "${Z}"
        else
            printf '%b├%b%s┴%s%b┐%b\n' "${Y}" "${R}" "$(_nuke_hbar "${tw}")" \
                "$(_nuke_hbar $(( w + 1 - tw )))" "${Y}" "${Z}"
        fi
    else
        printf '%b┌%b%s%b┐%b\n' "${Y}" "${R}" "$(_nuke_hbar $(( w + 2 )))" "${Y}" "${Z}"
    fi
    for line in "$@"; do
        raw=$(printf '%b' "${line}" | _strip_ansi)
        printf '%b│%b %b%*s %b│%b\n' "${R}" "${Z}" "${line}" \
            $(( w - ${#raw} )) '' "${R}" "${Z}"
    done
    if [[ "${pos}" == "-b" ]]; then
        local indent=$(( w + 2 - tw ))
        if (( indent == 0 )); then
            printf '%b├%b%s%b┤%b\n' "${Y}" "${R}" "$(_nuke_hbar "${tw}")" "${Y}" "${Z}"
        else
            printf '%b└%b%s┬%s%b┤%b\n' "${Y}" "${R}" "$(_nuke_hbar $(( indent - 1 )))" \
                "$(_nuke_hbar "${tw}")" "${Y}" "${Z}"
        fi
        printf '%*s%s\n' "${indent}" '' "${tab_row}"
        printf '%*s%b└%b%s%b┘%b\n' "${indent}" '' "${Y}" "${R}" "$(_nuke_hbar "${tw}")" "${Y}" "${Z}"
    else
        printf '%b└%b%s%b┘%b\n' "${Y}" "${R}" "$(_nuke_hbar $(( w + 2 )))" "${Y}" "${Z}"
    fi
}

# Standard menu frame: the options boxed under a title tab, with a blank row
# above and below. Every menu goes through this so they all look the same.
#   nuke_menu_box <title> <line>...
nuke_menu_box() {
    local title="$1"
    shift
    local -a box status panel
    mapfile -t box < <(nuke_box_lines -t "${title}" "" "$@" "")
    mapfile -t status < <(_nuke_status_lines)
    mapfile -t panel < <(nuke_box_lines -b "Nuke Status" "${status[@]}")
    _nuke_join_columns box panel
}

# Visible columns left for the menu column, right of the art and its border
# drawn by render_banner_with_lines.
_nuke_menu_col_room() {
    local art_w=0 bor_w=0 line cols
    while IFS= read -r line; do (( ${#line} > art_w )) && art_w=${#line}; done <<< "${NUKE_ASCII_ART}"
    while IFS= read -r line; do (( ${#line} > bor_w )) && bor_w=${#line}; done <<< "${BORDER_MENU}"
    cols=$(tput cols 2>/dev/null || echo 80)
    printf '%d' $(( cols - (3 + art_w + 1 + bor_w + 4) ))
}

# Cut a value to n visible chars, ending with "…" when it was longer.
_nuke_clip() {
    local v="$1" n="$2"
    (( ${#v} > n )) && v="${v:0:n-1}…"
    printf '%s' "${v}"
}

# Lines of the side status panel: where the session points, then which chaos
# tools are on PATH (green dot present, dim dot missing). Kept cheap: it is
# rebuilt on every menu draw.
_nuke_status_lines() {
    local ctx="none"
    command -v kubectl >/dev/null 2>&1 \
        && ctx="$(kubectl config current-context 2>/dev/null || true)"

    local defcon color
    defcon="$(nuke_defcon)"
    case "${defcon}" in
        5|4) color="${GREEN}" ;;
        3)   color="${YELLOW}" ;;
        2)   color="${BOLD}${BRIGHT_RED}" ;;
        *)   color="${BOLD}${BRIGHT_RED}"
             [[ -n "${RESET}" ]] && color+=$'\033[5m' ;;   # blink at DEFCON 1
    esac

    local payload="${DIM}none${RESET}"
    [[ -n "${NUKE_LEVEL:-}" ]] && payload="$(nuke_level_label "${NUKE_LEVEL}")"

    # Ready when the Ctrl+C trap that heals everything is armed.
    local rollback="${DIM}OFF${RESET}"
    [[ "$(trap -p INT)" == *nuke_panic* ]] && rollback="${GREEN}READY${RESET}"
    (( ${#NUKE_ROLLBACK_STACK[@]} > 0 )) \
        && rollback="${YELLOW}PENDING ${#NUKE_ROLLBACK_STACK[@]}${RESET}"

    local -a out=(
        "${DIM}DEFCON${RESET}    ${color}${defcon}${RESET}"
        "${DIM}SESSION${RESET}   ${BRIGHT_RED}$(_nuke_clip "${NUKE_SESSION_NAME:-Not set}" 16)${RESET}"
        "${DIM}TARGET${RESET}    ${BRIGHT_RED}$(_nuke_clip "${NUKE_SCOPE:-Not set}" 16)${RESET}"
        "${DIM}PAYLOAD${RESET}   ${payload}"
        "${DIM}ROLLBACK${RESET}  ${rollback}"
        "${DIM}CONTEXT${RESET}   $(_nuke_clip "${ctx:-none}" 16)"
        "${DIM}HOST${RESET}      $(_nuke_clip "$(uname -n)" 16)"
        "${DIM}TIME${RESET}      $(date +%H:%M)"
        ""
    )
    # Tools two per row to keep the panel short.
    local t cell row="" n=0
    for t in kubectl docker helm tc stress-ng; do
        if command -v "${t}" >/dev/null 2>&1; then
            printf -v cell '%b●%b %-10s' "${GREEN}" "${RESET}" "${t}"
        else
            printf -v cell '%b○ %-10s%b' "${DIM}" "${t}" "${RESET}"
        fi
        row+="${cell}"
        (( ++n % 2 == 0 )) && { out+=( "${row% }" ); row=""; }
    done
    [[ -n "${row}" ]] && out+=( "${row}" )
    printf '%s\n' "${out[@]}"
}

# Print two boxes side by side (names of two arrays). The right one is dropped
# when the terminal is too narrow to fit both beside the art and its border.
_nuke_join_columns() {
    local -n _left="$1" _right="$2"
    # Widest row of each box (the box rows, not the shorter title tab).
    local lw rw raw
    raw=$(printf '%b' "${_left[-1]}" | _strip_ansi);  lw=${#raw}
    raw=$(printf '%b' "${_right[-1]}" | _strip_ansi); rw=${#raw}

    if (( lw + 2 + rw > $(_nuke_menu_col_room) )); then
        printf '%s\n' "${_left[@]}"
        return 0
    fi

    local n=$(( ${#_left[@]} > ${#_right[@]} ? ${#_left[@]} : ${#_right[@]} ))
    local i l
    for (( i = 0; i < n; i++ )); do
        l="${_left[i]:-}"
        raw=$(printf '%b' "${l}" | _strip_ansi)
        printf '%s%*s  %s\n' "${l}" $(( lw - ${#raw} )) '' "${_right[i]:-}"
    done
}

# Placeholder for a fault whose logic is not wired yet. Honest by design: it
# names the tool and the effect it will have, shows the chosen intensity, and
# states plainly that nothing is executed. Layers that ship only the menu and
# safety scaffold (Docker / Network / Host) use this for each fault.
#   nuke_fault_stub <label> <tool> <effect> [level]
nuke_fault_stub() {
    local label="$1" tool="$2" effect="$3" level="${4:-}"
    local title="${label}"
    [[ -n "${level}" ]] && title="${label} @ $(nuke_level_label "${level}")"
    nuke_subview "${title}"
    printf '   %bScope%b   : %s\n'  "${DIM}" "${RESET}" "${NUKE_SCOPE:-Not set}"
    printf '   %bTool%b    : %s\n'  "${DIM}" "${RESET}" "${tool}"
    printf '   %bEffect%b  : %s\n\n' "${DIM}" "${RESET}" "${effect}"
    printf '   %bNot wired yet.%b This layer ships the menu and the safety\n' "${YELLOW}" "${RESET}"
    printf '   scaffold; the fault logic lands next per the roadmap.\n'
    press_enter_to_continue
}

# ---------------------------------------------------------------------------
# Menu generators. Each prints its lines on stdout, one per line.
# The sub-action labels below are placeholders — rename them per module.
# ---------------------------------------------------------------------------
generate_main_menu() {
    local -a menu_lines=(
        "${NUKE_BRAND_HEADER[@]}"
    )
    mapfile -t -O "${#menu_lines[@]}" menu_lines < <(nuke_menu_box "Nuke Main Menu" \
        "${BRIGHT_RED}[1]${RESET}  Configuration" \
        "" \
        "${BRIGHT_RED}[2]${RESET}  Kubernetes   ${GREEN}ready${RESET}" \
        "${BRIGHT_RED}[3]${RESET}  Docker       ${YELLOW}beta${RESET}" \
        "${BRIGHT_RED}[4]${RESET}  Network      ${YELLOW}beta${RESET}" \
        "${BRIGHT_RED}[5]${RESET}  Host         ${YELLOW}beta${RESET}" \
        "" \
        "${BRIGHT_RED}[0]${RESET}  Exit")
    printf '%s\n' "${menu_lines[@]}"
}


generate_config_menu() {
    local -a menu_lines=(
        "${NUKE_BRAND_HEADER[@]}"
        "Output : ${BRIGHT_RED}${NUKE_OUTPUT_DIR}${RESET}"
        ""
    )
    mapfile -t -O "${#menu_lines[@]}" menu_lines < <(nuke_menu_box "Nuke Configuration" \
        "${BRIGHT_RED}[1]${RESET}  Switch / new session" \
        "${BRIGHT_RED}[2]${RESET}  Rename this session" \
        "${BRIGHT_RED}[3]${RESET}  Set output directory" \
        "${BRIGHT_RED}[4]${RESET}  Detect environment (installed tools)" \
        "" \
        "${BRIGHT_RED}[0]${RESET}  Back to Main Menu")
    printf '%s\n' "${menu_lines[@]}"
}

generate_kubernetes_menu() {
    local -a menu_lines=(
        "${NUKE_BRAND_HEADER[@]}"
    )
    mapfile -t -O "${#menu_lines[@]}" menu_lines < <(nuke_menu_box "Nuke Kubernetes" \
        "$(_menu_row2 1 "Pod-kill"      2  "Pod-failure")" \
        "$(_menu_row2 3 "Net delay"     4  "Net loss")" \
        "$(_menu_row2 5 "Net partition" 6  "Stress CPU")" \
        "$(_menu_row2 7 "Stress memory" 8  "DNS chaos")" \
        "$(_menu_row2 9 "Time skew"     10 "Node drain")" \
        "" \
        "$(_menu_row2 99 "NUKE k8s" r "Recover")" \
        "" \
        "${BRIGHT_RED}[0]${RESET}   Back to Main Menu")
    printf '%s\n' "${menu_lines[@]}"
}

# Shared layout for the beta layers (Docker / Network / Host): a scope line, a
# hint, a two-column fault grid, then NUKE / back. Callers pass their own rows.
_generate_beta_layer_menu() {
    local title="$1" scope="$2" hint="$3"
    shift 3
    local -a rows=( "$@" )
    local short="${title% LAYER}"
    local -a menu_lines=(
        "${NUKE_BRAND_HEADER[@]}"
        "${YELLOW}${hint}${RESET}"
        ""
    )
    local tab="${short,,}"
    mapfile -t -O "${#menu_lines[@]}" menu_lines < <(nuke_menu_box "Nuke ${tab^}" \
        "$(_menu_row2 1 "Set scope" 2 "Status")" \
        "" \
        "${rows[@]}" \
        "" \
        "$(_menu_row2 99 "NUKE ${short,,}" "" "")" \
        "" \
        "${BRIGHT_RED}[0]${RESET}   Back to Main Menu")
    printf '%s\n' "${menu_lines[@]}"
}

generate_docker_menu() {
    _generate_beta_layer_menu "DOCKER LAYER" "${NUKE_SCOPE:-}" \
        "Set a container scope, then pick a fault." \
        "$(_menu_row2 3 "Pause"     4 "Stop")" \
        "$(_menu_row2 5 "Kill"      6 "Net delay")" \
        "$(_menu_row2 7 "Net loss"  8 "Stress")"
}

generate_network_menu() {
    _generate_beta_layer_menu "NETWORK LAYER" "${NUKE_SCOPE:-}" \
        "Set an interface scope, then pick a fault." \
        "$(_menu_row2 3 "Latency"   4 "Loss")" \
        "$(_menu_row2 5 "Throttle"  6 "Corrupt")" \
        "$(_menu_row2 7 "Blackhole" "" "")"
}

generate_host_menu() {
    _generate_beta_layer_menu "HOST LAYER" "${NUKE_SCOPE:-}" \
        "Confirm the hostname to scope, then pick a fault." \
        "$(_menu_row2 3 "CPU stress" 4 "Memory stress")" \
        "$(_menu_row2 5 "IO stress"  6 "Disk fill")" \
        "$(_menu_row2 7 "Clock skew" "" "")"
}


# ---------------------------------------------------------------------------
# Splash screen displayed when the toolkit boots.
# ---------------------------------------------------------------------------
_strip_ansi() {
    LC_ALL=C sed -E 's/\x1B\[[0-9;?]*[ -/]*[@-~]//g; s/\x1B\][^\a]*\a//g; s/\x1B[()][0-9A-Za-z]//g'
}

# ---------------------------------------------------------------------------
# Vertical fire gradient for the ASCII art.
# Interpolates yellow -> orange -> red across the art's lines using truecolor
# SGR escapes. Emits the escape for line index $1 of a total of $2 lines.
# Emits nothing when colors are disabled (piped / non-TTY, RESET is empty).
# Truecolor is attempted by default (most modern terminals support 24-bit even
# without exporting COLORTERM). Set NUKE_NO_TRUECOLOR=1 to force solid
# BRIGHT_RED on a terminal that only does 8/256 colors.
# Stops (R G B): 255,230,0  ->  255,120,0  ->  200,0,0
# ---------------------------------------------------------------------------
_gradient_escape() {
    local i="$1" n="$2"
    [[ -z "${RESET}" ]] && return 0
    if [[ -n "${NUKE_NO_TRUECOLOR:-}" ]]; then
        printf '%s' "${BRIGHT_RED}"
        return 0
    fi
    (( n <= 1 )) && n=2

    # Fixed-point position t in 0..1000 over the whole art.
    local t=$(( i * 1000 / (n - 1) ))
    (( t > 1000 )) && t=1000
    local r g b u
    if (( t <= 500 )); then
        u=$(( t * 2 ))                       # 0..1000 within yellow -> orange
        r=255
        g=$(( 230 + (120 - 230) * u / 1000 ))
        b=0
    else
        u=$(( (t - 500) * 2 ))               # 0..1000 within orange -> red
        r=$(( 255 + (200 - 255) * u / 1000 ))
        g=$(( 120 + (0   - 120) * u / 1000 ))
        b=0
    fi
    printf '\033[38;2;%d;%d;%dm' "$r" "$g" "$b"
}

display_title_middle_screen() {
    local cols rows
    cols=$(tput cols 2>/dev/null || echo 80)
    rows=$(tput lines 2>/dev/null || echo 24)

    local -a art_lines
    mapfile -t art_lines <<< "$NUKE_ASCII_ART"
    local art_count=${#art_lines[@]}

    # Subtitle shown under the art.
    local subtitle="Toolkit made by Melvin PETIT / WhiteMuush"

    # Widest visible line (art chars are single width; subtitle counts too).
    local max_w=0 raw visible_len line
    for line in "${art_lines[@]}" "$subtitle"; do
        raw=$(printf "%s" "$line" | _strip_ansi)
        visible_len=${#raw}
        (( visible_len > max_w )) && max_w=$visible_len
    done

    # Total block height: art + blank line + subtitle.
    local h=$(( art_count + 2 ))
    local top=$(( (rows - h) / 2 ))
    (( top < 0 )) && top=0
    local left=$(( (cols - max_w) / 2 ))
    (( left < 0 )) && left=0

    printf "\033c"
    local i
    for ((i=0; i<top; i++)); do
        printf "\n"
    done

    # Art with the same vertical fire gradient as the menu banner.
    local grad
    for ((i=0; i<art_count; i++)); do
        grad=$(_gradient_escape "$i" "$art_count")
        printf "%*s%b%s%b\n" "$left" "" "$grad" "${art_lines[i]}" "${RESET}"
    done

    printf "\n"

    # Subtitle centered under the art.
    local sub_pad=$(( (cols - ${#subtitle}) / 2 ))
    (( sub_pad < 0 )) && sub_pad=0
    printf "%*s%b%s%b\n" "$sub_pad" "" "${BOLD}${BRIGHT_RED}" "$subtitle" "${RESET}"
}

# ---------------------------------------------------------------------------
# Launch countdown: one huge digit per second, centered on a cleared screen,
# with the same yellow -> red fire gradient as the art.
# ---------------------------------------------------------------------------

# 5x5 glyphs, scaled x2 on render. One string per digit, rows split by "|".
_NUKE_DIGITS=(
    "#####|#   #|#   #|#   #|#####"
    "  #  | ##  |  #  |  #  | ### "
    "#####|    #|#####|#    |#####"
    "#####|    #| ####|    #|#####"
    "#   #|#   #|#####|    #|    #"
    "#####|#    |#####|    #|#####"
    "#####|#    |#####|#   #|#####"
    "#####|    #|   # |  #  |  #  "
    "#####|#   #|#####|#   #|#####"
    "#####|#   #|#####|    #|#####"
)

# _nuke_big_digit <0-9> — the digit scaled x2 both ways, one row per line.
_nuke_big_digit() {
    local d="$1"
    [[ "${d}" =~ ^[0-9]$ ]] || return 1
    local -a rows
    IFS='|' read -r -a rows <<< "${_NUKE_DIGITS[d]}"
    local row out c i
    for row in "${rows[@]}"; do
        out=""
        for (( i = 0; i < ${#row}; i++ )); do
            c="${row:i:1}"
            [[ "${c}" == "#" ]] && out+="████" || out+="    "
        done
        printf '%s\n%s\n' "${out}" "${out}"
    done
}

# nuke_countdown [seconds] — full-screen T-minus before a detonation. Ctrl+C
# aborts the launch (returns 1) instead of quitting Nuke. Skipped (returns 0)
# off a terminal, or with NUKE_COUNTDOWN=0; NUKE_COUNTDOWN sets the default.
nuke_countdown() {
    local secs="${1:-${NUKE_COUNTDOWN:-5}}"
    [[ -t 1 ]] || return 0
    (( secs > 0 )) || return 0
    (( secs > 9 )) && secs=9

    local aborted=0 prev_trap
    prev_trap="$(trap -p INT)"
    trap 'aborted=1' INT

    local cols rows n
    cols=$(tput cols 2>/dev/null || echo 80)
    rows=$(tput lines 2>/dev/null || echo 24)
    local -a digit
    for (( n = secs; n >= 1 && ! aborted; n-- )); do
        mapfile -t digit < <(_nuke_big_digit "${n}")
        local h=$(( ${#digit[@]} + 4 ))
        local w=${#digit[0]}
        local top=$(( (rows - h) / 2 )) left=$(( (cols - w) / 2 ))
        (( top < 0 )) && top=0
        (( left < 0 )) && left=0
        clear
        printf '%*s' "${top}" '' | tr ' ' '\n'
        local i
        for (( i = 0; i < ${#digit[@]}; i++ )); do
            printf '%*s%b%s%b\n' "${left}" '' "$(_gradient_escape "${i}" "${#digit[@]}")" \
                "${digit[i]}" "${RESET}"
        done
        local caption="T-${n}  LAUNCH SEQUENCE ENGAGED"
        local hint="Ctrl+C to abort"
        printf '\n%*s%b%s%b\n' $(( (cols - ${#caption}) / 2 )) '' "${BOLD}${BRIGHT_RED}" "${caption}" "${RESET}"
        printf '%*s%b%s%b\n' $(( (cols - ${#hint}) / 2 )) '' "${DIM}" "${hint}" "${RESET}"
        sleep 1
    done

    if [[ -n "${prev_trap}" ]]; then eval "${prev_trap}"; else trap - INT; fi
    if (( aborted )); then
        printf '\n'
        log_info "Launch aborted. No chaos launched."
        return 1
    fi
    return 0
}

# ---------------------------------------------------------------------------
# Core renderer: draw the given right-column lines beside the skull art and the
# yellow border. Every screen (menus and action sub-views) goes through this so
# they all share the same look. Pass the right-column lines as arguments.
# ---------------------------------------------------------------------------
render_banner_with_lines() {
    local -a menu_lines=( "$@" )
    local -a ascii_lines border_lines

    mapfile -t ascii_lines <<< "$NUKE_ASCII_ART"
    mapfile -t border_lines <<< "$BORDER_MENU"

    local ascii_count=${#ascii_lines[@]}
    local menu_count=${#menu_lines[@]}
    local max_lines=$(( ascii_count > menu_count ? ascii_count : menu_count ))

    local max_ascii_width=0 line
    for line in "${ascii_lines[@]}"; do
        (( ${#line} > max_ascii_width )) && max_ascii_width=${#line}
    done

    # Cycle the border glyphs so the border always spans the full content
    # height; the menu can never extend past its left border.
    local -a border_glyphs=()
    for line in "${border_lines[@]}"; do
        [[ -n "${line// /}" ]] && border_glyphs+=( "$line" )
    done
    local nglyph=${#border_glyphs[@]}
    local max_border_width=0
    for line in "${border_glyphs[@]}"; do
        (( ${#line} > max_border_width )) && max_border_width=${#line}
    done

    # Border column: solid yellow (no gradient). Empty when colors are off,
    # falls back to the 8-color YELLOW when truecolor is disabled.
    local border_color=""
    if [[ -n "${RESET}" ]]; then
        if [[ -n "${NUKE_NO_TRUECOLOR:-}" ]]; then
            border_color="${YELLOW}"
        else
            border_color=$'\033[38;2;255;230;0m'
        fi
    fi

    local spacing="    "
    local i
    for ((i=0; i<max_lines; i++)); do
        local ascii_line="${ascii_lines[i]:-}"
        local menu_line="${menu_lines[i]:-}"

        local border_line=""
        (( nglyph > 0 )) && border_line="${border_glyphs[i % nglyph]}"

        local grad
        grad=$(_gradient_escape "$i" "$ascii_count")
        local colored_ascii="${grad}${ascii_line}${RESET}"
        local colored_border="${border_color}${border_line}${RESET}"
        local pad=$(( max_ascii_width - ${#ascii_line} ))
        (( pad < 0 )) && pad=0
        local bpad=$(( max_border_width - ${#border_line} ))
        (( bpad < 0 )) && bpad=0

        printf "   %b%*s %b%*s%s%b\n" \
            "$colored_ascii" \
            "$pad" "" \
            "$colored_border" \
            "$bpad" "" \
            "$spacing" \
            "$menu_line"
    done
    echo ""
    # Centered under the ASCII art (art is indented by 3 columns, width = max_ascii_width).
    local notice="Nuke only authorized targets !"
    local notice_pad=$(( 3 + (max_ascii_width - ${#notice}) / 2 ))
    (( notice_pad < 0 )) && notice_pad=0
    printf "%*s%b%s%b\n" "$notice_pad" "" "${BOLD}${BRIGHT_RED}" "$notice" "${RESET}"
    echo ""
}

# Render one of the named menus beside the banner.
display_banner_with_menu() {
    local menu_type="$1"
    local -a menu_lines
    case "$menu_type" in
        main)       mapfile -t menu_lines < <(generate_main_menu) ;;
        config)     mapfile -t menu_lines < <(generate_config_menu) ;;
        kubernetes) mapfile -t menu_lines < <(generate_kubernetes_menu) ;;
        docker)     mapfile -t menu_lines < <(generate_docker_menu) ;;
        network)    mapfile -t menu_lines < <(generate_network_menu) ;;
        host)       mapfile -t menu_lines < <(generate_host_menu) ;;
        *)
            log_error "Unknown menu type: ${menu_type}"
            return 1
            ;;
    esac
    render_banner_with_lines "${menu_lines[@]}"
}

# Prompt rendered under each submenu, left-aligned like the main menu prompt.
prompt_menu_choice() {
    local label="$1"
    echo -ne "   ${BOLD}${BRIGHT_RED}▪ ${label^^} // AWAITING ORDERS : ${RESET}"
}
