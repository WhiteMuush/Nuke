#!/usr/bin/env bats
# Behavior of the safety guardrails.

setup() { load helper; _nuke_load; }

@test "rollback runs undos in LIFO order and clears the stack" {
    nuke_rollback_reset
    nuke_rollback_add "echo A"
    nuke_rollback_add "echo B"
    # Run in the current shell, not via `run`: its subshell would hide the stack
    # being cleared. Capture the output through a file instead.
    nuke_rollback_run >"${BATS_TEST_TMPDIR}/rollback.log" 2>&1
    local output
    output="$(cat "${BATS_TEST_TMPDIR}/rollback.log")"
    # B (most recent) must appear before A
    [[ "$output" == *"B"*"A"* ]]
    [ "${#NUKE_ROLLBACK_STACK[@]}" -eq 0 ]
}

@test "scope gate blocks when empty and passes when set" {
    NUKE_SCOPE=""
    run nuke_require_scope
    [ "$status" -ne 0 ]
    NUKE_SCOPE="k8s:test/default"
    run nuke_require_scope
    [ "$status" -eq 0 ]
}

@test "capped run completes a fast command" {
    run nuke_capped 5 -- bash -c 'exit 0'
    [ "$status" -eq 0 ]
}

@test "capped run kills a command that exceeds the limit" {
    run nuke_capped 1 -- sleep 5
    [ "$status" -ne 0 ]
}

@test "panic rolls back and exits 130" {
    run bash -c '
        clear() { :; }
        source lib/core.sh; source lib/installer.sh; source lib/safety.sh
        nuke_arm_rollback
        nuke_rollback_add "echo HEALED"
        ( sleep 0.2; kill -INT $$ ) &
        sleep 3
        echo NOTREACHED
    '
    [ "$status" -eq 130 ]
    [[ "$output" == *HEALED* ]]
    [[ "$output" != *NOTREACHED* ]]
}
