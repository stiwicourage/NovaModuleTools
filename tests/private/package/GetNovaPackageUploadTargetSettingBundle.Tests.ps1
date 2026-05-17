BeforeAll {
    $projectRoot = Split-Path -Parent (Split-Path -Parent (Split-Path -Parent $PSScriptRoot))
    . (Join-Path $projectRoot 'src/private/package/GetNovaPackageUploadTargetSettingBundle.ps1')

    function Get-NovaPackageSettingValue {param($InputObject, $Name) if ($null -eq $InputObject) {return $null}; return $InputObject.$Name}
    function Merge-NovaPackageSettingTable {param($BaseSettings, $OverrideSettings) return [ordered]@{Base=$BaseSettings; Override=$OverrideSettings}}
}

Describe 'Get-NovaPackageUploadTargetSettingBundle' {
    It 'returns a bundle with the repository name and merged settings' {
        $package = [pscustomobject]@{Headers=@{A=1}; Auth=@{S='Bearer'}}
        $repo = [pscustomobject]@{Name='Nexus'; Headers=@{A=2}; Auth=@{S='Basic'}}
        $bundle = Get-NovaPackageUploadTargetSettingBundle -PackageSettings $package -RepositorySettings $repo
        $bundle.Repository | Should -Be 'Nexus'
        $bundle.Headers.Override.A | Should -Be 2
        $bundle.Auth.Override.S | Should -Be 'Basic'
    }
}
