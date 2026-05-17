function Get-NovaPackageMetadataList {
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseSingularNouns', '', Justification = 'Package metadata list is the domain term represented by this helper.')]
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][pscustomobject]$ProjectInfo
    )

    $packageTypeList = @(Get-NovaConfiguredPackageTypeList -PackageSettings $ProjectInfo.Package)
    $includeLatest = Test-NovaPackageLatestEnabled -PackageSettings $ProjectInfo.Package -Version $ProjectInfo.Version

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
    } else {
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
        [AllowNull()]$PackageSettings,
        [Parameter(Mandatory)][string]$Version
    )

    $latestPolicy = Get-NovaPackageLatestPolicy -PackageSettings $PackageSettings
    switch ($latestPolicy) {
        'always' {
            return $true
        }
        'stable' {
            return Test-NovaPackageVersionIsStable -Version $Version
        }
        default {
            return $false
        }
    }
}

function Get-NovaPackageLatestPolicy {
    [CmdletBinding()]
    param(
        [AllowNull()]$PackageSettings
    )

    return ConvertTo-NovaPackageLatestPolicy -Value (Get-NovaPackageSettingValue -InputObject $PackageSettings -Name 'Latest')
}

function Test-NovaPackageVersionIsStable {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][string]$Version
    )

    return [string]::IsNullOrWhiteSpace(([semver]$Version).PreReleaseLabel)
}
