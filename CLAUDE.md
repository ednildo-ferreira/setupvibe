# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What This Project Is

**SetupVibe** is a cross-platform automated development environment setup script (v0.41.6). It installs and configures a complete developer toolkit in one command, supporting macOS 12+ and Linux (Ubuntu 24.04+, Debian 12+, Zorin OS 18+).

There are two editions:

- `desktop.sh` — macOS & Linux desktops; full stack including language ecosystems, GUI tools, and AI CLIs
- `server.sh` — Linux-only; lean install focused on DevOps tools, Docker, shell, and monitoring

## How to Run

There are no build tools, package managers, or test suites. Scripts are executed directly:

```bash
# Run locally
bash desktop.sh
bash server.sh

# Or via curl (canonical usage)
curl -sSL desktop.setupvibe.dev | bash
```

To test changes to a script, run it directly on a target machine or VM.

## Architecture

### Script Structure

Both `desktop.sh` and `server.sh` follow a numbered-step pattern (functions prefixed with `step_NN_`). Each step installs a logical group of tools. The scripts:

1. Detect OS, distro, and CPU architecture (`x86_64` vs `arm64/aarch64`)
2. Detect how the script was invoked (as root, via `sudo`, or as normal user) to correctly identify `$REAL_USER` and `$REAL_HOME`
3. Use `sudo` only where elevated privileges are required; everything else installs into `$HOME/.local/bin`
4. Clean up legacy APT repository entries before adding new ones (avoids GPG signature errors)

### `desktop.sh` Steps (14)

1. Base system & build tools
2. Homebrew
3. PHP 8.5 (Composer, Laravel)
4. Ruby 3.4.10 (rbenv, Rails)
5. Go 1.26.5, Rust, Python (uv; Python 3.14 on macOS)
6. JavaScript (Node, Bun, PNPM)
7. DevOps (Docker, Ansible, GitHub CLI)
8. Modern Unix tools via Homebrew
9. Network, monitoring & Tailscale
10. SSH server (Linux only)
11. ZSH, Oh-My-Zsh, Starship
12. Tmux & TPM plugins
13. AI CLI tools (includes n8n)
14. Finalization & cleanup

### `server.sh` Steps (9)

Subset of desktop steps — no Homebrew, no language ecosystems (PHP, Ruby, Python, Go, Rust) or desktop-specific tools. Node.js is installed via NodeSource APT repo. Focus on base tools, Docker, Ansible, shell, tmux, monitoring, and AI CLIs.

### `docs/` Directory

| Path                        | Content                                                           |
| --------------------------- | ----------------------------------------------------------------- |
| `docs/README.md`            | Overview and comparison table of both editions                    |
| `docs/desktop/en/README.md` | Full desktop edition documentation (14 steps)                     |
| `docs/server/en/README.md`  | Server edition documentation (9 steps)                            |
| `docs/en/EXECUTABLES.md`    | Executable helper script documentation (shared by both editions)  |
| `docs/desktop/en/tmux.md`   | Tmux plugin and keybinding reference (shared by both editions)    |
| `docs/desktop/en/pm2.md`    | PM2 command and configuration reference (shared by both editions) |

### `conf/` Directory

Configuration files deployed by the scripts to the user's home directory:

| File                  | Deployed to                | Purpose                                                                       |
| --------------------- | -------------------------- | ----------------------------------------------------------------------------- |
| `tmux-desktop.conf`   | `~/.tmux.conf` (desktop)   | Tmux with TPM; 20+ plugins, onedark theme, mouse support, session persistence |
| `tmux-server.conf`    | `~/.tmux.conf` (server)    | Lean tmux config for server environments                                      |
| `zshrc-macos.zsh`     | `~/.zshrc` (macOS)         | Homebrew, Cargo, Composer, Go, Bun, rbenv paths                               |
| `zshrc-linux.zsh`     | `~/.zshrc` (Linux desktop) | Linuxbrew paths, NPM, system aliases                                          |
| `zshrc-server.zsh`    | `~/.zshrc` (server)        | Server-specific shell config                                                  |
| `ecosystem.config.js` | Used with PM2              | PM2 config for two app processes                                              |

### `bin/` Directory

Executable helper scripts deployed by the installers to `~/.setupvibe/bin`:

| File         | Deployed to                    | Purpose                                                                                                 |
| ------------ | ------------------------------ | ------------------------------------------------------------------------------------------------------- |
| `sshcopykey` | `~/.setupvibe/bin/sshcopykey` | Copies the local public SSH key to a remote server using `--host`, `--user`, and optional `--pass` or hidden password prompt |

## Key Scripting Patterns

**User detection** — scripts handle being run as root, `sudo bash`, or plain user:

```bash
REAL_USER="${SUDO_USER:-$(whoami)}"
REAL_HOME=$(getent passwd "$REAL_USER" | cut -d: -f6)
```

**APT keyring management** — keyrings go in `/etc/apt/keyrings/`; legacy entries in `/etc/apt/sources.list.d/` are removed before re-adding to avoid signature errors.

**APT lock waiting** — server script polls for APT lock release before running apt commands (needed for cloud VMs with unattended-upgrades running at boot).

**Architecture detection**:

```bash
ARCH_RAW=$(dpkg --print-architecture)  # amd64 or arm64
```

## Versioning

The version number is defined at the top of both `desktop.sh` and `server.sh`. **Whenever a version is changed, it must be updated in ALL related files to maintain consistency**, including:

- `desktop.sh` (version variable)
- `server.sh` (version variable)
- `CHANGELOG.md` (new entry)
- `README.md` (root project overview)
- `AGENTS.md` (project overview)
- `CLAUDE.md` (project overview)
- All `README.md` files in the `docs/` directory and its subfolders.
- Any other documentation referring to the current version.

## Markdown Standards

All `.md` files in this project must conform to the rules defined in [`MARKDOWN.md`](MARKDOWN.md). That file is the single source of truth for formatting rules, markdownlint rule IDs, configuration, and examples.

The linting configuration is in [`.markdownlint.json`](.markdownlint.json) at the project root.

Use the `/markdown-format` skill to verify and apply these rules across all Markdown files.

## AI Context and Skill Synchronization

**`AGENTS.md` and `CLAUDE.md` are the two primary AI context files for this project.** They must always be kept in sync with each other for shared project rules.

### Context Rule

Whenever either file is modified — to add a new convention, update architecture information, change a rule, or correct an error — the **same shared change must be applied to the other file** before the task is considered complete.

### Skill Rule

Codex and Claude maintain separate skill folders:

- `.codex/skills` — Codex-specific skills using Codex terminology, tools, and workflows.
- `.claude/skills` — Claude-specific skills using Claude Code terminology, tools, and workflows.

Whenever a skill is added, removed, renamed, or materially changed in one folder, the equivalent skill must be updated in the other folder. The workflows should stay functionally aligned, but platform-specific instructions must remain native to each agent.

### Scope

This synchronization rule covers:

- Project overview and version references
- Architecture descriptions and step counts
- Key scripting patterns and conventions
- Versioning policy (the list of files to update)
- Markdown standards reference
- Skill inventory and cross-agent skill compatibility rules
- Any new global rule or policy added to one file

### What is NOT synchronized

Each file may contain sections specific to its target agent (tool-specific invocation syntax, skill references, etc.). Those sections are intentionally different and must not be overwritten.

No third AI agent context is maintained for this repository. Do not add extra agent context files, skill folders, or synchronization requirements unless the project explicitly adopts that agent.

---
