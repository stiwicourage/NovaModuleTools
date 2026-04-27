function Test-NovaCliNoUpdateResult {
    [CmdletBinding()]
    param(
        [string]$Command,
        [object]$Result
    )

    if ($Command -ne 'update' -or $null -eq $Result) {
        return $false
    }

    $propertyNames = @($Result.PSObject.Properties.Name)
    return ($propertyNames -contains 'UpdateAvailable') -and ($propertyNames -contains 'CurrentVersion') -and -not $Result.UpdateAvailable
}

function Test-NovaCliVersionUpdateResult {
    [CmdletBinding()]
    param(
        [string]$Command,
        [object]$Result
    )

    if ($Command -ne 'bump' -or $null -eq $Result) {
        return $false
    }

    $propertyNames = @($Result.PSObject.Properties.Name)
    foreach ($requiredPropertyName in @('PreviousVersion', 'NewVersion', 'Label', 'CommitCount', 'Applied')) {
        if ($propertyNames -notcontains $requiredPropertyName) {
            return $false
        }
    }

    return $true
}

function Format-NovaCliVersionUpdateResult {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][object]$Result
    )

    $summaryPrefix = if ($Result.Applied) {
        'Version bump completed:'
    }
    else {
        'Version plan:'
    }

    return "$summaryPrefix $( $Result.PreviousVersion ) -> $( $Result.NewVersion ) | Label: $( $Result.Label ) | Commits: $( $Result.CommitCount )"
}

function Format-NovaCliCommandResult {
    [CmdletBinding()]
    param(
        [string]$Command,
        [object]$Result
    )

    if (Test-NovaCliNoUpdateResult -Command $Command -Result $Result) {
        return @(
            "You're up to date!"
            "$( $Result.ModuleName ) $( $Result.CurrentVersion ) is currently the newest version available."
        )
    }

    if (Test-NovaCliVersionUpdateResult -Command $Command -Result $Result) {
        return Format-NovaCliVersionUpdateResult -Result $Result
    }

    return $Result
}

