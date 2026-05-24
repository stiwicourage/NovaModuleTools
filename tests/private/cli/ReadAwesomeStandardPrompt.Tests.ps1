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

    It 'writes the retry message before prompting again when validation fails once' {
        $script:promptCallCount = 0
        $hostUi = [pscustomobject]@{}
        $hostUi | Add-Member -MemberType ScriptMethod -Name Prompt -Value {
            param($caption, $message, $fields)
            $script:promptCallCount += 1
            return [pscustomobject]@{Attempt = $script:promptCallCount}
        }

        Mock Test-AwesomePromptRequiresRetry {
            return $Response.Attempt -eq 1
        }
        Mock Write-AwesomePromptRetryMessage {}

        Read-AwesomeStandardPrompt -Ask @{} -HostUi $hostUi | Should -Be 'final'
        $script:promptCallCount | Should -Be 2
        Should -Invoke Write-AwesomePromptRetryMessage -Times 1
    }
}
