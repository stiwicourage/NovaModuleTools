BeforeAll {
    $projectRoot = Split-Path -Parent (Split-Path -Parent (Split-Path -Parent $PSScriptRoot))
    . (Join-Path $projectRoot 'src/private/quality/GetNovaPesterRuntimeMajorVersion.ps1')
}

Describe 'Get-NovaPesterRuntimeMajorVersion' {
    It 'prefers the Invoke-Pester command version when it is available' {
        Mock Get-Command {
            [pscustomobject]@{Version = [version]'6.0.0'}
        } -ParameterFilter {$Name -eq 'Invoke-Pester'}
        Mock Get-Module {}

        Get-NovaPesterRuntimeMajorVersion | Should -Be 6
        Should -Invoke Get-Module -Times 0
    }

    It 'falls back to the highest available Pester module version when the command is unavailable' {
        Mock Get-Command {$null} -ParameterFilter {$Name -eq 'Invoke-Pester'}
        Mock Get-Module {
            @(
                [pscustomobject]@{Version = [version]'5.8.0'}
                [pscustomobject]@{Version = [version]'6.0.0'}
            )
        } -ParameterFilter {$Name -eq 'Pester' -and $ListAvailable}

        Get-NovaPesterRuntimeMajorVersion | Should -Be 6
    }

    It 'returns null when Pester is unavailable' {
        Mock Get-Command {$null} -ParameterFilter {$Name -eq 'Invoke-Pester'}
        Mock Get-Module {$null} -ParameterFilter {$Name -eq 'Pester' -and $ListAvailable}

        Get-NovaPesterRuntimeMajorVersion | Should -BeNullOrEmpty
    }
}

