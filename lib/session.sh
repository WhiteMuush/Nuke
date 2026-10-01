#!/usr/bin/env bash
# lib/session.sh — Named, persistent sessions.
# A session is a workspace on disk that remembers its config (scope, namespace,
# per-layer filters) and holds its own output directory, so relaunching Nuke can
# resume exactly where the last run left off. Chosen at boot, saved on change.
#
# Layout:
#   ${NUKE_HOME}/sessions/<name>/
#       session.env   key=value config, written and read by this layer only
#       output/       NUKE_OUTPUT_DIR for the session (logs, results)

if [[ -n "${NUKE_SESSION_LOADED:-}" ]]; then
    return 0
fi
NUKE_SESSION_LOADED=1

# Keys persisted to session.env. Only these are written and read back, so a
# hand-edited file can never inject arbitrary variables or code.
NUKE_SESSION_KEYS=(
    NUKE_SESSION_NAME
    NUKE_OUTPUT_DIR
    NUKE_SCOPE
    NUKE_K8S_NAMESPACE
    NUKE_K8S_LABEL
    NUKE_DOCKER_SCOPE
    NUKE_NET_IFACE
    NUKE_HOST_NAME
)

nuke_sessions_root() {
    printf '%s/sessions' "${NUKE_HOME}"
}

# nuke_session_dir [name] — directory for a session (defaults to the active one).
nuke_session_dir() {
    printf '%s/%s' "$(nuke_sessions_root)" "${1:-${NUKE_SESSION_NAME}}"
}

# Turn user input into a safe session name: spaces to underscores, then keep
# only [A-Za-z0-9._-]. Echoes the cleaned name (may be empty).
nuke_session_sanitize() {
    printf '%s' "$1" | tr ' ' '_' | sed 's/[^A-Za-z0-9._-]//g'
}

# Echo existing session names, newest first. Nothing if there are none.
nuke_session_names() {
    local root
    root="$(nuke_sessions_root)"
    [[ -d "${root}" ]] || return 0
    find "${root}" -mindepth 1 -maxdepth 1 -type d -printf '%T@ %f\n' 2>/dev/null \
        | sort -rn | cut -d' ' -f2-
}

# Write the active session's config to its session.env. Silent no-op if no
# session is active yet.
nuke_session_save() {
    [[ -n "${NUKE_SESSION_NAME}" ]] || return 0
    local dir
    dir="$(nuke_session_dir)"
    mkdir -p "${dir}"
    local key val file="${dir}/session.env"
    : > "${file}"
    for key in "${NUKE_SESSION_KEYS[@]}"; do
        val="${!key:-}"
        printf '%s=%s\n' "${key}" "${val}" >> "${file}"
    done
}

# nuke_session_load <name> — load a session's config into the globals.
# Reads only whitelisted keys; anything else in the file is ignored.
nuke_session_load() {
    local name="$1"
    local file
    file="$(nuke_session_dir "${name}")/session.env"
    NUKE_SESSION_NAME="${name}"
    [[ -f "${file}" ]] || return 0

    local key val
    while IFS='=' read -r key val; do
        case "${key}" in
            NUKE_SESSION_NAME)  NUKE_SESSION_NAME="${val}"  ;;
            NUKE_OUTPUT_DIR)    NUKE_OUTPUT_DIR="${val}"     ;;
            NUKE_SCOPE)         NUKE_SCOPE="${val}"          ;;
            NUKE_K8S_NAMESPACE) NUKE_K8S_NAMESPACE="${val}"  ;;
            NUKE_K8S_LABEL)     NUKE_K8S_LABEL="${val}"      ;;
            NUKE_DOCKER_SCOPE)  NUKE_DOCKER_SCOPE="${val}"   ;;
            NUKE_NET_IFACE)     NUKE_NET_IFACE="${val}"      ;;
            NUKE_HOST_NAME)     NUKE_HOST_NAME="${val}"      ;;
            *) : ;;
        esac
    done < "${file}"
}

# nuke_session_use <name> — make <name> the active session: create its dirs,
# default its output dir, load any saved config, then persist. Used by both the
# boot picker and "switch session" in the config menu.
nuke_session_use() {
    local name="$1"
    local dir
    dir="$(nuke_session_dir "${name}")"
    local existed=0
    [[ -d "${dir}" ]] && existed=1

    mkdir -p "${dir}/output"
    NUKE_SESSION_NAME="${name}"
    NUKE_OUTPUT_DIR="${dir}/output"

    if (( existed )); then
        nuke_session_load "${name}"
        log_success "Session loaded: ${name}"
    else
        log_success "New session: ${name}"
    fi
    nuke_session_save
}

# Boot picker. New / Continue / Auto, rendered as a full sub-view so it matches
# the rest of the toolkit.
_nuke_session_new() {
    local name=""
    while [[ -z "${name}" ]]; do
        nuke_subview "NEW SESSION"
        printf '   %bName the session%b (e.g. lab_cluster, staging_soak).\n' "${DIM}" "${RESET}"
        printf '   %bLetters, digits, . _ - only; spaces become underscores.%b\n\n' "${DIM}" "${RESET}"
        nuke_prompt "Session name"
        local raw
        read -r raw
        name="$(nuke_session_sanitize "${raw}")"
        [[ -z "${name}" ]] && { log_error "Name cannot be empty."; sleep 1; }
    done
    nuke_session_use "${name}"
}

_nuke_session_continue() {
    local -a names
    mapfile -t names < <(nuke_session_names)
    if [[ ${#names[@]} -eq 0 ]]; then
        nuke_subview "CONTINUE SESSION"
        log_warn "No saved sessions yet. Create a new one."
        sleep 2
        return 1
    fi

    local -a rows=()
    local i=1 n scope
    for n in "${names[@]}"; do
        scope="$(_nuke_session_saved_scope "${n}")"
        rows+=( "$(printf '%b[%d]%b  %-20s %b%s%b' \
            "${BRIGHT_RED}" "${i}" "${RESET}" "${n}" "${DIM}" "${scope}" "${RESET}")" )
        (( i++ ))
    done

    nuke_menu_screen "Nuke Continue Session" "Pick a session" "${rows[@]}"
    local pick
    read -r pick
    if [[ "${pick}" =~ ^[0-9]+$ ]] && (( pick >= 1 && pick <= ${#names[@]} )); then
        nuke_session_use "${names[$(( pick - 1 ))]}"
        return 0
    fi
    log_error "Invalid selection."
    sleep 1
    return 1
}

# Peek at a saved session's scope for the listing, without loading it.
_nuke_session_saved_scope() {
    local file
    file="$(nuke_session_dir "$1")/session.env"
    [[ -f "${file}" ]] || { printf 'no scope'; return 0; }
    local val
    val="$(sed -n 's/^NUKE_SCOPE=//p' "${file}")"
    printf '%s' "${val:-no scope}"
}

# nuke_session_init — run at boot. Loops until a session is active.
nuke_session_init() {
    while [[ -z "${NUKE_SESSION_NAME}" ]]; do
        local -a names
        mapfile -t names < <(nuke_session_names)
        local -a opts=()
        (( ${#names[@]} > 0 )) && opts+=( "${DIM}Saved sessions: ${#names[@]}${RESET}" "" )
        opts+=(
            "${BRIGHT_RED}[1]${RESET}  New session"
            ""
            "${BRIGHT_RED}[2]${RESET}  Continue an existing session"
            ""
            "${BRIGHT_RED}[3]${RESET}  Auto (nuke_$(date +%Y%m%d_%H%M%S))"
        )
        nuke_menu_screen "Nuke Sessions" "Session" "${opts[@]}"
        local choice
        read -r choice
        case "${choice}" in
            1)   _nuke_session_new ;;
            2)   _nuke_session_continue || continue ;;
            3|"") nuke_session_use "nuke_$(date +%Y%m%d_%H%M%S)" ;;
            *)   log_error "Invalid choice."; sleep 1 ;;
        esac
    done
    sleep 1
}

# One-line-per-field summary of the active session, for the config menu.
nuke_session_summary_lines() {
    printf 'Session   : %b%s%b\n'  "${BRIGHT_RED}" "${NUKE_SESSION_NAME:-Not set}" "${RESET}"
    printf 'Output    : %b%s%b\n'  "${BRIGHT_RED}" "${NUKE_OUTPUT_DIR}"             "${RESET}"
    printf 'Scope     : %b%s%b\n'  "${BRIGHT_RED}" "${NUKE_SCOPE:-Not set}"         "${RESET}"
}
