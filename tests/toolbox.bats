#!/usr/bin/env bats
# Behavior of cross-distro detection helpers.

setup() { load helper; _nuke_load; }

@test "os/arch is normalized as <os>/<arch>" {
    run nuke_os_arch
    [[ "$output" =~ ^[a-z]+/(amd64|arm64|arm|.+)$ ]]
}

@test "nuke_have detects present and absent commands" {
    run nuke_have bash
    [ "$status" -eq 0 ]
    run nuke_have definitely_not_a_real_command_xyz
    [ "$status" -ne 0 ]
}

@test "pkg manager returns a value" {
    run nuke_pkg_manager
    [ -n "$output" ]
}

@test "bin dir is on PATH after sourcing" {
    case ":${PATH}:" in
        *":${NUKE_BIN_DIR}:"*) : ;;
        *) false ;;
    esac
}
