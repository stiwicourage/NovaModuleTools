function Get-NovaPackageMetadataList {
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseSingularNouns', '', Justification = 'Package metadata list is the domain term represented by this helper.')]
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][pscustomobject]$ProjectInfo
    )

    $packageTypeList = @(Get-NovaConfiguredPackageTypeList -PackageSettings $ProjectInfo.Package)
    $includeLatest = Test-NovaPackageLatestEnabled -PackageSettings $ProjectInfo.Package

    return @(
    foreach ($packageType in $packageTypeList) {
        Get-NovaPackageMetadata -ProjectInfo $ProjectInfo -PackageType $packageType
        if ($includeLatest) {
            Get-NovaPackageMetadata -ProjectInfo $ProjectInfo -PackageType $packageType -Latest
        }
    }
    )
}

function Get-NovaConfiguredPackageTypeList {
    [CmdletBinding()]
    param(
        [AllowNull()]$PackageSettings
    )

    $configuredPackageTypes = if ($PackageSettings -is [System.Collections.IDictionary]) {
        @($PackageSettings['Types'])
    }
    else {
        @($PackageSettings.Types)
    }

    $packageTypeList = @($configuredPackageTypes | Where-Object {$_})
    if ($packageTypeList.Count -gt 0) {
        return $packageTypeList
    }

    return @('NuGet')
}

function Test-NovaPackageLatestEnabled {
    [CmdletBinding()]
    param(
        [AllowNull()]$PackageSettings
    )

    if ($PackageSettings -is [System.Collections.IDictionary]) {
        if ( $PackageSettings.Contains('Latest')) {
            return [bool]$PackageSettings['Latest']
        }

        return $false
    }

    if ($null -eq $PackageSettings) {
        return $false
    }

    if ($PackageSettings.PSObject.Properties.Name -contains 'Latest') {
        return [bool]$PackageSettings.Latest
    }

    return $false
}
