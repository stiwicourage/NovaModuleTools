BeforeAll {
    $projectRoot = Split-Path -Parent (Split-Path -Parent (Split-Path -Parent $PSScriptRoot))
    . (Join-Path $projectRoot 'src/private/cli/GetAwesomePromptFieldDescription.ps1')

    function Get-AwesomePromptValue {param($Ask, [string]$Name) return $null}
}

Describe 'Get-AwesomePromptFieldDescription' {
    It 'sets the default value when the ask default is not MANDATORY' {
        Mock Get-AwesomePromptValue {return 'Type something'} -ParameterFilter {$Name -eq 'Prompt'}
        Mock Get-AwesomePromptValue {return 'fallback'} -ParameterFilter {$Name -eq 'Default'}
        $description = Get-AwesomePromptFieldDescription -Ask @{}
        $description.Name | Should -Be 'Type something'
        $description.DefaultValue | Should -Be 'fallback'
    }

    It 'does not set the default value for MANDATORY asks' {
        Mock Get-AwesomePromptValue {return 'Type something'} -ParameterFilter {$Name -eq 'Prompt'}
        Mock Get-AwesomePromptValue {return 'MANDATORY'} -ParameterFilter {$Name -eq 'Default'}
        $description = Get-AwesomePromptFieldDescription -Ask @{}
        $description.DefaultValue | Should -BeNullOrEmpty
    }
}
