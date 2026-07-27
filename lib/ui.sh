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
⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢀⣠⢖⣠⣄⡀⠀⠀
⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⣀⣤⣾⣿⣿⠎⠀⠀⠹⡀⠀
⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢀⣤⣾⣿⣿⣿⣿⢿⣤⠴⠒⢦⡇⠀
⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢀⣠⣾⣿⣿⣿⣿⠿⠛⠁⠸⡇⠀⠀⠀⡇⠀
⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⣀⣴⣿⣿⣿⣿⠿⠋⠁⠀⠀⠀⠀⣧⠀⠀⠀⡇⠀
⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢀⣤⣶⣶⠂⠾⠿⣿⣿⡿⠛⠁⠀⠀⠀⠀⠀⠀⠀⣿⠀⠀⠀⢠⠀
⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⣴⣿⣿⣿⣿⣿⣷⣤⡀⠈⠉⠑⠒⠤⢀⡀⠀⠀⠀⠀⣿⠀⠀⠀⣼⠀
⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢀⣾⣿⣿⣿⠟⠿⠿⢿⣿⣿⣆⠀⠀⠀⠀⠀⠈⠑⢄⠀⠀⣿⠀⠀⠀⡏⠀
⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⣾⣿⣿⣿⡏⡄⠀⠀⠀⠈⠻⣿⣧⠀⠀⠀⠀⠀⠀⠀⢳⠀⣿⠀⠀⠀⡇⠀
⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢸⣿⣿⣿⣿⡀⣷⠄⠀⠀⠀⠀⠙⢿⣇⡀⠀⠀⠀⠀⠀⠀⣷⡇⠀⠀⢸⡇⠀
⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢀⣾⣿⣿⣿⡿⠐⣁⣀⣀⢀⣾⣤⢤⣶⣿⣿⣦⡀⠀⠀⠀⠀⢸⠇⠀⠀⡾⠀⠀
⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⣠⣿⣿⣿⣿⣿⣇⣾⣿⣿⣿⡇⠀⠻⣽⣿⣿⣿⡿⠿⣦⠀⠀⠀⡟⠀⠀⢰⠇⠀⠀
⠀⠀⠀⠀⠀⠀⠀⠀⠀⣼⣿⣿⣿⣿⣿⣿⡟⣌⡻⠛⠁⢰⠸⡔⣤⣉⡩⠐⠁⠀⢸⡇⠀⢰⠃⠀⠀⡎⠀⠀⠀
⠀⠀⠀⠀⠀⠀⠀⠀⣾⣿⣿⣿⣿⣿⣿⣿⣇⠀⠉⠀⠀⠀⠀⠀⠈⠙⠻⣶⢶⣶⣾⠇⢀⡏⠀⠀⠰⢣⠀⠀⠀
⠀⠀⠀⠀⠀⠀⠀⣼⣿⣿⢋⣿⣿⣿⣿⣿⣿⣿⣷⠀⠤⠒⠒⠓⠘⠀⢴⢏⡟⠈⣿⠀⡞⠀⠀⢀⡇⠀⠣⡀⠀
⠀⠀⠀⠀⠀⠀⣼⣿⡿⠁⣸⣿⣿⣿⣿⣿⣿⣿⣿⠀⡰⠞⠛⠛⠛⠳⠶⠿⠁⣰⣿⣼⠃⠀⠀⡼⢿⣶⡀⡇⠀
⠀⠀⠀⠀⠀⣼⣿⠟⠀⠀⣿⣿⣿⣿⣿⣿⣿⣿⣿⣄⣿⠟⠋⠉⠉⠁⠀⠀⢠⣿⣿⠃⠀⠀⠰⠁⠘⢿⠔⢀⣠
⠀⠀⠀⠀⣰⣿⡟⠀⠀⠀⠸⣿⣿⣿⣿⣿⣿⣿⣿⣏⠻⠖⠂⠈⠒⠂⢀⣠⣿⣿⠏⠀⠀⢀⣧⣶⡶⢖⣿⠇⡿
⠀⠀⠀⢠⣿⡟⠀⠀⠀⠀⠀⢻⣿⣿⣿⣿⣿⣿⣿⣿⣷⣶⣿⣏⠩⠭⣼⣿⣿⠏⠀⠀⠀⡼⠛⢉⣴⣿⠏⣸⡇
⠀⠀⢀⣾⡟⠀⠀⠀⠀⠀⠀⠀⠻⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣶⣿⣿⣿⠏⠀⠀⠀⡼⢁⣴⣿⡿⠁⣰⣿⠁
⠀⠀⣸⡟⠀⠀⠀⠀⠀⠀⠀⠀⠀⠈⠛⠿⠿⠿⠛⢛⣿⣿⣿⣿⣿⣿⣿⠏⠀⠀⠀⣰⣿⣿⡿⠋⠀⣰⣿⡟⢠
⠀⠀⡿⠁⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢀⣾⣿⣿⣿⣿⣿⣿⠏⠀⠀⠀⢠⣿⡿⠛⠁⠀⣼⣿⣿⣧⣿
⠀⢸⠃⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⣸⣿⣿⡿⠟⢻⠐⠉⠑⠤⣀⢠⣿⣿⠀⠀⢀⣾⣿⣿⣿⣿⣿
⠀⡏⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⣰⣿⣿⣿⢱⠹⠉⢉⠉⠓⠶⠤⠍⠛⢻⡄⣠⣿⣿⣿⣿⣿⣿⣿
⢸⠀⠀⠀⠀⠀⠀⢀⣤⣴⡖⠤⣀⠀⠀⠀⣼⣿⣿⣿⠉⠉⠑⠛⠛⠛⠳⢄⣀⠈⢹⠤⣿⣿⣿⣿⣿⣿⣿⣿⣿
ASCII
)

# ---------------------------------------------------------------------------
# NUKE wordmark reused by the main menu and the splash screen.
# ---------------------------------------------------------------------------
NUKE_WORDMARK=(
    "${BRIGHT_RED}███╗   ██╗ ██╗   ██╗ ██╗  ██╗ ███████╗${RESET}"
    "${BRIGHT_RED}████╗  ██║ ██║   ██║ ██║ ██╔╝ ██╔════╝${RESET}"
    "${BRIGHT_RED}██╔██╗ ██║ ██║   ██║ █████╔╝  █████╗  ${RESET}"
    "${BRIGHT_RED}██║╚██╗██║ ██║   ██║ ██╔═██╗  ██╔══╝  ${RESET}"
    "${BRIGHT_RED}██║ ╚████║ ╚██████╔╝ ██║  ██╗ ███████╗${RESET}"
    "${BRIGHT_RED}╚═╝  ╚═══╝  ╚═════╝  ╚═╝  ╚═╝ ╚══════╝${RESET}"
)

# ---------------------------------------------------------------------------
# Menu generators. Each prints its lines on stdout, one per line.
# The sub-action labels below are placeholders — rename them per module.
# ---------------------------------------------------------------------------
generate_main_menu() {
    local -a menu_lines=(
        "${NUKE_WORDMARK[@]}"
        " "
        "${BOLD}${BRIGHT_RED}█${RESET}    ${BRIGHT_MAGENTA}Configuration:${RESET}"
        "${BOLD}${BRIGHT_RED}█${RESET}    Target: ${BRIGHT_MAGENTA}${NUKE_TARGET:-Not set}${RESET}"
        "${BOLD}${BRIGHT_RED}█${RESET}    Output: ${BRIGHT_MAGENTA}${NUKE_OUTPUT_DIR}${RESET}"
        "${BOLD}${BRIGHT_RED}█${RESET}"
        "${BOLD}${BRIGHT_RED}█${RESET}    ${BRIGHT_RED}[1]${RESET}  Configuration Menu"
        "${BOLD}${BRIGHT_RED}█${RESET}    ${BRIGHT_RED}[2]${RESET}  Passive Module"
        "${BOLD}${BRIGHT_RED}█${RESET}    ${BRIGHT_RED}[3]${RESET}  Active Module"
        "${BOLD}${BRIGHT_RED}█${RESET}    ${BRIGHT_RED}[4]${RESET}  Special Module"
        "${BOLD}${BRIGHT_RED}█${RESET}"
        "${BOLD}${BRIGHT_RED}█${RESET}    ${BRIGHT_RED}[0]${RESET}  Exit"
        "${BOLD}${BRIGHT_RED}█${RESET}"
    )
    printf '%s\n' "${menu_lines[@]}"
}

generate_config_menu() {
    local -a menu_lines=(
        "${BRIGHT_RED}${BOLD}CONFIGURATION${RESET}"
        " "
        "${BRIGHT_MAGENTA}Set the parameters used by every module${RESET}"
        " "
        "${BOLD}${BRIGHT_RED}█${RESET}    Current Configuration:"
        "${BOLD}${BRIGHT_RED}█${RESET}    Target: ${BRIGHT_MAGENTA}${NUKE_TARGET:-Not set}${RESET}"
        "${BOLD}${BRIGHT_RED}█${RESET}    Output: ${BRIGHT_MAGENTA}${NUKE_OUTPUT_DIR}${RESET}"
        "${BOLD}${BRIGHT_RED}█${RESET}"
        "${BOLD}${BRIGHT_RED}█${RESET}    ${BRIGHT_RED}[1]${RESET}  Set Target (IP/Hostname)"
        "${BOLD}${BRIGHT_RED}█${RESET}    ${BRIGHT_RED}[2]${RESET}  Set Output Directory"
        "${BOLD}${BRIGHT_RED}█${RESET}"
        "${BOLD}${BRIGHT_RED}█${RESET}    ${BRIGHT_RED}[0]${RESET}  Back to Main Menu"
        "${BOLD}${BRIGHT_RED}█${RESET}"
    )
    printf '%s\n' "${menu_lines[@]}"
}

generate_passive_menu() {
    local -a menu_lines=(
        "${BRIGHT_RED}${BOLD}PASSIVE MODULE${RESET}"
        " "
        "${BRIGHT_MAGENTA}Placeholder actions — wire your own tools here${RESET}"
        " "
        "${BOLD}${BRIGHT_RED}█${RESET}    Target: ${BRIGHT_MAGENTA}${NUKE_TARGET:-Not set}${RESET}"
        "${BOLD}${BRIGHT_RED}█${RESET}"
        "${BOLD}${BRIGHT_RED}█${RESET}    ${BRIGHT_RED}[1]${RESET}  Action One"
        "${BOLD}${BRIGHT_RED}█${RESET}    ${BRIGHT_RED}[2]${RESET}  Action Two"
        "${BOLD}${BRIGHT_RED}█${RESET}"
        "${BOLD}${BRIGHT_RED}█${RESET}    ${BRIGHT_RED}[0]${RESET}  Back to Main Menu"
        "${BOLD}${BRIGHT_RED}█${RESET}"
    )
    printf '%s\n' "${menu_lines[@]}"
}

generate_active_menu() {
    local -a menu_lines=(
        "${BRIGHT_RED}${BOLD}ACTIVE MODULE${RESET}"
        " "
        "${BRIGHT_MAGENTA}Placeholder actions — wire your own tools here${RESET}"
        " "
        "${BOLD}${BRIGHT_RED}█${RESET}    Target: ${BRIGHT_MAGENTA}${NUKE_TARGET:-Not set}${RESET}"
        "${BOLD}${BRIGHT_RED}█${RESET}"
        "${BOLD}${BRIGHT_RED}█${RESET}    ${BRIGHT_RED}[1]${RESET}  Action One"
        "${BOLD}${BRIGHT_RED}█${RESET}    ${BRIGHT_RED}[2]${RESET}  Action Two"
        "${BOLD}${BRIGHT_RED}█${RESET}"
        "${BOLD}${BRIGHT_RED}█${RESET}    ${BRIGHT_RED}[0]${RESET}  Back to Main Menu"
        "${BOLD}${BRIGHT_RED}█${RESET}"
    )
    printf '%s\n' "${menu_lines[@]}"
}

generate_special_menu() {
    local -a menu_lines=(
        "${BRIGHT_RED}${BOLD}SPECIAL MODULE${RESET}"
        " "
        "${BRIGHT_MAGENTA}Placeholder actions — wire your own tools here${RESET}"
        " "
        "${BOLD}${BRIGHT_RED}█${RESET}    Target: ${BRIGHT_MAGENTA}${NUKE_TARGET:-Not set}${RESET}"
        "${BOLD}${BRIGHT_RED}█${RESET}"
        "${BOLD}${BRIGHT_RED}█${RESET}    ${BRIGHT_RED}[1]${RESET}  Action One"
        "${BOLD}${BRIGHT_RED}█${RESET}    ${BRIGHT_RED}[2]${RESET}  View Results"
        "${BOLD}${BRIGHT_RED}█${RESET}"
        "${BOLD}${BRIGHT_RED}█${RESET}    ${BRIGHT_RED}[0]${RESET}  Back to Main Menu"
        "${BOLD}${BRIGHT_RED}█${RESET}"
    )
    printf '%s\n' "${menu_lines[@]}"
}

# ---------------------------------------------------------------------------
# Splash screen displayed when the toolkit boots.
# ---------------------------------------------------------------------------
NUKE_INFO_PANEL=(
    "${NUKE_WORDMARK[@]}"
    ""
    "${BRIGHT_MAGENTA}${BOLD}Interactive Bash Toolkit Skeleton${RESET}"
    "${DIM}by Melvin PETIT${RESET}"
)

_strip_ansi() {
    sed -E 's/\x1B\[[0-9;?]*[ -/]*[@-~]//g; s/\x1B\][^\a]*\a//g'
}

display_title_middle_screen() {
    local cols rows
    cols=$(tput cols 2>/dev/null || echo 80)
    rows=$(tput lines 2>/dev/null || echo 24)

    local -a lines=( "${NUKE_INFO_PANEL[@]}" )
    local h=${#lines[@]}

    local max_w=0 raw visible_len line
    for line in "${lines[@]}"; do
        raw=$(printf "%s" "$line" | _strip_ansi)
        visible_len=${#raw}
        (( visible_len > max_w )) && max_w=$visible_len
    done

    local top=$(( (rows - h) / 2 ))
    (( top < 0 )) && top=0
    local left=$(( (cols - max_w) / 2 ))
    (( left < 0 )) && left=0

    printf "\033c"
    local i
    for ((i=0; i<top; i++)); do
        printf "\n"
    done

    for line in "${lines[@]}"; do
        printf "%*s%s\n" "$left" "" "$line"
    done
}

# ---------------------------------------------------------------------------
# Side-by-side rendering of the ASCII art and the active menu.
# ---------------------------------------------------------------------------
display_banner_with_menu() {
    local menu_type="$1"
    local -a ascii_lines menu_lines

    mapfile -t ascii_lines <<< "$NUKE_ASCII_ART"

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

    local spacing="    "
    local i
    for ((i=0; i<max_lines; i++)); do
        local ascii_line="${ascii_lines[i]:-}"
        local menu_line="${menu_lines[i]:-}"

        local colored_ascii="${BRIGHT_RED}${ascii_line}${RESET}"
        local pad=$(( max_ascii_width - ${#ascii_line} ))
        (( pad < 0 )) && pad=0

        printf "   %b%*s%s%b\n" \
            "$colored_ascii" \
            "$pad" "" \
            "$spacing" \
            "$menu_line"
    done
    echo ""
    printf "  %bCreator: \e]8;;https://github.com/WhiteMuush\aMelvin PETIT\e]8;;\a   %b%bAuthorized targets only%b\n" \
        "${BRIGHT_RED}" \
        "${BRIGHT_RED}" "${BOLD}" "${RESET}"
    echo ""
}

# Prompt rendered under each submenu. Hardcoded indent matches the menu layout.
prompt_menu_choice() {
    local label="$1"
    echo -ne "                                                 ${BOLD}${BRIGHT_RED}▪ ${label} : ${RESET}"
}
