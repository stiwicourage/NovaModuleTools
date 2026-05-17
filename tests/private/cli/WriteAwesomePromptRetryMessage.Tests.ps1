BeforeAll {
    $projectRoot = Split-Path -Parent (Split-Path -Parent (Split-Path -Parent $PSScriptRoot))
    . (Join-Path $projectRoot 'src/private/cli/WriteAwesomePromptRetryMessage.ps1')

    . (Join-Path $PSScriptRoot 'WriteAwesomePromptRetryMessage.TestSupport.ps1')
}

Describe 'Write-AwesomePromptRetryMessage' {
    It 'writes the failure message when validation fails' {
        Mock Get-AwesomePromptValidationFailure {return [pscustomobject]@{Message = 'invalid input'}}
        Mock Write-Message {}
        Write-AwesomePromptRetryMessage -Ask @{} -Response ([pscustomobject]@{Values = 'x'})
        Should -Invoke Write-Message -Times 1 -ParameterFilter {$Text -eq 'invalid input' -and $color -eq 'Yello'}
    }

    It 'writes nothing when validation passes' {
        Mock Get-AwesomePromptValidationFailure {return $null}
        Mock Write-Message {}
        Write-AwesomePromptRetryMessage -Ask @{} -Response ([pscustomobject]@{Values = 'x'})
        Should -Invoke Write-Message -Times 0
    }
}
