<p align="center">
  <a href="LICENSE"><img alt="License: MIT" src="https://img.shields.io/badge/License-MIT-yellow.svg"></a>
  <a href=".github/workflows/ci.yml"><img alt="CI" src="https://github.com/WhiteMuush/Nuke/actions/workflows/ci.yml/badge.svg"></a>
  <a href="docs/CONTRIBUTING.md"><img alt="PRs welcome" src="https://img.shields.io/badge/PRs-welcome-brightgreen.svg"></a>
  <a href="https://github.com/koalaman/shellcheck"><img alt="Shellcheck" src="https://img.shields.io/badge/lint-shellcheck-blue.svg"></a>
</p>

**Nuke** is a skeleton for building an interactive Bash toolkit. It gives you
the framework — a TTY-aware color palette, logging and prompting helpers, a
side-by-side ASCII-art menu renderer, install primitives and a modular
`passive / active / special` layout — and leaves the tool logic for you to
fill in. Placeholder actions show the canonical shape so you can drop in real
tools without wiring plumbing.

## What you get

### Framework
- TTY-aware color palette (plain text when piped).
- Logging (`log_step / log_info / log_warn / log_error / log_success`).
- Prompting (`prompt_value / prompt_password / prompt_yesno`).
- Install primitives (`apt_install`, `pipx_install`, `pip_install`,
  `clone_or_pull`, ...).
- Menu rendering with a boot splash and per-menu banners.

### Modular layout
- `config` — set the target and output directory.
- `passive` / `active` / `special` — placeholder modules with example
  actions following the standard five-line shape.

---

## Installation

Nuke targets Debian / Ubuntu / Kali and bundles a base installer:

```bash
sudo ./install.sh
```

The installer sets up the base tooling (git, Python, pipx, build) and the
chaos tools the layers rely on: kubectl, kind, helm, docker, stress-ng,
iproute2 (tc), iptables, pumba and toxiproxy-cli. The Kubernetes and
container-chaos binaries are pulled from their latest upstream release into
`/usr/local/bin`; the rest come from apt.

### Other distros and macOS

Runs natively on Debian / Ubuntu / Kali. On Fedora, Arch, openSUSE, an atomic
distro (Bazzite, Silverblue) or macOS, the chaos tools it drives (`tc`/`netem`,
`stress-ng`, `pumba`, `kubectl`, ...) are Linux-only, so at startup Nuke offers
to relaunch itself inside a shared lightweight Debian box (podman preferred,
docker as a fallback). The same box is reused by the sibling toolkits under the
same parent directory, so it is built once. Three environment variables tune it:

- `PENTEST_BOX_NAME=<name>` forces a box name (highest priority).
- `PENTEST_BOX_DEDICATED=1` gives Nuke its own box (`pentest-nuke`).
- `PENTEST_BOX_IMAGE=<image>` overrides the base image (default
  `debian:stable-slim`).

Engagement output persists on the host under `PENTEST_ENGAGEMENTS_DIR`
(default `~/pentest-engagements`). On a Debian host, or once already inside the
box, Nuke runs directly with no prompt. The headless `nuke.sh run <experiment>`
path is not gated and runs in place, since replays are meant for a Debian CI
runner.

### Running Nuke

```bash
git clone https://github.com/WhiteMuush/Nuke.git
cd Nuke
chmod +x nuke.sh
./nuke.sh
```

---

## Quick start

```bash
./nuke.sh

# 1. Configure your target
Main Menu → [1] Configuration Menu
    → [1] Set Target: 192.168.1.10
    → [0] Back

# 2. Run a placeholder action
Main Menu → [2] Passive Module
    → [1] Action One

# Output directory: nuke_out_YYYYMMDD_HHMMSS/
```

To turn a placeholder into a real tool, follow
[docs/ADDING_A_TOOL.md](docs/ADDING_A_TOOL.md).

---

## Project layout

```
nuke.sh                    Entry point (~50 lines).
install.sh                 Installs base dependencies.
lib/
├── core.sh                Colors (TTY-aware), palette, globals.
├── ui.sh                  ASCII art and menu rendering.
├── installer.sh           Logging, prompting, install primitives.
├── compat.sh              Non-Debian / macOS gate: shared Debian box.
└── modules/
    ├── config.sh          Target / output config.
    ├── passive.sh         Placeholder module.
    ├── active.sh          Placeholder module.
    └── special.sh         Placeholder workflows + results viewer.
docs/
├── ARCHITECTURE.md        Layout, boot sequence, helpers, CI.
├── ADDING_A_TOOL.md       Recipe for plugging in a new tool.
├── CONTRIBUTING.md        Local setup, conventions, PR checklist.
├── CODE_OF_CONDUCT.md     Community standards.
└── SECURITY.md            Private vulnerability disclosure.
.github/
├── workflows/ci.yml       shellcheck + bash -n + smoke test.
├── ISSUE_TEMPLATE/        Structured bug and tool-request forms.
└── PULL_REQUEST_TEMPLATE.md
```

See [docs/ARCHITECTURE.md](docs/ARCHITECTURE.md) for details and
[docs/CONTRIBUTING.md](docs/CONTRIBUTING.md) for the contribution workflow.

---

## Contributing

Contributions are welcome. See [docs/CONTRIBUTING.md](docs/CONTRIBUTING.md) for the
local setup, the conventions and the PR checklist. To plug in a new tool,
[docs/ADDING_A_TOOL.md](docs/ADDING_A_TOOL.md) walks through the recipe in
under a page.

- Bug reports and tool requests use the templates in
  [.github/ISSUE_TEMPLATE/](.github/ISSUE_TEMPLATE/).
- Security issues should be reported privately, see
  [docs/SECURITY.md](docs/SECURITY.md).

---

## License

Nuke is released under the [MIT License](LICENSE). Anything you build on
top of it: use only against systems you own or have explicit written
permission to test.
