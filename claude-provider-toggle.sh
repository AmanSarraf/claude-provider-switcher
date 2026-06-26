#!/usr/bin/env zsh
# claude-provider-toggle.sh
# Drop-in shell snippet for switching Claude Code between multiple API providers.
# Source this file from your ~/.zshrc or ~/.bashrc.
#
# Usage:
#   claude-switch              # cycle to next profile (alphabetical)
#   claude-switch <name>       # switch to a specific profile
#   claude-status              # show active profile and available profiles
#   claude-profiles            # list profiles + instructions for adding new ones

# Profiles live in ~/.claude-providers/<name>.env
# State file holds the active profile name
CLAUDE_PROVIDER_STATE="$HOME/.claude-provider-state"
[ ! -f "$CLAUDE_PROVIDER_STATE" ] && echo "anthropic" > "$CLAUDE_PROVIDER_STATE"

_load_claude_provider() {
  local provider profile_file
  provider=$(cat "$CLAUDE_PROVIDER_STATE" 2>/dev/null || echo "anthropic")
  profile_file="$HOME/.claude-providers/${provider}.env"
  if [ -f "$profile_file" ]; then
    source "$profile_file"
  else
    echo "[claude-toggle] Warning: profile file not found: $profile_file"
  fi
}

claude-switch() {
  local target available
  if [ -n "$1" ]; then
    # Switch to named profile
    target="$1"
    if [ ! -f "$HOME/.claude-providers/${target}.env" ]; then
      echo "Unknown profile: $target"
      echo "Available profiles:"
      ls "$HOME/.claude-providers/"/*.env 2>/dev/null | xargs -I{} basename {} .env | sed 's/^/  /'
      return 1
    fi
    echo "$target" > "$CLAUDE_PROVIDER_STATE"
  else
    # No arg: cycle to next profile alphabetically
    local -a available
    available=($(ls "$HOME/.claude-providers/"/*.env 2>/dev/null | xargs -I{} basename {} .env | sort))
    local current idx next
    current=$(cat "$CLAUDE_PROVIDER_STATE" 2>/dev/null || echo "${available[1]}")
    idx=${available[(i)$current]}
    next="${available[$(( idx % ${#available[@]} + 1 ))]}"
    echo "$next" > "$CLAUDE_PROVIDER_STATE"
  fi
  _load_claude_provider
  claude-status
}

claude-status() {
  local provider profile_file
  provider=$(cat "$CLAUDE_PROVIDER_STATE" 2>/dev/null || echo "anthropic")
  profile_file="$HOME/.claude-providers/${provider}.env"
  echo "--- Claude Provider Status ---"
  echo "Active  : $provider"
  echo "Profile : $profile_file"
  echo "Available profiles:"
  ls "$HOME/.claude-providers/"/*.env 2>/dev/null | xargs -I{} basename {} .env | sed 's/^/  /'
}

claude-profiles() {
  echo "Profiles in ~/.claude-providers/:"
  ls "$HOME/.claude-providers/"/*.env 2>/dev/null | xargs -I{} basename {} .env | sed 's/^/  /'
  echo ""
  echo "To add a new profile:"
  echo "  1. Create ~/.claude-providers/<name>.env with your export/unset lines"
  echo "  2. Run: claude-switch <name>"
}

_load_claude_provider
