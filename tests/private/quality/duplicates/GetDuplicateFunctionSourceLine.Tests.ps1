BeforeAll {
    $projectRoot = Split-Path -Parent (Split-Path -Parent (Split-Path -Parent (Split-Path -Parent $PSScriptRoot)))
    . (Join-Path $projectRoot 'src/private/quality/duplicates/GetDuplicateFunctionSourceLine.ps1')
}

Describe 'Get-DuplicateFunctionSourceLine' {
    It 'returns an empty array when the source index is unavailable' {
        @(Get-DuplicateFunctionSourceLine -Key 'Get-Alpha').Count | Should -Be 0
    }

    It 'returns an empty array when the source index does not contain the key' {
        @(Get-DuplicateFunctionSourceLine -Key 'Get-Alpha' -SourceIndex @{Other = @()}).Count | Should -Be 0
    }

    It 'returns a sorted source list with a heading when the key exists' {
        $sourceIndex = @{
            'Get-Alpha' = @(
                [pscustomobject]@{Path = 'src/public/GetAlpha.ps1'; Line = 8}
                [pscustomobject]@{Path = 'src/private/GetAlpha.ps1'; Line = 3}
                [pscustomobject]@{Path = 'src/private/GetAlpha.ps1'; Line = 1}
            )
        }

        $result = Get-DuplicateFunctionSourceLine -Key 'Get-Alpha' -SourceIndex $sourceIndex

        $result | Should -Be @(
            '  - source files:'
            '    - src/private/GetAlpha.ps1:1'
            '    - src/private/GetAlpha.ps1:3'
            '    - src/public/GetAlpha.ps1:8'
        )
    }
}
