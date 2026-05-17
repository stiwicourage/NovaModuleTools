BeforeAll {
    $projectRoot = Split-Path -Parent (Split-Path -Parent (Split-Path -Parent $PSScriptRoot))
    . (Join-Path $projectRoot 'src/private/cli/WriteMessage.ps1')
}

Describe 'Write-Message' {
    It 'writes to host without throwing for default color' {
        {Write-Message -Text 'hello' 6> $null} | Should -Not -Throw
    }

    It 'rejects colors outside the supported set' {
        {Write-Message -Text 'hello' -color 'Red'} | Should -Throw
    }
}
