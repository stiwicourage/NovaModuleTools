BeforeAll {
    $projectRoot = Split-Path -Parent (Split-Path -Parent (Split-Path -Parent $PSScriptRoot))
    . (Join-Path $projectRoot 'src/private/package/GetNovaPackageArtifactPatternInfo.ps1')

    function Get-NovaPackageSettingValue {param($InputObject, $Name) return $InputObject.$Name}
    function ConvertTo-NovaPackageType {param($Type) if ($Type -match 'zip') {'Zip'} else {'NuGet'}}
}

Describe 'Get-NovaPackageArtifactPatternInfo' {
    It 'derives pattern from PackageId when FileNamePattern is empty' {
        $project = [pscustomobject]@{Package=[pscustomobject]@{FileNamePattern=''; Id='X'}}
        $info = Get-NovaPackageArtifactPatternInfo -ProjectInfo $project
        $info.Pattern | Should -Be 'X*'
        $info.ExplicitPackageType | Should -BeNullOrEmpty
    }

    It 'returns the explicit package type when the pattern ends with a known extension' {
        $project = [pscustomobject]@{Package=[pscustomobject]@{FileNamePattern='X*.zip'; Id='X'}}
        $info = Get-NovaPackageArtifactPatternInfo -ProjectInfo $project
        $info.Pattern | Should -Be 'X*.zip'
        $info.ExplicitPackageType | Should -Be 'Zip'
    }
}
