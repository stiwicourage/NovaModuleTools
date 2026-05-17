BeforeAll {
    $projectRoot = Split-Path -Parent (Split-Path -Parent (Split-Path -Parent $PSScriptRoot))
    . (Join-Path $projectRoot 'src/private/cli/ReadAwesomeStandardPrompt.ps1')

    . (Join-Path $PSScriptRoot 'ReadAwesomeStandardPrompt.TestSupport.ps1')
}

Describe 'Read-AwesomeStandardPrompt' {
    It 'returns the prompt result when no retry is needed' {
        $hostUi = [pscustomobject]@{}
        $hostUi | Add-Member -MemberType ScriptMethod -Name Prompt -Value {param($caption, $message, $fields) return [pscustomobject]@{Values = 'x'}}
        Read-AwesomeStandardPrompt -Ask @{} -HostUi $hostUi | Should -Be 'final'
    }
}
