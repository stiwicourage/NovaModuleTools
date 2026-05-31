BeforeAll {
    $script:projectRoot = Split-Path -Parent $PSScriptRoot
    $script:publicSourceDirectory = Join-Path $script:projectRoot 'src/public'
    $script:publicTestDirectory = Join-Path $script:projectRoot 'tests/public'
    $script:sourceStemList = @(
        Get-ChildItem -LiteralPath $script:publicSourceDirectory -Filter '*.ps1' -File |
            ForEach-Object BaseName |
            Sort-Object
    )
}

Describe 'Public command test ownership' {
    It 'keeps mirrored unit tests for every public command source file' {
        $unitTestStemList = @(
            Get-ChildItem -LiteralPath $script:publicTestDirectory -Filter '*.Tests.ps1' -File |
                Where-Object Name -notlike '*.Integration.Tests.ps1' |
                ForEach-Object { $_.Name -replace '\.Tests\.ps1$', '' } |
                Sort-Object
        )

        $unitTestStemList | Should -Be $script:sourceStemList
    }

    It 'keeps mirrored integration tests for every public command source file' {
        $integrationTestStemList = @(
            Get-ChildItem -LiteralPath $script:publicTestDirectory -Filter '*.Integration.Tests.ps1' -File |
                ForEach-Object { $_.Name -replace '\.Integration\.Tests\.ps1$', '' } |
                Sort-Object
        )

        $integrationTestStemList | Should -Be $script:sourceStemList
    }
}
