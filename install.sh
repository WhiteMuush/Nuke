#!/usr/bin/env bash
# install.sh — Install the base dependencies required by Nuke.
# Designed for Debian/Ubuntu/Kali. Run with sudo.
#
# This is a skeleton installer: it sets up a sane base and PATH, then leaves
# per-tool installers for you to fill in. See install_example_tool below and
# docs/ADDING_A_TOOL.md.

set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
readonly SCRIPT_DIR

# shellcheck source=lib/core.sh
source "${SCRIPT_DIR}/lib/core.sh"
# shellcheck source=lib/installer.sh
source "${SCRIPT_DIR}/lib/installer.sh"

require_root

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
        git \
        curl \
        wget \
        python3 \
        python3-pip \
        python3-venv \
        python3-full \
        pipx \
        build-essential 2>&1 | grep -v "WARNING" || true

    log_success "Base dependencies installed"

    export PATH="${PATH}:/root/.local/bin:${HOME}/.local/bin"
    pipx ensurepath 2>/dev/null || true
}

# ---------------------------------------------------------------------------
# Example per-tool installer. Copy this shape for each real tool you add,
# then call it from main(). Delete once you have your own.
# ---------------------------------------------------------------------------
install_example_tool() {
    log_step "Installing example-tool..."
    # apt path:
    #   apt_install example-tool
    # pipx path:
    #   pipx_install example-tool
    # git path:
    #   local dest="${NUKE_TOOLS_DIR}/example-tool"
    #   clone_or_pull "https://github.com/owner/example-tool.git" "$dest"
    #   install_pip_requirements "$dest"
    #   chmod +x "${dest}/main.py"
    #   ln -sf "${dest}/main.py" /usr/local/bin/example-tool
    log_info "example-tool is a placeholder. Replace this function."
}

configure_path() {
    log_step "Configuring PATH..."
    if ! grep -q ".local/bin" /root/.bashrc 2>/dev/null; then
        echo 'export PATH="$PATH:$HOME/.local/bin:/root/.local/bin"' >> /root/.bashrc
    fi

    if [[ -n "${SUDO_USER:-}" ]]; then
        local user_home
        user_home=$(getent passwd "$SUDO_USER" | cut -d: -f6)
        if [[ -f "${user_home}/.bashrc" ]]; then
            if ! grep -q ".local/bin" "${user_home}/.bashrc"; then
                echo 'export PATH="$PATH:$HOME/.local/bin"' >> "${user_home}/.bashrc"
                chown "${SUDO_USER}:${SUDO_USER}" "${user_home}/.bashrc"
            fi
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
    echo "Base ready. Add your per-tool installers in install.sh (see"
    echo "install_example_tool) and register them in main()."
    echo ""
    echo "IMPORTANT:"
    echo "  Reload your shell: source ~/.bashrc"
    echo "  Or restart your terminal."
    echo ""
    echo "========================================================================"
}

main() {
    disable_broken_repos
    install_base_dependencies
    # install_example_tool
    configure_path
    print_summary
}

main "$@"
