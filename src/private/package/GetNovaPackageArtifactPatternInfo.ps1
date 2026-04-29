function Get-NovaPackageArtifactPatternInfo {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][pscustomobject]$ProjectInfo
    )

    $pattern = "$( Get-NovaPackageSettingValue -InputObject $ProjectInfo.Package -Name 'FileNamePattern' )".Trim()
    if ( [string]::IsNullOrWhiteSpace($pattern)) {
        $packageId = "$( Get-NovaPackageSettingValue -InputObject $ProjectInfo.Package -Name 'Id' )".Trim()
        $pattern = "$packageId*"
    }

    $explicitPackageType = $null
    if ($pattern -match '(?i)(\.nupkg|\.zip)$') {
        $explicitPackageType = ConvertTo-NovaPackageType -Type $Matches[1]
    }

    return [pscustomobject]@{
        Pattern = $pattern
        ExplicitPackageType = $explicitPackageType
    }
}
