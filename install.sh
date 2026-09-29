#!/usr/bin/env bash
# install.sh — Install the tools Nuke's layers rely on.
# Targets Debian / Ubuntu / Kali. Run with sudo.
#
# System tools come from apt; the Kubernetes and container-chaos tools are
# pinned to their latest upstream release and dropped as static binaries into
# /usr/local/bin, so this works the same across distros.

set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
readonly SCRIPT_DIR

# shellcheck source=lib/core.sh
source "${SCRIPT_DIR}/lib/core.sh"
# shellcheck source=lib/installer.sh
source "${SCRIPT_DIR}/lib/installer.sh"

# Downloaded binaries go system-wide (this runs as root).
export NUKE_BIN_DIR="${NUKE_BIN_DIR:-/usr/local/bin}"
# shellcheck source=lib/toolbox.sh
source "${SCRIPT_DIR}/lib/toolbox.sh"

# Release architecture slug (amd64 / arm64 / ...), derived from the host.
NUKE_ARCH="$(nuke_os_arch)"; NUKE_ARCH="${NUKE_ARCH#*/}"
readonly NUKE_ARCH

# ---------------------------------------------------------------------------
# GitHub release resolvers. Echo empty on failure so callers can skip cleanly.
# ---------------------------------------------------------------------------
# Download URL of the first asset matching <pattern> in the latest release.
_gh_latest_asset() {
    local repo="$1" pattern="$2"
    curl -fsSL "https://api.github.com/repos/${repo}/releases/latest" 2>/dev/null \
        | grep -oE '"browser_download_url": *"[^"]+"' \
        | cut -d'"' -f4 | grep -E "${pattern}" | head -1
}

# Tag name of the latest release (e.g. v3.16.2).
_gh_latest_tag() {
    curl -fsSL "https://api.github.com/repos/$1/releases/latest" 2>/dev/null \
        | grep -oE '"tag_name": *"[^"]+"' | cut -d'"' -f4 | head -1
}

# ---------------------------------------------------------------------------
# Disable known broken apt repositories that would abort `apt update`.
# ---------------------------------------------------------------------------
disable_broken_repos() {
    log_step "Cleaning up broken apt repositories..."
    mkdir -p /etc/apt/sources.list.d/disabled
    if ls /etc/apt/sources.list.d/*winehq* >/dev/null 2>&1; then
        mv /etc/apt/sources.list.d/*winehq* /etc/apt/sources.list.d/disabled/ \
            2>/dev/null || true
    fi
    log_success "Repositories cleaned"
}

install_base_dependencies() {
    log_step "Installing base dependencies..."
    apt update -y 2>&1 | grep -v "NO_PUBKEY\|not signed" || true
    apt_install \
        git curl wget \
        python3 python3-pip python3-venv python3-full pipx \
        build-essential 2>&1 | grep -v "WARNING" || true
    log_success "Base dependencies installed"
    export PATH="${PATH}:/root/.local/bin:${HOME}/.local/bin"
    pipx ensurepath 2>/dev/null || true
}

# System-level chaos tools available from apt: tc (iproute2), iptables,
# stress-ng, and the Docker engine used by the container layer and kind.
install_system_tools() {
    log_step "Installing system tools (iproute2, iptables, stress-ng, docker)..."
    apt_install iproute2 iptables stress-ng docker.io 2>&1 | grep -v "WARNING" || true
    systemctl enable --now docker >/dev/null 2>&1 || true
    if [[ -n "${SUDO_USER:-}" ]] && getent group docker >/dev/null 2>&1; then
        usermod -aG docker "${SUDO_USER}" 2>/dev/null \
            && log_info "Added ${SUDO_USER} to the docker group (re-login to apply)."
    fi
    log_success "System tools installed"
}

# kubectl: pinned to the current stable channel.
install_kubectl() {
    local ver
    ver="$(curl -fsSL https://dl.k8s.io/release/stable.txt 2>/dev/null)" || true
    [[ -n "${ver}" ]] || { log_warn "Could not resolve kubectl version, skipping."; return 0; }
    nuke_install_binary "https://dl.k8s.io/release/${ver}/bin/linux/${NUKE_ARCH}/kubectl" kubectl
}

# kind: local Kubernetes in Docker, used by the test environment.
install_kind() {
    local url
    url="$(_gh_latest_asset kubernetes-sigs/kind "kind-linux-${NUKE_ARCH}\$")"
    [[ -n "${url}" ]] || { log_warn "Could not resolve kind release, skipping."; return 0; }
    nuke_install_binary "${url}" kind
}

# helm: used to install Chaos Mesh for the network / stress faults.
install_helm() {
    local ver
    ver="$(_gh_latest_tag helm/helm)"
    [[ -n "${ver}" ]] || { log_warn "Could not resolve helm version, skipping."; return 0; }
    nuke_install_binary "https://get.helm.sh/helm-${ver}-linux-${NUKE_ARCH}.tar.gz" helm \
        --tar "linux-${NUKE_ARCH}/helm"
}

# pumba: container chaos (pause, kill, netem) for the Docker layer.
install_pumba() {
    local url
    url="$(_gh_latest_asset alexei-led/pumba "pumba_linux_${NUKE_ARCH}\$")"
    [[ -n "${url}" ]] || { log_warn "Could not resolve pumba release, skipping."; return 0; }
    nuke_install_binary "${url}" pumba
}

# toxiproxy-cli: TCP fault injection for the network layer.
install_toxiproxy() {
    local url
    url="$(_gh_latest_asset Shopify/toxiproxy "toxiproxy-cli-linux-${NUKE_ARCH}\$")"
    [[ -n "${url}" ]] || { log_warn "Could not resolve toxiproxy release, skipping."; return 0; }
    nuke_install_binary "${url}" toxiproxy-cli
}

configure_path() {
    log_step "Configuring PATH..."
    if ! grep -q ".local/bin" /root/.bashrc 2>/dev/null; then
        echo 'export PATH="$PATH:$HOME/.local/bin:/root/.local/bin"' >> /root/.bashrc
    fi
    if [[ -n "${SUDO_USER:-}" ]]; then
        local user_home
        user_home=$(getent passwd "$SUDO_USER" | cut -d: -f6)
        if [[ -f "${user_home}/.bashrc" ]] \
                && ! grep -q ".local/bin" "${user_home}/.bashrc"; then
            echo 'export PATH="$PATH:$HOME/.local/bin"' >> "${user_home}/.bashrc"
            chown "${SUDO_USER}:${SUDO_USER}" "${user_home}/.bashrc"
        fi
    fi
    export PATH="${PATH}:${HOME}/.local/bin:/root/.local/bin"
}

print_summary() {
    echo ""
    echo "========================================================================"
    log_success "Installation complete."
    echo "========================================================================"
    echo ""
    echo "Reload your shell (source ~/.bashrc) so the new binaries are on PATH."
    echo "Docker group changes need a re-login to take effect."
    echo ""
}

main() {
    require_root
    disable_broken_repos
    install_base_dependencies
    install_system_tools
    install_kubectl
    install_kind
    install_helm
    install_pumba
    install_toxiproxy
    configure_path
    print_summary
    echo ""
    nuke_detect_env || true
}

# Allow sourcing (for tests) without running the installer.
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
