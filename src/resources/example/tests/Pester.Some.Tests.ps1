BeforeAll {
    $project = Get-NovaProjectInfo
    Remove-Module $project.ProjectName -ErrorAction SilentlyContinue
    Import-Module $project.OutputModuleDir -Force
}

Describe 'Nova example project' {
    It 'returns a default greeting from the bundled configuration' {
        Get-ExampleGreeting | Should -Be 'Hello, Nova user!'
    }

    It 'returns a custom greeting when a name is provided' {
        Get-ExampleGreeting -Name 'Stiwi' | Should -Be 'Hello, Stiwi!'
    }

    It 'can return greeting metadata for inspection' {
        $result = Get-ExampleGreeting -Name 'CodeScene' -AsObject

        $result.Message | Should -Be 'Hello, CodeScene!'
        $result.Audience | Should -Be 'CodeScene'
        (Test-Path -LiteralPath $result.ConfigurationPath) | Should -BeTrue
    }
}
