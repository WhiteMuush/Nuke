# Contributing to Nuke

Thanks for the interest. Nuke is a skeleton for an interactive Bash toolkit.
The codebase is plain Bash and aims to stay small, readable and
contributor-friendly.

This guide covers the conventions that make a contribution easy to review
and merge.

---

## Local setup

```bash
git clone https://github.com/WhiteMuush/Nuke.git
cd Nuke
sudo ./install.sh        # installs the base dependencies
./nuke.sh                # launch the interactive menu
```

Nuke targets **Debian / Ubuntu / Kali**. Other distros may work but
are not part of CI.

Optional local checks before opening a PR:

```bash
# Syntax check on every bash script
find . -name '*.sh' -not -path './.git/*' -exec bash -n {} \;

# Shellcheck (matches what CI runs)
shellcheck -e SC1091 -e SC2034 -e SC2154 \
    nuke.sh install.sh lib/*.sh lib/modules/*.sh
```

---

## Project layout

```
nuke.sh                    Thin entry point; loads lib/ and drives the loop.
install.sh                 Installs the base dependencies. Run with sudo.
lib/core.sh                Colors (TTY-aware), globals, palette.
lib/ui.sh                  ASCII art and menu rendering.
lib/installer.sh           Logging, prompting and install primitives.
lib/modules/config.sh      Target / output config.
lib/modules/passive.sh     Placeholder module.
lib/modules/active.sh      Placeholder module.
lib/modules/special.sh     Placeholder workflows + results viewer.
```

See [ARCHITECTURE.md](ARCHITECTURE.md) for the full description
and [ADDING_A_TOOL.md](ADDING_A_TOOL.md) if you want to plug in
a new tool.

---

## Code conventions

### Shell

- `#!/usr/bin/env bash` shebang on every executable script.
- Strict mode at the entry point only: `set -uo pipefail` for the
  interactive `nuke.sh`, `set -euo pipefail` for the non-interactive
  `install.sh`. **Do not** add `set -e` to interactive menus — a single
  non-zero exit code kills the whole loop.
- Always quote variable expansions: `"${var}"`, not `$var`.
- Function names are `snake_case` and prefixed by their module:
  `passive_action_one`, `config_set_target`, etc.
- Global state lives in `NUKE_*` variables defined in `lib/core.sh`.
- Logging goes through `log_step / log_info / log_warn / log_error /
  log_success`. Do not emit raw `echo -e ${RED}...${RESET}` from
  application code.
- User prompts go through `prompt_value / prompt_password / prompt_yesno`.
- Tool presence is checked with `ensure_command` (and `resolve_command`
  for binaries with multiple possible names).
- Use `mapfile -t arr <<<"$STRING"` or `mapfile -t arr < <(cmd)` for
  array splitting. Avoid the legacy `IFS=$'\n' read -r -d '' -a` pattern.

### Language

Every file in the repository is **English only** — code, comments, log
messages, prompts, README, docs, commit messages. PRs that introduce
non-English content will be asked to translate before merge.

### Comments

Default to writing no comments. Only add one when the *why* is
non-obvious. Don't restate what well-named code already says.

### Commit messages

Conventional Commits:

```
type: short imperative summary
```

Common types: `feat`, `fix`, `refactor`, `docs`, `ci`, `chore`, `test`.

---

## CI

Every PR runs three checks:

1. **shellcheck** with warning severity and a small ignore list
   (`SC1091`, `SC2034`, `SC2154`).
2. **bash -n** on every `.sh` for syntax.
3. **Smoke test** that sources the full `lib/` chain and asserts that
   every public function is defined.

All three must pass before review.

---

## Reporting bugs and proposing tools

- Bugs: open an issue with the **Bug report** template.
- New tools: open an issue with the **Tool request** template. Bonus
  points for opening the PR that wires the tool in.
- Security issues: see [SECURITY.md](SECURITY.md).

---

## Authorized use only

Nuke is a scaffold for security tooling. If you build offensive
capability on top of it, use it only against systems you own or have
explicit written permission to test.
