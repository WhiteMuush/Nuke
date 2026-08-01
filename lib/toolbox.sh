#!/usr/bin/env bash
# lib/toolbox.sh — Cross-distro environment detection and tool bring-up.
# Nuke must run on any distro, so tool install prefers downloaded static
# binaries over distro packages. Per-tool recipes live in each layer; this
# file provides the shared plumbing they call.

if [[ -n "${NUKE_TOOLBOX_LOADED:-}" ]]; then
    return 0
fi
NUKE_TOOLBOX_LOADED=1

# Where Nuke drops static binaries it downloads. User-writable, no root needed.
NUKE_BIN_DIR="${NUKE_BIN_DIR:-${HOME}/.nuke/bin}"

# Put Nuke's bin dir on PATH for this process so installed tools are found.
case ":${PATH}:" in
    *":${NUKE_BIN_DIR}:"*) ;;
    *) PATH="${NUKE_BIN_DIR}:${PATH}" ;;
esac
export PATH

# True if a command is available on PATH.
nuke_have() {
    command -v "$1" >/dev/null 2>&1
}

# Detect the system package manager, echoing its name (apt/dnf/yum/pacman/
# apk/zypper/brew) or "none". Used only as a fallback; static binaries first.
nuke_pkg_manager() {
    local pm
    for pm in apt-get apt dnf yum pacman apk zypper brew; do
        if nuke_have "$pm"; then
            printf '%s' "$pm"
            return 0
        fi
    done
    printf 'none'
    return 1
}

# Echo "<os>/<arch>" normalized for release download URLs (e.g. linux/amd64).
nuke_os_arch() {
    local os arch
    os="$(uname -s | tr '[:upper:]' '[:lower:]')"
    case "$(uname -m)" in
        x86_64|amd64)      arch=amd64 ;;
        aarch64|arm64)     arch=arm64 ;;
        armv7l|armv7|arm)  arch=arm   ;;
        *)                 arch="$(uname -m)" ;;
    esac
    printf '%s/%s' "${os}" "${arch}"
}

# nuke_download <url> <dest>  — curl or wget, whichever exists.
nuke_download() {
    local url="$1" dest="$2"
    if nuke_have curl; then
        curl -fsSL "$url" -o "$dest"
    elif nuke_have wget; then
        wget -qO "$dest" "$url"
    else
        log_error "Neither curl nor wget available to download ${url}"
        return 1
    fi
}

# nuke_install_binary <url> <name> [--tar <path-in-archive>]
# Fetch a static binary (or extract one from a .tar.gz) into NUKE_BIN_DIR,
# make it executable, and confirm it runs. Idempotent: skips if already present.
nuke_install_binary() {
    local url="$1" name="$2" tar_member=""
    if [[ "${3:-}" == "--tar" ]]; then
        tar_member="$4"
    fi

    if nuke_have "$name"; then
        log_info "${name} already available ($(command -v "$name"))"
        return 0
    fi

    mkdir -p "${NUKE_BIN_DIR}"
    local dest="${NUKE_BIN_DIR}/${name}"

    log_step "Installing ${name} from ${url}"
    if [[ -n "${tar_member}" ]]; then
        local tmp
        tmp="$(mktemp)"
        nuke_download "$url" "$tmp" || { rm -f "$tmp"; return 1; }
        tar -xzf "$tmp" -O "${tar_member}" > "${dest}" || { rm -f "$tmp"; return 1; }
        rm -f "$tmp"
    else
        nuke_download "$url" "${dest}" || return 1
    fi

    chmod +x "${dest}"
    if "${dest}" --version >/dev/null 2>&1 || "${dest}" version >/dev/null 2>&1; then
        log_success "${name} installed to ${dest}"
    else
        log_success "${name} installed to ${dest} (version check skipped)"
    fi
}

# Print a presence table for the tools Nuke's layers rely on.
nuke_detect_env() {
    local -a tools=(docker kubectl kind tc iptables stress-ng pumba toxiproxy-cli helm)
    log_step "Environment detection"
    log_info "Package manager: $(nuke_pkg_manager)"
    log_info "Platform: $(nuke_os_arch)"
    local t mark
    for t in "${tools[@]}"; do
        if nuke_have "$t"; then
            mark="${GREEN}present${RESET}"
        else
            mark="${DIM}missing${RESET}"
        fi
        printf '  %b%-16s%b %b\n' "${BOLD}" "$t" "${RESET}" "$mark"
    done
}
