BeforeAll {
    $projectRoot = Split-Path -Parent (Split-Path -Parent (Split-Path -Parent $PSScriptRoot))
    . (Join-Path $projectRoot 'src/private/cli/ReadAwesomeHost.ps1')

    function Get-AwesomeHostUi {return [pscustomobject]@{}}
    function Read-AwesomeStandardPrompt {param($Ask, $HostUi) return 'standard'}
    function Read-AwesomeChoicePrompt {param($Ask, $HostUi) return 'choice'}
}

Describe 'Read-AwesomeHost' {
    It 'uses the standard prompt when the ask has no Choice' {
        Read-AwesomeHost -Ask @{} | Should -Be 'standard'
    }

    It 'uses the choice prompt when the ask hashtable has a Choice value' {
        Read-AwesomeHost -Ask @{Choice = @{Yes = 'y'}} | Should -Be 'choice'
    }

    It 'uses the choice prompt when the ask object has a Choice property' {
        Read-AwesomeHost -Ask ([pscustomobject]@{Choice = @{Yes = 'y'}}) | Should -Be 'choice'
    }
}
