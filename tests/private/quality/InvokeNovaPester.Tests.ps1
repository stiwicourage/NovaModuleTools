BeforeAll {
    $projectRoot = Split-Path -Parent (Split-Path -Parent (Split-Path -Parent $PSScriptRoot))
    . (Join-Path $projectRoot 'src/private/quality/InvokeNovaPester.ps1')
}

Describe 'Invoke-NovaPester' {
    It 'forwards configuration to Invoke-Pester and returns its result' {
        Mock Invoke-Pester {return [pscustomobject]@{Result = 'Passed'}}
        $config = New-PesterConfiguration
        $result = Invoke-NovaPester -Configuration $config
        $result.Result | Should -Be 'Passed'
        Should -Invoke Invoke-Pester -Times 1
    }
}
