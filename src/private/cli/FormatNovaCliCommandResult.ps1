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

function Format-NovaCliCommandResult {
    [CmdletBinding()]
    param(
        [string]$Command,
        [object]$Result
    )

    if (-not (Test-NovaCliNoUpdateResult -Command $Command -Result $Result)) {
        return $Result
    }

    return @(
        "You're up to date!"
        "$( $Result.ModuleName ) $( $Result.CurrentVersion ) is currently the newest version available."
    )
}

