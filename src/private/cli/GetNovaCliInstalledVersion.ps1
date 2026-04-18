function Get-NovaCliInstalledVersion {
    [CmdletBinding()]
    param(
        [object]$Module = $ExecutionContext.SessionState.Module
    )

    $installedVersion = $Module.Version.ToString()
    $prereleaseLabel = $null
    $psData = $Module.PrivateData.PSData

    if ($psData -is [hashtable]) {
        $prereleaseLabel = $psData['Prerelease']
    }
    elseif ($null -ne $psData -and $psData.PSObject.Properties.Name -contains 'Prerelease') {
        $prereleaseLabel = $psData.Prerelease
    }

    if ( [string]::IsNullOrWhiteSpace($prereleaseLabel)) {
        return $installedVersion
    }

    return "$installedVersion-$prereleaseLabel"
}

