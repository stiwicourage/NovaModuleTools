BeforeAll {
    $projectRoot = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)

    . (Join-Path $projectRoot 'src/private/Get-ExampleConfiguration.ps1')
    . (Join-Path $projectRoot 'src/public/Get-ExampleGreeting.ps1')
}

Describe 'Get-ExampleGreeting' {
    BeforeEach {
        Mock Get-ExampleConfiguration {
            return [pscustomobject]@{
                GreetingPrefix = 'Hello'
                DefaultAudience = 'Nova user'
                ConfigurationPath = '/tmp/greeting-config.json'
            }
        }
    }

    It 'returns the default greeting when no name is provided' {
        Get-ExampleGreeting | Should -Be 'Hello, Nova user!'
    }

    It 'returns a custom greeting when a name is provided' {
        Get-ExampleGreeting -Name 'Stiwi' | Should -Be 'Hello, Stiwi!'
    }

    It 'returns greeting metadata when -AsObject is used' {
        $result = Get-ExampleGreeting -Name 'CodeScene' -AsObject

        $result.Message | Should -Be 'Hello, CodeScene!'
        $result.Audience | Should -Be 'CodeScene'
        $result.ConfigurationPath | Should -Be '/tmp/greeting-config.json'
    }
}
