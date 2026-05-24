BeforeAll {
    $projectRoot = Split-Path -Parent $PSScriptRoot
    $script:projectJson = Get-Content -LiteralPath (Join-Path $projectRoot 'project.json') -Raw | ConvertFrom-Json -AsHashtable
    $script:projectTemplateJson = Get-Content -LiteralPath (Join-Path $projectRoot 'src/resources/ProjectTemplate.json') -Raw | ConvertFrom-Json -AsHashtable
    $script:exampleProjectJson = Get-Content -LiteralPath (Join-Path $projectRoot 'src/resources/example/project.json') -Raw | ConvertFrom-Json -AsHashtable
}

Describe 'project.json Pester code coverage configuration' {
    It 'keeps one recursive private-source glob in the repository config' {
        $script:projectJson.Pester.CodeCoverage.Path | Should -Be @(
            'src/public/*.ps1'
            'src/private/**/*.ps1'
        )
    }

    It 'keeps scaffolded project templates aligned with the recursive private-source glob' {
        $expectedPath = @(
            'src/public/*.ps1'
            'src/private/**/*.ps1'
            'src/classes/*.ps1'
        )

        $script:projectTemplateJson.Pester.CodeCoverage.Path | Should -Be $expectedPath
        $script:exampleProjectJson.Pester.CodeCoverage.Path | Should -Be $expectedPath
    }
}
