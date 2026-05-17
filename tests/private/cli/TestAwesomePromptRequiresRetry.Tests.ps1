BeforeAll {
    $projectRoot = Split-Path -Parent (Split-Path -Parent (Split-Path -Parent $PSScriptRoot))
    . (Join-Path $projectRoot 'src/private/cli/TestAwesomePromptRequiresRetry.ps1')

    function Get-AwesomePromptValue {param($Ask, [string]$Name) return $null}
    function Get-AwesomePromptResult {param($Ask, $Response) return 'value'}
    function Get-AwesomePromptValidationFailure {param($Ask, $Value) return $null}
}

Describe 'Test-AwesomePromptRequiresRetry' {
    It 'requires retry when mandatory ask gets an empty response' {
        Mock Get-AwesomePromptValue {return 'MANDATORY'} -ParameterFilter {$Name -eq 'Default'}
        $response = [pscustomobject]@{Values = ''}
        Test-AwesomePromptRequiresRetry -Ask @{} -Response $response | Should -BeTrue
    }

    It 'requires retry when validation reports a failure' {
        Mock Get-AwesomePromptValue {return 'fallback'} -ParameterFilter {$Name -eq 'Default'}
        Mock Get-AwesomePromptValidationFailure {return [pscustomobject]@{Message = 'bad'}}
        $response = [pscustomobject]@{Values = 'something'}
        Test-AwesomePromptRequiresRetry -Ask @{} -Response $response | Should -BeTrue
    }

    It 'does not require retry when value is valid' {
        Mock Get-AwesomePromptValue {return 'fallback'} -ParameterFilter {$Name -eq 'Default'}
        Mock Get-AwesomePromptValidationFailure {return $null}
        $response = [pscustomobject]@{Values = 'something'}
        Test-AwesomePromptRequiresRetry -Ask @{} -Response $response | Should -BeFalse
    }
}
