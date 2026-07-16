# SetupVibe

> The ultimate cross-platform development environment setup script — v0.41.6

Installs and configures a complete development stack in one command, supporting Windows, macOS, and major Linux distributions.

## Key Features

- **Smart Privilege Elevation:** Uses UAC on Windows and `sudo` only where required on macOS and Linux.
- **Native Package Management:** Uses WinGet and Chocolatey on Windows, with Homebrew or APT on Unix systems.
- **Modern Shell:** PowerShell 7 + Starship + zoxide on Windows, and ZSH + Oh My Zsh + Starship on Unix systems.
- **Optimized Terminals:** Installs Windows Terminal on Windows and configures Tmux + TPM on Unix systems.
- **AI-Ready:** Includes the latest AI CLI tools for developers.

## Documentation

|                 | Link                                             |
| --------------- | ------------------------------------------------ |
| Overview        | [docs/README.md](docs/README.md)                 |
| Desktop Edition | [docs/desktop/README.md](docs/desktop/README.md) |
| Windows Edition | [docs/windows/README.md](docs/windows/README.md) |
| Server Edition  | [docs/server/README.md](docs/server/README.md)   |
| Tmux Guide      | [docs/desktop/en/tmux.md](docs/desktop/en/tmux.md) |
| PM2 Guide       | [docs/desktop/en/pm2.md](docs/desktop/en/pm2.md) |

## Quick Start

### Desktop (macOS, Linux & WSL)

```bash
curl -sSL desktop.setupvibe.dev | bash
```

### Windows Desktop

Run the Windows installer directly from the official repository. It requests administrator access through UAC automatically.

```powershell
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12; irm https://raw.githubusercontent.com/promovaweb/setupvibe/main/desktop.ps1 | iex
```

See the [Windows installation guide](docs/windows/README.md) for local installation, verification, logs, and restart options.

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
