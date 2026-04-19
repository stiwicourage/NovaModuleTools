function Get-NovaResolvedProjectPackageSettings {
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseSingularNouns', '', Justification = 'Package settings is the domain term represented by this resolver.')]
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][hashtable]$ProjectData,
        [Parameter(Mandatory)][hashtable]$ManifestSettings,
        [Parameter(Mandatory)][string]$ProjectRoot
    )

    $packageSettings = Get-NovaProjectPackageSettingsTable -ProjectData $ProjectData
    $packageSettings['Types'] = @(Get-NovaResolvedProjectPackageTypeList -PackageSettings $packageSettings)
    $packageSettings['OutputDirectory'] = Get-NovaResolvedProjectPackageOutputDirectorySettings -PackageSettings $packageSettings -ProjectRoot $ProjectRoot
    Set-NovaPackageSettingDefault -PackageSettings $packageSettings -Name 'Id' -Value $ProjectData['ProjectName'] -TreatWhitespaceAsMissing

    Set-NovaPackageSettingDefault -PackageSettings $packageSettings -Name 'PackageFileName' -Value "$( $packageSettings['Id'] ).$( $ProjectData['Version'] ).nupkg" -TreatWhitespaceAsMissing
    Set-NovaPackageSettingDefault -PackageSettings $packageSettings -Name 'FileNamePattern' -Value "$( $packageSettings['Id'] )*" -TreatWhitespaceAsMissing
    Set-NovaPackageSettingDefault -PackageSettings $packageSettings -Name 'Authors' -Value $ManifestSettings['Author']
    Set-NovaPackageSettingDefault -PackageSettings $packageSettings -Name 'Description' -Value $ProjectData['Description'] -TreatWhitespaceAsMissing
    Set-NovaPackageSettingDefault -PackageSettings $packageSettings -Name 'Latest' -Value $false
    Set-NovaPackageSettingDefault -PackageSettings $packageSettings -Name 'Repositories' -Value @()
    Set-NovaPackageSettingDefault -PackageSettings $packageSettings -Name 'Headers' -Value ([ordered]@{})
    Set-NovaPackageSettingDefault -PackageSettings $packageSettings -Name 'Auth' -Value ([ordered]@{})

    $packageSettings['Latest'] = [bool]$packageSettings['Latest']
    $packageSettings['Repositories'] = @($packageSettings['Repositories'])
    $packageSettings['Headers'] = [ordered]@{} + $packageSettings['Headers']
    $packageSettings['Auth'] = [ordered]@{} + $packageSettings['Auth']

    return $packageSettings
}

