# Claude Provider Switcher

A lightweight shell snippet that lets you switch [Claude Code](https://claude.ai/code) between multiple API providers — Anthropic direct, Microsoft Azure AI Foundry, AWS Bedrock, Google Vertex AI — with a single command.

No dependencies. No config files to learn. Just shell functions.

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

### 1. Copy the toggle script

```zsh
mkdir -p ~/.claude-providers
curl -fsSL https://raw.githubusercontent.com/AmanSarraf/claude-provider-switcher/main/claude-provider-toggle.sh \
  -o ~/.claude-provider-toggle.sh
```

### 2. Source it in your shell config

Add to your `~/.zshrc` or `~/.bashrc`:

```zsh
source ~/.claude-provider-toggle.sh
```

Then reload:

```zsh
source ~/.zshrc
```

### 3. Create your first profile

Copy an example from the `profiles/` folder:

```zsh
# Example: Anthropic direct
cp profiles/anthropic.env.example ~/.claude-providers/anthropic.env
# Edit it and add your API key
nano ~/.claude-providers/anthropic.env
```

### 4. Switch to it

```zsh
claude-switch anthropic
```

---

## How It Works

Each provider is a plain `.env` file in `~/.claude-providers/`:

```
~/.claude-providers/
  anthropic.env
  foundry.env
  bedrock.env
  vertex.env
```

The active profile name is stored in `~/.claude-provider-state`. On every new shell session, the active profile is sourced automatically — so Claude Code always picks up the right environment variables.

Switching is instant. No restarts needed.

---

## Profile Examples

Ready-to-use templates are in the [`profiles/`](profiles/) folder:

| File | Provider |
|---|---|
| [`anthropic.env.example`](profiles/anthropic.env.example) | Anthropic direct (API key or OAuth) |
| [`foundry.env.example`](profiles/foundry.env.example) | Microsoft Azure AI Foundry |
| [`bedrock.env.example`](profiles/bedrock.env.example) | AWS Bedrock |
| [`vertex.env.example`](profiles/vertex.env.example) | Google Cloud Vertex AI |

Copy the one you need to `~/.claude-providers/<name>.env` and fill in your values.

---

## Adding a New Profile

1. Create `~/.claude-providers/<name>.env` with the relevant `export`/`unset` lines
2. Run `claude-switch <name>`

The `unset` lines are important — they clear the previous provider's variables so they don't bleed into the new session. See the example templates for the right pattern.

---

## Important: OAuth Accounts

This switcher handles API keys and environment variables freely. However, switching between two different **OAuth/Gmail accounts** still requires:

```zsh
claude logout
claude login
```

That's a Claude Code limitation, not this tool's.

---

## Security

- **Never commit your real `.env` files.** The `.gitignore` in this repo excludes `*.env` (only `*.env.example` files are tracked).
- Store `~/.claude-providers/` with restricted permissions: `chmod 700 ~/.claude-providers`

---

## Contributing

PRs welcome — especially new provider templates in `profiles/`. Keep them minimal and well-commented.

---

## License

MIT
