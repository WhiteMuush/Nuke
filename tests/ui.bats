#!/usr/bin/env bats
# Behavior of menu rendering helpers.

setup() { load helper; _nuke_load; }

@test "_menu_row2 pads the left cell to a fixed visible width" {
    run _menu_row2 4 "Pod-kill" 5 "Pod-failure"
    local visible
    visible="$(strip_ansi "$output")"
    # Left cell is _NUKE_CELL_W (24) cols, so the right marker starts at column
    # 24 (0-indexed). The key slot is _NUKE_KEY_W (4) plus a 2-space gap, which
    # puts three spaces between "[n]" and its label.
    [[ "${visible:24}" == "[5]   Pod-failure" ]]
    [[ "$visible" == "[4]   Pod-kill"* ]]
}

@test "_menu_row2 renders a single cell when the right side is empty" {
    run _menu_row2 3 "Setup" "" ""
    local visible
    visible="$(strip_ansi "$output")"
    [[ "$visible" == "[3]   Setup"* ]]
    [[ "$visible" != *"["*"]"*"["* ]]
}

@test "every menu renders without unbound-variable errors under set -u" {
    for m in main config kubernetes; do
        run bash -c "set -u; source tests/helper.bash; _nuke_load; display_banner_with_menu $m >/dev/null"
        [ "$status" -eq 0 ]
    done
}

@test "menus contain their expected content" {
    run display_banner_with_menu main
    [[ "$(strip_ansi "$output")" == *"Kubernetes"* ]]
    run display_banner_with_menu kubernetes
    [[ "$(strip_ansi "$output")" == *"Nuke Kubernetes"* ]]
    [[ "$(strip_ansi "$output")" == *"Pod-kill"* ]]
}

@test "the authorized-targets notice is present on every screen" {
    for m in main config kubernetes; do
        run display_banner_with_menu "$m"
        [[ "$(strip_ansi "$output")" == *"Nuke only authorized targets"* ]]
    done
}

@test "defcon is 5 without a target and follows the payload level" {
    NUKE_SCOPE="" NUKE_LEVEL=""
    [ "$(nuke_defcon)" -eq 5 ]
    NUKE_SCOPE="demo"
    [ "$(nuke_defcon)" -eq 5 ]
    NUKE_LEVEL=POKE;   [ "$(nuke_defcon)" -eq 4 ]
    NUKE_LEVEL=STRESS; [ "$(nuke_defcon)" -eq 3 ]
    NUKE_LEVEL=HAVOC;  [ "$(nuke_defcon)" -eq 2 ]
    NUKE_LEVEL=NUKE;   [ "$(nuke_defcon)" -eq 1 ]
    NUKE_SCOPE=""
    [ "$(nuke_defcon)" -eq 5 ]
}

@test "status panel uses the command-post vocabulary" {
    NUKE_SCOPE="demo" NUKE_LEVEL="HAVOC"
    run _nuke_status_lines
    local v
    v="$(strip_ansi "$output")"
    [[ "$v" == *"DEFCON"*"2"* ]]
    [[ "$v" == *"TARGET"*"demo"* ]]
    [[ "$v" == *"PAYLOAD"*"HAVOC"* ]]
    [[ "$v" == *"ROLLBACK"* ]]
}

@test "countdown digits are big and every digit has the same height" {
    local d h=""
    for d in 0 1 2 3 4 5 6 7 8 9; do
        run _nuke_big_digit "$d"
        [ "$status" -eq 0 ]
        [ "${#lines[@]}" -ge 5 ]
        [[ -z "$h" || "$h" -eq "${#lines[@]}" ]]
        h=${#lines[@]}
    done
}

@test "countdown is skipped off a terminal and when disabled" {
    run nuke_countdown 3
    [ "$status" -eq 0 ]
    [ -z "$output" ]
    NUKE_COUNTDOWN=0 run nuke_countdown
    [ "$status" -eq 0 ]
}
