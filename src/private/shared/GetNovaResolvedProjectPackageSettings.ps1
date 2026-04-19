function Get-NovaResolvedProjectPackageSettings {
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseSingularNouns', '', Justification = 'Package settings is the domain term represented by this resolver.')]
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][hashtable]$ProjectData,
        [Parameter(Mandatory)][hashtable]$ManifestSettings,
        [Parameter(Mandatory)][string]$ProjectRoot
    )

    $packageSettings = if ($ProjectData.ContainsKey('Package') -and $ProjectData['Package'] -is [hashtable]) {
        [ordered]@{} + $ProjectData['Package']
    }
    else {
        [ordered]@{}
    }

    Set-NovaPackageSettingDefault -PackageSettings $packageSettings -Name 'Enabled' -Value $true
    Set-NovaPackageSettingDefault -PackageSettings $packageSettings -Name 'Id' -Value $ProjectData['ProjectName'] -TreatWhitespaceAsMissing
    Set-NovaPackageSettingDefault -PackageSettings $packageSettings -Name 'OutputDirectory' -Value 'artifacts/packages' -TreatWhitespaceAsMissing

    if (-not [System.IO.Path]::IsPathRooted("$( $packageSettings['OutputDirectory'] )")) {
        $null = $packageSettings['OutputDirectory'] = [System.IO.Path]::Join($ProjectRoot, "$( $packageSettings['OutputDirectory'] )")
    }

    Set-NovaPackageSettingDefault -PackageSettings $packageSettings -Name 'PackageFileName' -Value "$( $packageSettings['Id'] ).$( $ProjectData['Version'] ).nupkg" -TreatWhitespaceAsMissing
    Set-NovaPackageSettingDefault -PackageSettings $packageSettings -Name 'Authors' -Value $ManifestSettings['Author']
    Set-NovaPackageSettingDefault -PackageSettings $packageSettings -Name 'Description' -Value $ProjectData['Description'] -TreatWhitespaceAsMissing

    return $packageSettings
}

