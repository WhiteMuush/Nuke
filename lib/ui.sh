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
# Shared NUKE brand header. Shown on the main menu and every sub-menu so the
# toolkit identity and the safety warning stay visible throughout.
# ---------------------------------------------------------------------------
NUKE_BRAND_HEADER=(
    ""
    "${BRIGHT_RED}${BOLD}Chaos & Resilience Toolkit ☢️${RESET}"
    ""
    "${BOLD}🚩 Only detonate infra you own or are cleared to test. ${RESET}"
    ""
)

# ---------------------------------------------------------------------------
# Two-column menu row: "[ln]  ltext        [rn]  rtext".
# The left cell is padded on its VISIBLE width so colors never break alignment.
# Pass an empty rn to render a single left cell.
# ---------------------------------------------------------------------------
_menu_row2() {
    local ln="$1" lt="$2" rn="$3" rt="$4" width=22
    local lplain="[${ln}]  ${lt}"
    local pad=$(( width - ${#lplain} ))
    (( pad < 0 )) && pad=0
    printf '%b[%s]%b  %s%*s' "${BRIGHT_RED}" "${ln}" "${RESET}" "${lt}" "${pad}" ""
    [[ -n "${rn}" ]] && printf '%b[%s]%b  %s' "${BRIGHT_RED}" "${rn}" "${RESET}" "${rt}"
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

# ---------------------------------------------------------------------------
# Menu generators. Each prints its lines on stdout, one per line.
# The sub-action labels below are placeholders — rename them per module.
# ---------------------------------------------------------------------------
generate_main_menu() {
    local -a menu_lines=(
        "${NUKE_BRAND_HEADER[@]}"
        "Inject real failures into your infra and prove it survives."
        "Escalate from a gentle POKE to an all-out NUKE!, always"
        "scoped, always with automatic rollback."
        ""
        "${DIM}Pick a target layer:${RESET}"
        ""
        "${BRIGHT_RED}[1]${RESET}  Configuration"
        ""
        "${BRIGHT_RED}[2]${RESET}  Kubernetes   ${GREEN}ready${RESET}"
        "${BRIGHT_RED}[3]${RESET}  Docker       ${DIM}soon${RESET}"
        "${BRIGHT_RED}[4]${RESET}  Network      ${DIM}soon${RESET}"
        "${BRIGHT_RED}[5]${RESET}  Host         ${DIM}soon${RESET}"
        ""
        "${BRIGHT_RED}[0]${RESET}  Exit"
    )
    printf '%s\n' "${menu_lines[@]}"
}


generate_config_menu() {
    local -a menu_lines=(
        "${NUKE_BRAND_HEADER[@]}"
        "${BRIGHT_RED}${BOLD}CONFIGURATION${RESET}"
        ""
        "Output : ${BRIGHT_RED}${NUKE_OUTPUT_DIR}${RESET}"
        "Scope  : ${BRIGHT_RED}${NUKE_SCOPE:-Not set}${RESET}"
        ""
        "${DIM}Scope is set inside each layer (e.g. the k8s namespace).${RESET}"
        ""
        "${BRIGHT_RED}[1]${RESET}  Set output directory"
        "${BRIGHT_RED}[2]${RESET}  Detect environment (installed tools)"
        ""
        "${BRIGHT_RED}[0]${RESET}  Back to Main Menu"
    )
    printf '%s\n' "${menu_lines[@]}"
}

generate_kubernetes_menu() {
    local -a menu_lines=(
        "${NUKE_BRAND_HEADER[@]}"
        "${BRIGHT_RED}${BOLD}KUBERNETES LAYER${RESET}"
        ""
        "Namespace : ${BRIGHT_RED}${NUKE_K8S_NAMESPACE:-Not set}${RESET}"
        "Scope     : ${BRIGHT_RED}${NUKE_SCOPE:-Not set}${RESET}"
        ""
        "${DIM}Set scope, install Chaos Mesh, then fire a fault.${RESET}"
        ""
        "$(_menu_row2 1 "Set scope"        2  "Status")"
        "$(_menu_row2 3 "Setup Chaos Mesh" ""  "")"
        ""
        "${DIM}Faults (POKE -> NUKE!)${RESET}"
        "$(_menu_row2 4  "Pod-kill"         5  "Pod-failure")"
        "$(_menu_row2 6  "Net delay"        7  "Net loss")"
        "$(_menu_row2 8  "Net partition"    9  "Stress CPU")"
        "$(_menu_row2 10 "Stress memory"    11 "DNS chaos")"
        "$(_menu_row2 12 "Time skew"        13 "Node drain")"
        ""
        "$(_menu_row2 99 "NUKE k8s" r "Recover")"
        ""
        "${BRIGHT_RED}[0]${RESET}   Back to Main Menu"
    )
    printf '%s\n' "${menu_lines[@]}"
}


# ---------------------------------------------------------------------------
# Splash screen displayed when the toolkit boots.
# ---------------------------------------------------------------------------
_strip_ansi() {
    sed -E 's/\x1B\[[0-9;?]*[ -/]*[@-~]//g; s/\x1B\][^\a]*\a//g'
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
        *)
            log_error "Unknown menu type: ${menu_type}"
            return 1
            ;;
    esac
    render_banner_with_lines "${menu_lines[@]}"
}

# Prompt rendered under each submenu. Hardcoded indent matches the menu layout.
prompt_menu_choice() {
    local label="$1"
    echo -ne "                                                 ${BOLD}${BRIGHT_RED}▪ ${label} : ${RESET}"
}
