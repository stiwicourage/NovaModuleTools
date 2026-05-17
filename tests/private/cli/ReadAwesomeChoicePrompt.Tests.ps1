BeforeAll {
    $projectRoot = Split-Path -Parent (Split-Path -Parent (Split-Path -Parent $PSScriptRoot))
    . (Join-Path $projectRoot 'src/private/cli/ReadAwesomeChoicePrompt.ps1')

    function Get-AwesomeChoiceOptionList {param($Choice)
        return @(
            [pscustomobject]@{Label = '&Yes'},
            [pscustomobject]@{Label = '&No'}
        )
    }
    function Get-AwesomePromptValue {param($Ask, [string]$Name) return $null}
}

Describe 'Read-AwesomeChoicePrompt' {
    It 'returns the selected choice label without the accelerator prefix' {
        Mock Get-AwesomePromptValue {return @{Yes='y';No='n'}} -ParameterFilter {$Name -eq 'Choice'}
        Mock Get-AwesomePromptValue {return 'No'} -ParameterFilter {$Name -eq 'Default'}
        Mock Get-AwesomePromptValue {return 'cap'} -ParameterFilter {$Name -eq 'Caption'}
        Mock Get-AwesomePromptValue {return 'msg'} -ParameterFilter {$Name -eq 'Message'}
        $hostUi = [pscustomobject]@{}
        $hostUi | Add-Member -MemberType ScriptMethod -Name PromptForChoice -Value {param($caption, $message, $options, $default) return 0}
        Read-AwesomeChoicePrompt -Ask @{} -HostUi $hostUi | Should -Be 'Yes'
    }
}
