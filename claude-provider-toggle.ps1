# claude-provider-toggle.ps1
# Drop-in PowerShell snippet for switching Claude Code between multiple API providers on Windows.
# Dot-source this file from your PowerShell profile ($PROFILE).
#
# Usage:
#   claude-switch              # cycle to next profile (alphabetical)
#   claude-switch <name>       # switch to a specific profile
#   claude-status              # show active profile and available profiles
#   claude-profiles            # list profiles + instructions for adding new ones
#   claude-run <profile> [cmd] # run a command under a profile without switching globally
#
# Profiles live in $HOME\.claude-providers\<name>.ps1
# State file holds the active profile name

$script:ClaudeProviderDir   = Join-Path $HOME ".claude-providers"
$script:ClaudeProviderState = Join-Path $HOME ".claude-provider-state"

if (-not (Test-Path $ClaudeProviderState)) {
    "anthropic" | Set-Content $ClaudeProviderState -NoNewline
}

function script:_Load-ClaudeProvider {
    $provider = (Get-Content $ClaudeProviderState -ErrorAction SilentlyContinue) -replace '\s', ''
    if (-not $provider) { $provider = "anthropic" }
    $profileFile = Join-Path $ClaudeProviderDir "$provider.ps1"
    if (Test-Path $profileFile) {
        . $profileFile
    } else {
        Write-Warning "[claude-toggle] Profile file not found: $profileFile"
    }
}

function global:claude-switch {
    param([string]$Target)

    if ($Target) {
        $profileFile = Join-Path $ClaudeProviderDir "$Target.ps1"
        if (-not (Test-Path $profileFile)) {
            Write-Host "Unknown profile: $Target"
            Write-Host "Available profiles:"
            Get-ChildItem "$ClaudeProviderDir\*.ps1" -ErrorAction SilentlyContinue `
              | Sort-Object BaseName `
              | ForEach-Object { Write-Host "  $($_.BaseName)" }
            return
        }
        $Target | Set-Content $ClaudeProviderState -NoNewline
    } else {
        $current  = (Get-Content $ClaudeProviderState -ErrorAction SilentlyContinue) -replace '\s', ''
        $profiles = Get-ChildItem "$ClaudeProviderDir\*.ps1" -ErrorAction SilentlyContinue `
                    | Sort-Object BaseName `
                    | Select-Object -ExpandProperty BaseName
        if (-not $profiles) {
            Write-Warning "[claude-toggle] No profiles found in $ClaudeProviderDir"
            return
        }
        $idx  = [array]::IndexOf($profiles, $current)
        $next = if ($idx -eq -1 -or $idx -ge ($profiles.Count - 1)) { $profiles[0] } else { $profiles[$idx + 1] }
        $next | Set-Content $ClaudeProviderState -NoNewline
    }
    _Load-ClaudeProvider
    claude-status
}

function global:claude-status {
    $provider = (Get-Content $ClaudeProviderState -ErrorAction SilentlyContinue) -replace '\s', ''
    if (-not $provider) { $provider = "anthropic" }
    Write-Host "--- Claude Provider Status ---"
    Write-Host "Active  : $provider"
    Write-Host "Profile : $(Join-Path $ClaudeProviderDir "$provider.ps1")"
    Write-Host "Available profiles:"
    Get-ChildItem "$ClaudeProviderDir\*.ps1" -ErrorAction SilentlyContinue `
      | Sort-Object BaseName `
      | ForEach-Object { Write-Host "  $($_.BaseName)" }
}

function global:claude-profiles {
    Write-Host "Profiles in $ClaudeProviderDir\"
    Get-ChildItem "$ClaudeProviderDir\*.ps1" -ErrorAction SilentlyContinue `
      | Sort-Object BaseName `
      | ForEach-Object { Write-Host "  $($_.BaseName)" }
    Write-Host ""
    Write-Host "To add a new profile:"
    Write-Host "  1. Create $ClaudeProviderDir\<name>.ps1 with your `$env: lines"
    Write-Host "  2. Run: claude-switch <name>"
}

# Run a command under a specific provider profile without changing the global active profile.
# Snapshots all relevant env vars before loading the profile, runs the command,
# then restores the original values so the parent session is never modified.
#
# Usage: claude-run <profile> <command> [args...]
# Example: claude-run foundry claude --version
# Example: claude-run bedrock pwsh -Command 'Get-ChildItem Env:AWS*'
function global:claude-run {
    param(
        [Parameter(Mandatory=$true, Position=0)][string]$Profile,
        [Parameter(ValueFromRemainingArguments=$true)][string[]]$Command
    )

    $profileFile = Join-Path $ClaudeProviderDir "$Profile.ps1"
    if (-not (Test-Path $profileFile)) {
        Write-Host "Unknown profile: $Profile"
        Write-Host "Available profiles:"
        Get-ChildItem "$ClaudeProviderDir\*.ps1" -ErrorAction SilentlyContinue `
          | Sort-Object BaseName `
          | ForEach-Object { Write-Host "  $($_.BaseName)" }
        return
    }

    # All env vars our profiles may touch — snapshot before loading
    $trackedVars = @(
        'ANTHROPIC_API_KEY',
        'CLAUDE_CODE_USE_FOUNDRY', 'ANTHROPIC_FOUNDRY_RESOURCE', 'ANTHROPIC_FOUNDRY_API_KEY',
        'ANTHROPIC_DEFAULT_SONNET_MODEL', 'ANTHROPIC_DEFAULT_OPUS_MODEL', 'ANTHROPIC_DEFAULT_HAIKU_MODEL',
        'CLAUDE_CODE_USE_BEDROCK', 'AWS_ACCESS_KEY_ID', 'AWS_SECRET_ACCESS_KEY', 'AWS_REGION',
        'CLAUDE_CODE_USE_VERTEX', 'ANTHROPIC_VERTEX_PROJECT_ID', 'CLOUD_ML_REGION'
    )
    $snapshot = @{}
    foreach ($var in $trackedVars) {
        $snapshot[$var] = [System.Environment]::GetEnvironmentVariable($var)
    }

    try {
        . $profileFile
        if ($Command) {
            & $Command[0] $Command[1..($Command.Count - 1)]
        } else {
            Write-Host "[claude-toggle] Profile '$Profile' loaded in current session."
            Write-Host "[claude-toggle] Note: on PowerShell, open a new pwsh session for full isolation."
        }
    } finally {
        # Always restore — even if the command throws
        foreach ($var in $trackedVars) {
            if ($null -eq $snapshot[$var]) {
                Remove-Item "Env:$var" -ErrorAction SilentlyContinue
            } else {
                Set-Item "Env:$var" $snapshot[$var]
            }
        }
    }
}

_Load-ClaudeProvider
