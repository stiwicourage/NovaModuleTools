function Get-NovaCliHelpUsageText {
    [CmdletBinding()]
    param()

    return "Use 'nova --help', 'nova -h', 'nova --help <command>', 'nova -h <command>', or 'nova <command> --help'/'nova <command> -h'."
}

function Get-NovaCliResolvedHelpRequest {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][string]$Command,
        [ValidateSet('Short', 'Long')][string]$View,
        [ValidateSet('Root', 'Command')][string]$TargetType
    )

    return [pscustomobject]@{
        Command = $Command
        View = $View
        TargetType = $TargetType
        IsHelpRequest = $true
    }
}

function Assert-NovaCliHelpUsageSupported {
    [CmdletBinding()]
    param(
        [AllowEmptyCollection()][string[]]$Tokens = @()
    )

    Stop-NovaOperation -Message "Unsupported help usage. $( Get-NovaCliHelpUsageText )" -ErrorId 'Nova.Validation.UnsupportedCliHelpUsage' -Category InvalidArgument -TargetObject ($Tokens -join ' ')
}

function Get-NovaCliRootHelpRequest {
    [CmdletBinding()]
    param(
        [AllowEmptyCollection()][string[]]$Arguments = @()
    )

    if ($Arguments.Count -eq 0) {
        return Get-NovaCliResolvedHelpRequest -Command '--help' -View Short -TargetType Root
    }

    if ($Arguments.Count -eq 1 -and -not (Test-NovaCliHelpToken -Argument $Arguments[0])) {
        return Get-NovaCliResolvedHelpRequest -Command $Arguments[0] -View Long -TargetType Command
    }

    Assert-NovaCliHelpUsageSupported -Tokens @('--help') + $Arguments
}

function Get-NovaCliSubcommandHelpRequest {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][string]$Command,
        [AllowEmptyCollection()][string[]]$Arguments = @()
    )

    if ($Arguments.Count -eq 0) {
        return $null
    }

    if ($Arguments.Count -eq 1 -and (Test-NovaCliHelpToken -Argument $Arguments[0])) {
        return Get-NovaCliResolvedHelpRequest -Command $Command -View Short -TargetType Command
    }

    if (@($Arguments | Where-Object {Test-NovaCliHelpToken -Argument $_}).Count -gt 0) {
        Assert-NovaCliHelpUsageSupported -Tokens @($Command) + $Arguments
    }

    return $null
}

function Get-NovaCliHelpRequest {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][string]$Command,
        [AllowEmptyCollection()][string[]]$Arguments = @()
    )

    $normalizedCommand = Get-NovaCliNormalizedRootCommand -Command $Command
    if ($normalizedCommand -eq '--help') {
        return Get-NovaCliRootHelpRequest -Arguments $Arguments
    }

    return Get-NovaCliSubcommandHelpRequest -Command $normalizedCommand -Arguments $Arguments
}


