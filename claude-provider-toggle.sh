#!/usr/bin/env bash
# claude-provider-toggle.sh
# Drop-in shell snippet for switching Claude Code between multiple API providers.
# Works with bash and zsh. Source this file from your ~/.zshrc or ~/.bashrc.
#
# Usage:
#   claude-switch              # cycle to next profile (alphabetical)
#   claude-switch <name>       # switch to a specific profile
#   claude-status              # show active profile and available profiles
#   claude-status --json       # machine-readable JSON output
#   claude-profiles            # list profiles + instructions for adding new ones
#   claude-run <profile> [cmd] # run a command under a profile without switching globally
#
# Profiles live in ~/.claude-providers/<name>.env
# State file holds the active profile name

CLAUDE_PROVIDER_STATE="$HOME/.claude-provider-state"
[ ! -f "$CLAUDE_PROVIDER_STATE" ] && echo "anthropic" > "$CLAUDE_PROVIDER_STATE"

_load_claude_provider() {
  local provider profile_file
  provider=$(cat "$CLAUDE_PROVIDER_STATE" 2>/dev/null || echo "anthropic")
  provider="${provider%$'\n'}"  # strip trailing newline (portable)
  profile_file="$HOME/.claude-providers/${provider}.env"
  if [ -f "$profile_file" ]; then
    # shellcheck source=/dev/null
    . "$profile_file"
  else
    echo "[claude-toggle] Warning: profile file not found: $profile_file"
  fi
}

# Returns the profile that comes after $1 alphabetically, wrapping around.
_next_claude_profile() {
  local current="$1" first="" found=0 next=""
  while IFS= read -r profile; do
    profile="${profile%$'\n'}"
    [ -z "$first" ] && first="$profile"
    if [ "$found" -eq 1 ]; then
      next="$profile"
      found=0
      break
    fi
    [ "$profile" = "$current" ] && found=1
  done < <(ls "$HOME/.claude-providers/"*.env 2>/dev/null \
           | while IFS= read -r f; do basename "$f" .env; done \
           | sort)
  echo "${next:-$first}"
}

claude-switch() {
  local target
  if [ -n "$1" ]; then
    target="$1"
    if [ ! -f "$HOME/.claude-providers/${target}.env" ]; then
      echo "Unknown profile: $target"
      echo "Available profiles:"
      ls "$HOME/.claude-providers/"*.env 2>/dev/null \
        | while IFS= read -r f; do echo "  $(basename "$f" .env)"; done \
        | sort
      return 1
    fi
    echo "$target" > "$CLAUDE_PROVIDER_STATE"
  else
    local current
    current=$(cat "$CLAUDE_PROVIDER_STATE" 2>/dev/null || echo "anthropic")
    current="${current%$'\n'}"
    local next
    next=$(_next_claude_profile "$current")
    echo "$next" > "$CLAUDE_PROVIDER_STATE"
  fi
  _load_claude_provider
  claude-status
}

claude-status() {
  local provider
  provider=$(cat "$CLAUDE_PROVIDER_STATE" 2>/dev/null || echo "anthropic")
  provider="${provider%$'\n'}"

  # Collect available profiles into a variable
  local profiles_list
  profiles_list=$(ls "$HOME/.claude-providers/"*.env 2>/dev/null \
    | while IFS= read -r f; do basename "$f" .env; done \
    | sort)

  if [ "$1" = "--json" ]; then
    # Emit machine-readable JSON — no jq dependency needed
    local profiles_json=""
    while IFS= read -r p; do
      [ -n "$profiles_json" ] && profiles_json="${profiles_json},"
      profiles_json="${profiles_json}\"${p}\""
    done <<< "$profiles_list"
    printf '{"active":"%s","profiles":[%s]}\n' "$provider" "$profiles_json"
    return
  fi

  echo "--- Claude Provider Status ---"
  echo "Active  : $provider"
  echo "Profile : $HOME/.claude-providers/${provider}.env"
  echo "Available profiles:"
  echo "$profiles_list" | while IFS= read -r p; do echo "  $p"; done
}

claude-profiles() {
  echo "Profiles in ~/.claude-providers/:"
  ls "$HOME/.claude-providers/"*.env 2>/dev/null \
    | while IFS= read -r f; do echo "  $(basename "$f" .env)"; done \
    | sort
  echo ""
  echo "To add a new profile:"
  echo "  1. Create ~/.claude-providers/<name>.env with your export/unset lines"
  echo "  2. Run: claude-switch <name>"
}

# Run a command under a specific provider profile without changing the global active profile.
# The profile is sourced inside a subshell, so the parent shell environment is never modified.
#
# Usage: claude-run <profile> <command> [args...]
# Example: claude-run foundry claude --version
# Example: claude-run bedrock env | grep AWS
claude-run() {
  local profile="$1"
  if [ -z "$profile" ]; then
    echo "Usage: claude-run <profile> <command> [args...]"
    echo "       claude-run <profile>          # open a subshell under that profile"
    return 1
  fi
  local profile_file="$HOME/.claude-providers/${profile}.env"
  if [ ! -f "$profile_file" ]; then
    echo "Unknown profile: $profile"
    echo "Available profiles:"
    ls "$HOME/.claude-providers/"*.env 2>/dev/null \
      | while IFS= read -r f; do echo "  $(basename "$f" .env)"; done \
      | sort
    return 1
  fi
  shift
  if [ "$#" -eq 0 ]; then
    # No command given — open an interactive subshell with the profile loaded
    echo "[claude-toggle] Entering subshell with profile: $profile"
    echo "[claude-toggle] Type 'exit' to return to your original environment."
    (. "$profile_file"; exec "${SHELL:-sh}")
  else
    # Run the given command in a subshell — exec replaces the subshell process
    (. "$profile_file"; exec "$@")
  fi
}

_load_claude_provider
