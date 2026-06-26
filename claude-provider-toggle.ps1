# claude-provider-toggle.ps1
# Drop-in PowerShell snippet for switching Claude Code between multiple API providers on Windows.
# Dot-source this file from your PowerShell profile ($PROFILE).
#
# Usage:
#   claude-switch              # cycle to next profile (alphabetical)
#   claude-switch <name>       # switch to a specific profile
#   claude-status              # show active profile and available profiles
#   claude-profiles            # list profiles + instructions for adding new ones
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

_Load-ClaudeProvider
