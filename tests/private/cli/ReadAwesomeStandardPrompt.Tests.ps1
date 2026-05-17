BeforeAll {
    $projectRoot = Split-Path -Parent (Split-Path -Parent (Split-Path -Parent $PSScriptRoot))
    . (Join-Path $projectRoot 'src/private/cli/ReadAwesomeStandardPrompt.ps1')

    function Get-AwesomePromptFieldDescription {param($Ask) return [pscustomobject]@{Name = 'field'}}
    function Get-AwesomePromptValue {param($Ask, [string]$Name) return $Name}
    function Test-AwesomePromptRequiresRetry {param($Ask, $Response) return $false}
    function Write-AwesomePromptRetryMessage {param($Ask, $Response)}
    function Get-AwesomePromptResult {param($Ask, $Response) return 'final'}
}

Describe 'Read-AwesomeStandardPrompt' {
    It 'returns the prompt result when no retry is needed' {
        $hostUi = [pscustomobject]@{}
        $hostUi | Add-Member -MemberType ScriptMethod -Name Prompt -Value {param($caption, $message, $fields) return [pscustomobject]@{Values = 'x'}}
        Read-AwesomeStandardPrompt -Ask @{} -HostUi $hostUi | Should -Be 'final'
    }
}
