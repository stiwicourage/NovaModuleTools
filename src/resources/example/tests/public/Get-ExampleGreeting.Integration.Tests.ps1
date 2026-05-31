BeforeAll {
    $projectRoot = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
    $moduleManifestPath = Join-Path $projectRoot 'dist/NovaExampleModule/NovaExampleModule.psd1'

    Import-Module $moduleManifestPath -Force
}

Describe 'Get-ExampleGreeting integration' {
    It 'imports the built module and returns the public greeting' {
        (Get-Command -Name 'Get-ExampleGreeting' -Module 'NovaExampleModule') | Should -Not -BeNullOrEmpty
        Get-ExampleGreeting -Name 'Build validation' | Should -Be 'Hello, Build validation!'
    }
}
