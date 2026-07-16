# SetupVibe

> The ultimate cross-platform development environment setup script — v0.41.6

Installs and configures a development environment in one command, supporting Windows 11, macOS, and major Linux distributions. The Windows Edition focuses on native utilities and the WSL 2 base system, while the Unix editions include language ecosystems and AI CLI tools.

## Key Features

- **Administrator Setup:** Requests initial UAC elevation on Windows, then asks whether to disable UAC with `Yes` as the default; uses `sudo` only where required on macOS and Linux.
- **Safe Windows Servicing:** Waits for competing installers, rejects pending restarts, starts required services, validates the component store, and records dedicated DISM logs without forcibly terminating system processes.
- **Native Package Management:** Uses WinGet and Chocolatey on Windows, with Homebrew or APT on Unix systems.
- **Modern Shell:** PowerShell 7 + Starship + zoxide on Windows, and ZSH + Oh My Zsh + Starship on Unix systems.
- **Optimized Terminals:** Installs Windows Terminal on Windows and configures Tmux + TPM on Unix systems.
- **Global Helper Scripts:** Installs Windows helper scripts in `%USERPROFILE%\.setupvibe\bin` and adds the directory to the user's `PATH`.
- **WSL 2 Ready:** Installs the WSL base without a Linux distribution and configures mirrored VPN/LAN networking and development optimizations on Windows 11.
- **AI-Ready Unix Editions:** Includes the latest AI CLI tools for developers on macOS, Linux, and WSL.

## Documentation

|                        | Link                                                       |
| ---------------------- | ---------------------------------------------------------- |
| Overview               | [docs/README.md](docs/README.md)                           |
| Desktop Edition        | [docs/desktop/README.md](docs/desktop/README.md)           |
| Windows Edition (Beta) | [docs/windows/README.md](docs/windows/README.md)           |
| Server Edition         | [docs/server/README.md](docs/server/README.md)             |
| Tmux Guide             | [docs/desktop/en/tmux.md](docs/desktop/en/tmux.md)         |
| PM2 Guide              | [docs/desktop/en/pm2.md](docs/desktop/en/pm2.md)           |

## Quick Start

### Desktop (macOS, Linux & WSL)

```bash
curl -sSL desktop.setupvibe.dev | bash
```

### Windows Desktop (Beta)

Run the Windows utility installer directly from the `windows` development branch. It requests administrator access through UAC automatically, then asks whether to disable UAC with `Yes` as the default.

```powershell
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12; irm https://raw.githubusercontent.com/promovaweb/setupvibe/windows/desktop.ps1 | iex
```

See the [Windows installation guide](docs/windows/README.md) for local installation, verification, logs, restart options, and the `-Uninstall` mode.

### Server (Linux only)

```bash
curl -sSL server.setupvibe.dev | bash
```

To initialize Docker Swarm automatically after setup:

```bash
curl -sSL server.setupvibe.dev | bash -s -- --manager
```

## Contributing

We welcome contributions of all sizes! Please read our [Contribution Guide](CONTRIBUTING.md) to get started.

---

Maintained by [promovaweb.com](https://promovaweb.com) · Licensed under [GPL-3.0](LICENSE)

---
