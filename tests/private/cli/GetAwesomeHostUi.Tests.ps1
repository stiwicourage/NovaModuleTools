BeforeAll {
    $projectRoot = Split-Path -Parent (Split-Path -Parent (Split-Path -Parent $PSScriptRoot))
    . (Join-Path $projectRoot 'src/private/cli/GetAwesomeHostUi.ps1')
}

Describe 'Get-AwesomeHostUi' {
    It 'returns the current host UI object' {
        Get-AwesomeHostUi | Should -Be $Host.UI
    }
}
