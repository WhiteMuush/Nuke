# Adding a tool to Nuke

Most contributions add a new tool to one of the existing modules. The
process is intentionally short — a single function, a single menu line,
optionally a few lines in `install.sh`.

This document walks through the recipe step by step.

---

## Pick a module

| Module                       | Use case                                              |
|------------------------------|-------------------------------------------------------|
| `lib/modules/passive.sh`     | Actions that assume no privileges                     |
| `lib/modules/active.sh`      | Actions that need credentials / privileges            |
| `lib/modules/special.sh`     | Workflows, batch runs, post-processing                |

The passive / active / special split is just a convention. Rename the
modules or add new ones if your toolkit needs a different taxonomy. If a
tool doesn't fit any module, open an issue first.

---

## Anatomy of a module function

Every module function follows the same shape:

```bash
<module>_action_<name>() {
    require_target
    ensure_command "<binary>" "<install hint>" || return 0
    ensure_output_dir

    log_step "Running <tool>..."
    <binary> "${NUKE_TARGET}" ... \
        | tee "${NUKE_OUTPUT_DIR}/<output_file>"
    log_success "Results saved"
    press_enter_to_continue
}
```

That's it. The framework handles colors, prompting, missing-tool
warnings and output directory creation.

If the binary may be packaged under several names, use `resolve_command`
instead of `ensure_command`:

```bash
local bin
if ! bin=$(resolve_command "toolv2" "tool" "tool-ng"); then
    log_warn "None of toolv2, tool, tool-ng is installed."
    log_info "Hint: pipx install tool-ng"
    return 0
fi
"$bin" scan "${NUKE_TARGET}" ...
```

---

## Wire it into the menu

Two edits:

### 1. Update `generate_<module>_menu` in `lib/ui.sh`

Add one line in the `menu_lines` array for the new entry:

```bash
"${BOLD}${BRIGHT_RED}█${RESET}    ${BRIGHT_RED}[3]${RESET}  My Cool Tool"
```

### 2. Update `handle_<module>_menu` in `lib/modules/<module>.sh`

Add the matching case:

```bash
case "$choice" in
    1) passive_action_one ;;
    2) passive_action_two ;;
    3) passive_run_my_cool_tool ;;
    0) return ;;
esac
```

---

## Update `install.sh` if the tool needs installing

Copy the `install_example_tool` shape. If the tool ships in apt:

```bash
install_my_cool_tool() {
    log_step "Installing my-cool-tool..."
    apt_install my-cool-tool
    log_success "my-cool-tool installed"
}
```

If it's a pipx package:

```bash
install_my_cool_tool() {
    log_step "Installing my-cool-tool..."
    pipx_install my-cool-tool
    log_success "my-cool-tool installed"
}
```

If it's a GitHub project that needs cloning + symlink:

```bash
install_my_cool_tool() {
    log_step "Installing my-cool-tool..."
    local dest="${NUKE_TOOLS_DIR}/my-cool-tool"
    clone_or_pull "https://github.com/owner/my-cool-tool.git" "$dest"
    install_pip_requirements "$dest"
    chmod +x "${dest}/main.py"
    ln -sf "${dest}/main.py" /usr/local/bin/my-cool-tool
    log_success "my-cool-tool installed"
}
```

Then add the function to the `main` block at the bottom of `install.sh`.

---

## Checklist before opening the PR

- [ ] The new module function follows the shape above.
- [ ] Tool presence is checked with `ensure_command` or `resolve_command`.
- [ ] User input goes through `prompt_value` / `prompt_password`,
      not raw `read`.
- [ ] Logs go through `log_*`, not `echo -e ${RED}...${RESET}`.
- [ ] Every variable expansion is quoted (`"${var}"`, not `$var`).
- [ ] `bash -n` passes locally on the changed `.sh` files.
- [ ] The menu line and the case in `handle_<module>_menu` are updated
      in lockstep.
- [ ] If the tool needs installing, `install.sh` is updated.
- [ ] The smoke-test `expected` list in `ci.yml` includes the new
      public function.

---

## Don't / Do

| Don't                                                  | Do                                                          |
|--------------------------------------------------------|-------------------------------------------------------------|
| `echo -e "${RED}Running...${RESET}"`                   | `log_step "Running..."`                                     |
| `read -p "Target: " TARGET`                            | `target=$(prompt_value "Target")`                           |
| `command -v foo \|\| { echo missing; return; }`        | `ensure_command "foo" "apt install foo" \|\| return 0`      |
| `IFS=$'\n' read -r -d '' -a arr <<<"$STR"`             | `mapfile -t arr <<<"$STR"`                                  |
| `cd /opt/foo && do_stuff && cd -`                      | `(cd /opt/foo \|\| exit 1; do_stuff)`                       |
| `arr=( $(find . -name '*.txt') )`                      | `mapfile -t arr < <(find . -name '*.txt')`                  |
| `$CMD --flag $TARGET`                                  | `"$CMD" --flag "${NUKE_TARGET}"`                            |
| French comments / log messages / docs                  | English everywhere                                          |
