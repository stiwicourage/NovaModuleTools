BeforeAll {
    $projectRoot = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
    . (Join-Path $projectRoot 'src/public/GetNovaProjectInfo.ps1')

    . (Join-Path $PSScriptRoot 'GetNovaProjectInfo.TestSupport.ps1')
}

Describe 'Get-NovaProjectInfo' {
    It 'returns the installed project version when -Installed is set' {
        Get-NovaProjectInfo -Installed | Should -Be 'ProjectX 9.8.7'
    }

    It 'returns the installed NovaModuleTools version when -InstalledNovaVersion is set' {
        Get-NovaProjectInfo -InstalledNovaVersion | Should -Match 'NovaModuleTools 1\.2\.3|.+1\.2\.3'
    }

    It 'returns the project info result when -Version is not set' {
        $result = Get-NovaProjectInfo -Path '/proj'
        $result.Path | Should -Be '/proj'
    }

    It 'returns the version string when -Version is set' {
        Get-NovaProjectInfo -Path '/proj' -Version | Should -Be '9.9.9'
    }
}
