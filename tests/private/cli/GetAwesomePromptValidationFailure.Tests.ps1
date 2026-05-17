BeforeAll {
    $projectRoot = Split-Path -Parent (Split-Path -Parent (Split-Path -Parent $PSScriptRoot))
    . (Join-Path $projectRoot 'src/private/cli/GetAwesomePromptValidationFailure.ps1')
    . (Join-Path $projectRoot 'src/private/cli/GetAwesomePromptValue.ps1')
}

Describe 'Get-AwesomePromptValidationFailure' {
    It 'returns $null when ask has no Validation entry' {
        Get-AwesomePromptValidationFailure -Ask @{} -Value 'x' | Should -BeNullOrEmpty
    }

    It 'returns $null when Validation entry has no Test' {
        $ask = @{Validation = @{Message = 'bad'}}
        Get-AwesomePromptValidationFailure -Ask $ask -Value 'x' | Should -BeNullOrEmpty
    }

    It 'returns $null when validator returns true' {
        $ask = @{Validation = @{Test = {param($v) $true}; Message = 'bad'; ErrorId = 'e'; Category = 'c'}}
        Get-AwesomePromptValidationFailure -Ask $ask -Value 'x' | Should -BeNullOrEmpty
    }

    It 'returns a failure object when validator returns false' {
        $ask = @{Validation = @{Test = {param($v) $false}; Message = 'bad'; ErrorId = 'e'; Category = 'c'}}
        $failure = Get-AwesomePromptValidationFailure -Ask $ask -Value 'x'
        $failure.Message | Should -Be 'bad'
        $failure.ErrorId | Should -Be 'e'
        $failure.TargetObject | Should -Be 'x'
    }
}
