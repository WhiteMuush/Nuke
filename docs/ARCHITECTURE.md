# Architecture

Nuke is a skeleton for an interactive Bash toolkit: a single, predictable
menu that dispatches to modular actions. It ships the framework (colors,
logging, prompting, menu rendering, install primitives) with placeholder
modules you replace with your own tools.

This document explains the layout of the codebase so that a new
contributor can find the right file in seconds.

---

## File layout

```
nuke.sh                     Entry point. ~50 lines.
install.sh                  Installer for Debian / Ubuntu / Kali.
lib/
├── core.sh                 Colors (TTY-aware), palette, global state.
├── ui.sh                   ASCII art, menus, banner rendering.
├── installer.sh            Logging, prompting and install primitives.
├── compat.sh               Non-Debian / macOS gate: shared Debian box.
└── modules/
    ├── config.sh           Target / output config.
    ├── passive.sh          Placeholder module (no privileges assumed).
    ├── active.sh           Placeholder module (privileged actions).
    └── special.sh          Placeholder workflows + results viewer.
.github/
├── workflows/ci.yml        shellcheck + bash -n + smoke test.
├── ISSUE_TEMPLATE/         Structured issue forms.
└── PULL_REQUEST_TEMPLATE.md
docs/
├── ARCHITECTURE.md         This document.
├── ADDING_A_TOOL.md        How to plug in a new tool.
├── CONTRIBUTING.md         Local setup, conventions, PR checklist.
├── CODE_OF_CONDUCT.md      Community standards.
└── SECURITY.md             Private vulnerability disclosure.
```

---

## Boot sequence

```
./nuke.sh
    │
    ├── set -uo pipefail                  (strict-ish: -e omitted on purpose)
    ├── SCRIPT_DIR=<absolute path>
    │
    ├── source lib/core.sh                # palette + globals
    ├── source lib/installer.sh           # logging + prompts + helpers
    ├── source lib/ui.sh                  # ascii art + menus
    ├── source lib/modules/config.sh
    ├── source lib/modules/passive.sh
    ├── source lib/modules/active.sh
    ├── source lib/modules/special.sh
    │
    └── main_loop
            ├── display_title_middle_screen
            ├── while true:
            │       display_banner_with_menu "main"
            │       read choice
            │       case → handle_{config,passive,active,special}_menu
            └── 0 → exit 0
```

`install.sh` follows the same source chain but only loads `core.sh` and
`installer.sh` (it does not need the UI or modules).

---

## Why no `set -e`

The interactive `nuke.sh` deliberately uses `set -uo pipefail` and
**not** `set -e`. Inside a menu loop, any tool that returns a non-zero
exit code would otherwise kill the entire toolkit.

`install.sh` is non-interactive and uses the full `set -euo pipefail`.

---

## Color handling

`lib/core.sh` defines the palette. Colors are emitted **only** when
stdout is a TTY (`[[ -t 1 ]]`) and `tput` is available. When piped or
redirected, every color variable becomes the empty string so the output
stays clean.

---

## Global state

Shared runtime state lives in the variables defined in `lib/core.sh`:

| Variable            | Set by                                | Read by                              |
|---------------------|---------------------------------------|--------------------------------------|
| `NUKE_TARGET`       | `config_set_target`, `require_target` | Every action module                  |
| `NUKE_OUTPUT_DIR`   | `config_set_output_dir`               | Every module that writes to disk     |
| `NUKE_TOOLS_DIR`    | environment (default `/opt`)          | `install.sh`                         |

Modules never touch globals owned by another module. Add your own
`NUKE_*` globals in `core.sh` as the toolkit grows.

---

## Public helpers (`lib/installer.sh`)

| Helper                       | Purpose                                            |
|------------------------------|----------------------------------------------------|
| `log_step / log_info / log_warn / log_error / log_success` | Color-coded logging |
| `prompt_value LABEL [DEFAULT]` | Free-form input with optional default            |
| `prompt_password LABEL`      | Silent password prompt                             |
| `prompt_yesno LABEL [DEFAULT]` | y/N prompt that returns 0/1                       |
| `press_enter_to_continue`    | Pause and wait for Enter                           |
| `ensure_command CMD [HINT]`  | Warn if `CMD` is missing, return 1                 |
| `resolve_command CMD...`     | Echo first available command from a list           |
| `clone_or_pull URL DEST`     | Git clone or fast-forward pull                     |
| `pip_install PKG`            | Best-effort pip install with PEP 668 fallbacks     |
| `pipx_install PKG`           | Pipx install with `--force` and warning filter     |
| `apt_install PKG...`         | Wrapper around `apt install -y`                    |
| `require_root`               | Exit if EUID != 0                                  |

---

## Public helpers (`lib/modules/config.sh`)

| Helper                       | Purpose                                            |
|------------------------------|----------------------------------------------------|
| `require_target`             | Prompt if `NUKE_TARGET` is empty                   |
| `ensure_output_dir`          | `mkdir -p "${NUKE_OUTPUT_DIR}"`                     |

Every module function follows the same shape:

```bash
<module>_action_<name>() {
    require_target
    ensure_command "<binary>" "<install hint>" || return 0
    ensure_output_dir
    log_step "..."
    <binary> ... | tee "${NUKE_OUTPUT_DIR}/<file>"
    log_success "Results saved"
    press_enter_to_continue
}
```

---

## CI

Three jobs run on every push and PR:

1. `shellcheck` — `severity: warning`, with
   `SHELLCHECK_OPTS: -e SC1091 -e SC2034 -e SC2154`.
2. `bash -n` — syntax check on every `.sh` in the tree.
3. Smoke test — sources the full `lib/` chain and asserts that every
   public function from `installer.sh`, `ui.sh` and the four modules is
   defined. Update the `expected` list in `ci.yml` when you add or rename
   a public function.
