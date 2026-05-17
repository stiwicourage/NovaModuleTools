BeforeAll {
    $projectRoot = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
    . (Join-Path $projectRoot 'src/public/GetNovaProjectInfo.ps1')

    function Get-NovaCliInstalledVersion {param($Module) return '1.2.3'}
    function Format-NovaCliVersionString {param($Name, $Version) return "$Name $Version"}
    function Get-NovaProjectInfoContext {param($Path) return [pscustomobject]@{Path=$Path}}
    function Get-NovaProjectInfoResult {param($WorkflowContext, [switch]$Version)
        if ($Version) {return '9.9.9'}
        return [pscustomobject]@{Name='X'; Path=$WorkflowContext.Path}
    }
}

Describe 'Get-NovaProjectInfo' {
    It 'returns a formatted installed version when -Installed is set' {
        Get-NovaProjectInfo -Installed | Should -Match 'NovaModuleTools 1\.2\.3|.+1\.2\.3'
    }

    It 'returns the project info result when -Version is not set' {
        $result = Get-NovaProjectInfo -Path '/proj'
        $result.Path | Should -Be '/proj'
    }

    It 'returns the version string when -Version is set' {
        Get-NovaProjectInfo -Path '/proj' -Version | Should -Be '9.9.9'
    }
}
