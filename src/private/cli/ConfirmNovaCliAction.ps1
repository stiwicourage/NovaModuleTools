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

function Read-NovaCliConsoleKeyChar {
    [CmdletBinding()]
    param()

    return (Invoke-NovaCliConsoleReadKey).KeyChar
}

function Invoke-NovaCliConsoleReadKey {
    [CmdletBinding()]
    param()

    return [Console]::ReadKey($true)
}

function Read-NovaCliPromptKey {
    [CmdletBinding()]
    param()

    try {
        return Read-NovaCliConsoleKeyChar
    }
    catch {
        return [char]0
    }
}

function Get-NovaCliCommandPromptKey {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][string]$Message
    )

    if (-not [string]::IsNullOrWhiteSpace($env:NOVA_CLI_CONFIRM_RESPONSE)) {
        return [char]$env:NOVA_CLI_CONFIRM_RESPONSE[0]
    }

    Write-Host 'Confirm'
    Write-Host $Message
    Write-Host -NoNewline '[Y] Yes  [A] Yes to All  [N] No  [L] No to All  [S] Suspend  (default is "Y"): '
    return Read-NovaCliPromptKey
}

function Get-NovaCliCommandCancellationInfo {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][string]$Command,
        [Parameter(Mandatory)][char]$KeyChar
    )

    $message = if (($KeyChar.ToString()).ToUpperInvariant() -eq 'S') {
        'Suspend is not supported in nova CLI mode. Operation cancelled.'
    }
    else {
        'Operation cancelled.'
    }

    $errorId = if (($KeyChar.ToString()).ToUpperInvariant() -eq 'S') {
        'Nova.Workflow.CliSuspendNotSupported'
    }
    else {
        'Nova.Workflow.CliOperationCancelled'
    }

    return [pscustomobject]@{
        Command = $Command
        Message = $message
        ErrorId = $errorId
    }
}

function Confirm-NovaCliCommandAction {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][string]$Command
    )

    $message = "Continue with 'nova $Command'?"
    do {
        $keyChar = Get-NovaCliCommandPromptKey -Message $message

        if ($keyChar -eq [char]13 -or $keyChar -eq [char]10) {
            Write-Host
            return
        }

        $decision = Get-NovaCliConfirmDecision -KeyChar $keyChar
        if ($null -eq $decision) {
            Write-Host
            continue
        }

        Write-Host $keyChar

        if (-not $decision) {
            $cancellation = Get-NovaCliCommandCancellationInfo -Command $Command -KeyChar $keyChar
            Stop-NovaOperation -Message $cancellation.Message -ErrorId $cancellation.ErrorId -Category OperationStopped -TargetObject $cancellation.Command
        }

        return
    } while ($true)
}

