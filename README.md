# Claude Provider Switcher

A lightweight shell snippet that lets you switch [Claude Code](https://claude.ai/code) between multiple API providers — Anthropic direct, Microsoft Azure AI Foundry, AWS Bedrock, Google Cloud Vertex AI — with a single command.

Works on **macOS**, **Linux**, **WSL**, and **Windows** (PowerShell). No dependencies. No config files to learn. Just shell functions.

---

## Commands

| Command | What it does |
|---|---|
| `claude-switch` | Cycle to the next profile (alphabetical) |
| `claude-switch <name>` | Switch to a specific named profile |
| `claude-status` | Show active provider and all available profiles |
| `claude-profiles` | List profiles + instructions for adding new ones |

---

## Quick Start

Choose your platform:

- [macOS / Linux / WSL (bash or zsh)](#macos--linux--wsl)
- [Windows (PowerShell)](#windows-powershell)

---

## macOS / Linux / WSL

### 1. Download the toggle script

```bash
curl -fsSL https://raw.githubusercontent.com/AmanSarraf/claude-provider-switcher/main/claude-provider-toggle.sh \
  -o ~/.claude-provider-toggle.sh
mkdir -p ~/.claude-providers
```

### 2. Source it in your shell config

Add to your `~/.zshrc` or `~/.bashrc`:

```bash
source ~/.claude-provider-toggle.sh
```

Then reload:

```bash
source ~/.zshrc   # or ~/.bashrc
```

### 3. Create your first profile

Copy an example from the [`profiles/`](profiles/) folder:

```bash
# Example: Anthropic direct
cp profiles/anthropic.env.example ~/.claude-providers/anthropic.env
nano ~/.claude-providers/anthropic.env   # fill in your values
```

### 4. Switch to it

```bash
claude-switch anthropic
```

---

## Windows (PowerShell)

Claude Code is available natively on Windows. The PowerShell script mirrors the same commands as the bash version.

### 1. Download the toggle script

```powershell
Invoke-WebRequest `
  -Uri "https://raw.githubusercontent.com/AmanSarraf/claude-provider-switcher/main/claude-provider-toggle.ps1" `
  -OutFile "$HOME\.claude-provider-toggle.ps1"

New-Item -ItemType Directory -Force -Path "$HOME\.claude-providers" | Out-Null
```

### 2. Add it to your PowerShell profile

```powershell
# Open your profile for editing
notepad $PROFILE

# Add this line:
. "$HOME\.claude-provider-toggle.ps1"
```

Then reload:

```powershell
. $PROFILE
```

### 3. Create your first profile

Copy an example from the [`profiles/windows/`](profiles/windows/) folder:

```powershell
Copy-Item profiles\windows\anthropic.ps1.example "$HOME\.claude-providers\anthropic.ps1"
notepad "$HOME\.claude-providers\anthropic.ps1"   # fill in your values
```

### 4. Switch to it

```powershell
claude-switch anthropic
```

> **Git Bash on Windows?** Use the bash script (`claude-provider-toggle.sh`) and Unix `.env` profiles instead — Git Bash is a bash-compatible shell.

---

## How It Works

Each provider is a plain config file in your home directory:

**macOS/Linux/WSL** — `~/.claude-providers/<name>.env`
```bash
~/.claude-providers/
  anthropic.env
  foundry.env
  bedrock.env
```

**Windows** — `$HOME\.claude-providers\<name>.ps1`
```
$HOME\.claude-providers\
  anthropic.ps1
  foundry.ps1
  bedrock.ps1
```

The active profile name is stored in `~/.claude-provider-state` (or `$HOME\.claude-provider-state` on Windows). On every new shell session, the active profile is sourced automatically — so Claude Code always picks up the right environment variables.

Switching is instant. No restarts needed.

---

## Profile Examples

### Unix (bash/zsh/WSL)

Templates are in the [`profiles/`](profiles/) folder:

| File | Provider |
|---|---|
| [`anthropic.env.example`](profiles/anthropic.env.example) | Anthropic direct (API key or OAuth) |
| [`foundry.env.example`](profiles/foundry.env.example) | Microsoft Azure AI Foundry |
| [`bedrock.env.example`](profiles/bedrock.env.example) | AWS Bedrock |
| [`vertex.env.example`](profiles/vertex.env.example) | Google Cloud Vertex AI |

### Windows (PowerShell)

Templates are in the [`profiles/windows/`](profiles/windows/) folder:

| File | Provider |
|---|---|
| [`anthropic.ps1.example`](profiles/windows/anthropic.ps1.example) | Anthropic direct (API key or OAuth) |
| [`foundry.ps1.example`](profiles/windows/foundry.ps1.example) | Microsoft Azure AI Foundry |
| [`bedrock.ps1.example`](profiles/windows/bedrock.ps1.example) | AWS Bedrock |
| [`vertex.ps1.example`](profiles/windows/vertex.ps1.example) | Google Cloud Vertex AI |

---

## Adding a New Profile

### macOS / Linux / WSL

1. Create `~/.claude-providers/<name>.env` with the relevant `export`/`unset` lines
2. Run `claude-switch <name>`

### Windows

1. Create `$HOME\.claude-providers\<name>.ps1` with `$env:VAR = "value"` and `Remove-Item Env:VAR` lines
2. Run `claude-switch <name>`

The `unset`/`Remove-Item` lines are important — they clear the previous provider's variables so they don't bleed into the new session. See the example templates for the right pattern.

---

## Platform Notes

| Platform | Script | Profile format |
|---|---|---|
| macOS | `claude-provider-toggle.sh` | `*.env` |
| Linux | `claude-provider-toggle.sh` | `*.env` |
| WSL | `claude-provider-toggle.sh` | `*.env` |
| Git Bash (Windows) | `claude-provider-toggle.sh` | `*.env` |
| PowerShell (Windows) | `claude-provider-toggle.ps1` | `*.ps1` |

---

## Important: OAuth Accounts

This switcher handles API keys and environment variables freely. However, switching between two different **OAuth/Gmail accounts** still requires:

```bash
claude logout
claude login
```

That's a Claude Code limitation, not this tool's.

---

## Security

- **Never commit your real profile files.** The `.gitignore` in this repo excludes `*.env` (only `*.env.example` files are tracked). Your `.ps1` profiles are outside the repo entirely.
- Restrict permissions on your profiles directory:
  - **macOS/Linux:** `chmod 700 ~/.claude-providers`
  - **Windows:** The directory is under your user profile — no extra steps needed, but avoid sharing it.

---

## Contributing

PRs welcome — especially new provider templates in `profiles/` and `profiles/windows/`. Keep them minimal and well-commented.

---

## License

MIT
