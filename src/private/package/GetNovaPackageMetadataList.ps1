function Get-NovaPackageMetadataList {
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseSingularNouns', '', Justification = 'Package metadata list is the domain term represented by this helper.')]
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][pscustomobject]$ProjectInfo
    )

    $packageSettings = $ProjectInfo.Package
    $configuredPackageTypes = if ($packageSettings -is [System.Collections.IDictionary]) {
        @($packageSettings['Types'])
    }
    else {
        @($packageSettings.Types)
    }

    $packageTypeList = @($configuredPackageTypes | Where-Object {$_})
    if ($packageTypeList.Count -eq 0) {
        $packageTypeList = @('NuGet')
    }

    return @(
    $packageTypeList | ForEach-Object {
        Get-NovaPackageMetadata -ProjectInfo $ProjectInfo -PackageType $_
    }
    )
}
