#!/usr/bin/env bats
# Behavior of the intensity ladder.

setup() { load helper; _nuke_load; }

@test "level index is 1-based and ordered" {
    [ "$(nuke_level_index POKE)" -eq 1 ]
    [ "$(nuke_level_index STRESS)" -eq 2 ]
    [ "$(nuke_level_index HAVOC)" -eq 3 ]
    [ "$(nuke_level_index NUKE)" -eq 4 ]
}

@test "level index is 0 for an unknown level" {
    run nuke_level_index BOGUS
    [ "$output" -eq 0 ]
    [ "$status" -ne 0 ]
}

@test "profiles escalate across levels" {
    [ "$(nuke_level_profile POKE duration)" -lt "$(nuke_level_profile NUKE duration)" ]
    [ "$(nuke_level_profile POKE magnitude)" -eq 20 ]
    [ "$(nuke_level_profile NUKE magnitude)" -eq 100 ]
    [ "$(nuke_level_profile NUKE blast)" -eq 9999 ]
    [ "$(nuke_level_profile POKE blast)" -eq 1 ]
}

@test "unknown level or field returns non-zero" {
    run nuke_level_profile BOGUS duration
    [ "$status" -ne 0 ]
    run nuke_level_profile POKE bogus
    [ "$status" -ne 0 ]
}

@test "only NUKE requires detonation confirmation" {
    run nuke_level_requires_confirm NUKE
    [ "$status" -eq 0 ]
    for l in POKE STRESS HAVOC; do
        run nuke_level_requires_confirm "$l"
        [ "$status" -ne 0 ]
    done
}

@test "level label mentions the level name" {
    run nuke_level_label HAVOC
    [[ "$output" == *HAVOC* ]]
}
