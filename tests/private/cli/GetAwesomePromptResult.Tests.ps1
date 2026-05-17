BeforeAll {
    $projectRoot = Split-Path -Parent (Split-Path -Parent (Split-Path -Parent $PSScriptRoot))
    . (Join-Path $projectRoot 'src/private/cli/GetAwesomePromptResult.ps1')

    function Get-AwesomePromptValue {param($Ask, [string]$Name) return 'fallback'}
}

Describe 'Get-AwesomePromptResult' {
    It 'returns the response value when populated' {
        $response = [pscustomobject]@{Values = 'user-typed'}
        Get-AwesomePromptResult -Ask @{} -Response $response | Should -Be 'user-typed'
    }

    It 'returns the default ask value when the response is empty' {
        $response = [pscustomobject]@{Values = ''}
        Mock Get-AwesomePromptValue {return 'default-value'} -ParameterFilter {$Name -eq 'Default'}
        Get-AwesomePromptResult -Ask @{} -Response $response | Should -Be 'default-value'
    }
}
