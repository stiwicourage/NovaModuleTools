function Get-NovaCliConfirmDecision {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][char]$KeyChar
    )

    switch ( ($KeyChar.ToString()).ToUpperInvariant()) {
        'Y' {
            return $true
        }
        'A' {
            return $true
        }
        'N' {
            return $false
        }
        'L' {
            return $false
        }
        'S' {
            return $false
        }
        default {
            return $null
        }
    }
}

function Read-NovaCliPromptKey {
    [CmdletBinding()]
    param()

    try {
        return [Console]::ReadKey($true).KeyChar
    }
    catch {
        return [char]0
    }
}

function Confirm-NovaCliBumpAction {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][string]$Target,
        [Parameter(Mandatory)][string]$Action
    )

    if (-not [string]::IsNullOrWhiteSpace($env:NOVA_CLI_CONFIRM_RESPONSE)) {
        return Get-NovaCliConfirmDecision -KeyChar ([char]$env:NOVA_CLI_CONFIRM_RESPONSE[0])
    }

    $message = "Performing the operation `"$Action`" on target `"$Target`"."
    do {
        Write-Host 'Confirm'
        Write-Host $message
        Write-Host -NoNewline '[Y] Yes  [A] Yes to All  [N] No  [L] No to All  [S] Suspend  (default is "Y"): '
        $keyChar = Read-NovaCliPromptKey
        if ($keyChar -eq [char]13 -or $keyChar -eq [char]10) {
            Write-Host
            return $true
        }

        $decision = Get-NovaCliConfirmDecision -KeyChar $keyChar
        if ($null -ne $decision) {
            Write-Host $keyChar
            return $decision
        }

        Write-Host
    } while ($true)
}
