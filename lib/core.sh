#!/usr/bin/env bash
# lib/core.sh — Colors, palette, global state and shared constants for Nuke.
# Sourced by the entry point and by every module; never executed directly.

if [[ -n "${NUKE_CORE_LOADED:-}" ]]; then
    return 0
fi
NUKE_CORE_LOADED=1

# ---------------------------------------------------------------------------
# Color palette — TTY-aware. Pipes get plain text, terminals get colors.
# ---------------------------------------------------------------------------
if [[ -t 1 ]] && command -v tput >/dev/null 2>&1 \
        && [[ -n "${TERM:-}" ]] && [[ "${TERM}" != "dumb" ]]; then
    RESET="$(tput sgr0)"
    BOLD="$(tput bold)"
    DIM="$(tput dim)"

    RED="$(tput setaf 1)"
    GREEN="$(tput setaf 2)"
    YELLOW="$(tput setaf 3)"
    BLUE="$(tput setaf 4)"
    MAGENTA="$(tput setaf 5)"
    CYAN="$(tput setaf 6)"

    BRIGHT_RED="$(tput setaf 9)"
    BRIGHT_GREEN="$(tput setaf 10)"
    BRIGHT_MAGENTA="$(tput setaf 13)"
else
    RESET=""
    BOLD=""
    DIM=""
    RED=""
    GREEN=""
    YELLOW=""
    BLUE=""
    MAGENTA=""
    CYAN=""
    BRIGHT_RED=""
    BRIGHT_GREEN=""
    BRIGHT_MAGENTA=""
fi
readonly RESET BOLD DIM RED GREEN YELLOW BLUE MAGENTA CYAN
readonly BRIGHT_RED BRIGHT_GREEN BRIGHT_MAGENTA

# ---------------------------------------------------------------------------
# Global runtime state. Modules read and write these freely.
# Per-experiment scope (namespace / container / host filter) lives in
# NUKE_SCOPE, defined by the safety layer and set inside each target layer.
# ---------------------------------------------------------------------------
NUKE_OUTPUT_DIR="nuke_out_$(date +%Y%m%d_%H%M%S)"

# Where third-party tools may be cloned by install.sh.
NUKE_TOOLS_DIR="${NUKE_TOOLS_DIR:-/opt}"

# ---------------------------------------------------------------------------
# Shared helpers used across modules. Add project-wide pure helpers here.
# ---------------------------------------------------------------------------
