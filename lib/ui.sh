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
# Menu generators. Each prints its lines on stdout, one per line.
# The sub-action labels below are placeholders — rename them per module.
# ---------------------------------------------------------------------------
generate_main_menu() {
    local -a menu_lines=(
        ""
        "${BRIGHT_RED}▄▄▄    ▄▄▄   ▄▄▄  ▄▄▄   ▄▄▄   ▄▄▄    ▄▄▄▄▄▄▄      ▄▄▄ ${RESET}"
        "${BRIGHT_RED}████▄  ███   ███  ███   ███ ▄███▀   ███▀▀▀▀▀      ███ ${RESET}"
        "${BRIGHT_RED}███▀██▄███   ███  ███   ███████     ███▄▄         ███ ${RESET}"
        "${BRIGHT_RED}███  ▀████   ███▄▄███   ███▀███▄    ███           ▀▀▀ ${RESET}"
        "${BRIGHT_RED}███    ███   ▀██████▀   ███  ▀███   ▀███████      ███ ${RESET}"
        ""
        "${BRIGHT_RED}${BOLD}Server Stress & Resilience Toolkit ☢️${RESET}"
        ""
        "breaking point on purpose. Nuke generates heavy,"
        "controlled load, saturates connections and hammers"
        "endpoints to expose bottlenecks, timeouts and failure"
        "modes before real traffic does."
        ""
        "${BOLD}🚩 Detonate only on hosts you own or are cleared to test. ${RESET}"
        ""
        ""
        "${BRIGHT_RED}[1]${RESET}  Configuration"
        ""
        "${BRIGHT_RED}[2]${RESET}  Passive Module"
        ""
        "${BRIGHT_RED}[3]${RESET}  Active Module"
        ""
        "${BRIGHT_RED}[4]${RESET}  Special Module"
        ""
        "${BRIGHT_RED}[0]${RESET}  Exit"
    )
    printf '%s\n' "${menu_lines[@]}"
}


generate_config_menu() {
    local -a menu_lines=(
        "${BRIGHT_RED}${BOLD}CONFIGURATION${RESET}"
        ""
        "Target : ${BRIGHT_RED}${NUKE_TARGET:-Not set}${RESET}"
        "Output : ${BRIGHT_RED}${NUKE_OUTPUT_DIR}${RESET}"
        ""
        "${BRIGHT_RED}[1]${RESET}  Set Target (IP/Hostname)"
        "${BRIGHT_RED}[2]${RESET}  Set Output Directory"
        ""
        "${BRIGHT_RED}[0]${RESET}  Back to Main Menu"
    )
    printf '%s\n' "${menu_lines[@]}"
}

generate_passive_menu() {
    local -a menu_lines=(
        "${BRIGHT_RED}${BOLD}PASSIVE MODULE${RESET}"
        ""
        "Placeholder actions — wire your own tools here."
        ""
        "Target : ${BRIGHT_RED}${NUKE_TARGET:-Not set}${RESET}"
        ""
        "${BRIGHT_RED}[1]${RESET}  Action One"
        "${BRIGHT_RED}[2]${RESET}  Action Two"
        ""
        "${BRIGHT_RED}[0]${RESET}  Back to Main Menu"
    )
    printf '%s\n' "${menu_lines[@]}"
}

generate_active_menu() {
    local -a menu_lines=(
        "${BRIGHT_RED}${BOLD}ACTIVE MODULE${RESET}"
        ""
        "Placeholder actions — wire your own tools here."
        ""
        "Target : ${BRIGHT_RED}${NUKE_TARGET:-Not set}${RESET}"
        ""
        "${BRIGHT_RED}[1]${RESET}  Action One"
        "${BRIGHT_RED}[2]${RESET}  Action Two"
        ""
        "${BRIGHT_RED}[0]${RESET}  Back to Main Menu"
    )
    printf '%s\n' "${menu_lines[@]}"
}

generate_special_menu() {
    local -a menu_lines=(
        "${BRIGHT_RED}${BOLD}SPECIAL MODULE${RESET}"
        ""
        "Placeholder actions — wire your own tools here."
        ""
        "Target : ${BRIGHT_RED}${NUKE_TARGET:-Not set}${RESET}"
        ""
        "${BRIGHT_RED}[1]${RESET}  Action One"
        "${BRIGHT_RED}[2]${RESET}  View Results"
        ""
        "${BRIGHT_RED}[0]${RESET}  Back to Main Menu"
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
# Side-by-side rendering of the ASCII art and the active menu.
# ---------------------------------------------------------------------------
display_banner_with_menu() {
    local menu_type="$1"
    local -a ascii_lines menu_lines border_lines

    mapfile -t ascii_lines <<< "$NUKE_ASCII_ART"
    mapfile -t border_lines <<< "$BORDER_MENU"

    case "$menu_type" in
        main)    mapfile -t menu_lines < <(generate_main_menu) ;;
        config)  mapfile -t menu_lines < <(generate_config_menu) ;;
        passive) mapfile -t menu_lines < <(generate_passive_menu) ;;
        active)  mapfile -t menu_lines < <(generate_active_menu) ;;
        special) mapfile -t menu_lines < <(generate_special_menu) ;;
        *)
            log_error "Unknown menu type: ${menu_type}"
            return 1
            ;;
    esac

    local ascii_count=${#ascii_lines[@]}
    local menu_count=${#menu_lines[@]}
    local max_lines=$(( ascii_count > menu_count ? ascii_count : menu_count ))

    local max_ascii_width=0 line
    for line in "${ascii_lines[@]}"; do
        (( ${#line} > max_ascii_width )) && max_ascii_width=${#line}
    done

    local border_count=${#border_lines[@]}
    (( border_count > max_lines )) && max_lines=$border_count
    local max_border_width=0
    for line in "${border_lines[@]}"; do
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

        local border_line="${border_lines[i]:-}"

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

# Prompt rendered under each submenu. Hardcoded indent matches the menu layout.
prompt_menu_choice() {
    local label="$1"
    echo -ne "                                                 ${BOLD}${BRIGHT_RED}▪ ${label} : ${RESET}"
}
