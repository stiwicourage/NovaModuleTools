BeforeAll {
    $projectRoot = Split-Path -Parent $PSScriptRoot
    $script:projectJson = Get-Content -LiteralPath (Join-Path $projectRoot 'project.json') -Raw | ConvertFrom-Json -AsHashtable
}

Describe 'project.json Pester code coverage configuration' {
    It 'uses explicit private-source globs so nested helpers stay measurable' {
        $script:projectJson.Pester.CodeCoverage.Path | Should -Be @(
            'src/public/*.ps1'
            'src/private/**/*.ps1'
        )
    }
}
