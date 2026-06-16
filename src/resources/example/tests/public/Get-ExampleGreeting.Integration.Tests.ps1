BeforeAll {
    $projectRoot = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
    $projectFile = Join-Path $projectRoot 'project.json'
    $projectData = Get-Content -LiteralPath $projectFile -Raw | ConvertFrom-Json -AsHashtable
    $script:moduleName = [string]$projectData.ProjectName
    $moduleManifestPath = Join-Path $projectRoot "dist/$($script:moduleName)/$($script:moduleName).psd1"

    Import-Module $moduleManifestPath -Force
}

Describe 'Get-ExampleGreeting integration' {
    It 'imports the built module and returns the public greeting' {
        (Get-Command -Name 'Get-ExampleGreeting' -Module $script:moduleName) | Should -Not -BeNullOrEmpty
        Get-ExampleGreeting -Name 'Build validation' | Should -Be 'Hello, Build validation!'
    }
}
