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
    Set-NovaPackageSettingDefault -PackageSettings $packageSettings -Name 'AddVersionToFileName' -Value $false
    Set-NovaPackageSettingDefault -PackageSettings $packageSettings -Name 'FileNamePattern' -Value "$( $packageSettings['Id'] )*" -TreatWhitespaceAsMissing
    Set-NovaPackageSettingDefault -PackageSettings $packageSettings -Name 'Authors' -Value $ManifestSettings['Author']
    Set-NovaPackageSettingDefault -PackageSettings $packageSettings -Name 'Description' -Value $ProjectData['Description'] -TreatWhitespaceAsMissing
    Set-NovaPackageSettingDefault -PackageSettings $packageSettings -Name 'Latest' -Value 'never'
    Set-NovaPackageSettingDefault -PackageSettings $packageSettings -Name 'Repositories' -Value @()
    Set-NovaPackageSettingDefault -PackageSettings $packageSettings -Name 'Headers' -Value ([ordered]@{})
    Set-NovaPackageSettingDefault -PackageSettings $packageSettings -Name 'Auth' -Value ([ordered]@{})

    $packageSettings['Latest'] = ConvertTo-NovaPackageLatestPolicy -Value $packageSettings['Latest']
    $packageSettings['AddVersionToFileName'] = [bool]$packageSettings['AddVersionToFileName']
    $packageSettings['Repositories'] = @($packageSettings['Repositories'])
    $packageSettings['Headers'] = [ordered]@{} + $packageSettings['Headers']
    $packageSettings['Auth'] = [ordered]@{} + $packageSettings['Auth']

    return $packageSettings
}

function ConvertTo-NovaPackageLatestPolicy {
    [CmdletBinding()]
    param(
        [AllowNull()]$Value
    )

    if ($null -eq $Value) {
        return 'never'
    }

    # TODO: Remove legacy boolean Package.Latest handling in the next major version.
    if ($Value -is [bool]) {
        if ($Value) {
            return 'always'
        }

        return 'never'
    }

    $policy = "$Value".Trim()
    if ([string]::IsNullOrWhiteSpace($policy)) {
        return 'never'
    }

    switch -Regex ($policy) {
        '^(?i)never$' {
            return 'never'
        }
        '^(?i)stable$' {
            return 'stable'
        }
        '^(?i)always$' {
            return 'always'
        }
        default {
            Stop-NovaOperation -Message "Invalid project.json Package.Latest value: $Value. Use one of: 'never', 'stable', 'always'." -ErrorId 'Nova.Validation.InvalidPackageLatestPolicy' -Category InvalidData -TargetObject $Value
        }
    }
}
