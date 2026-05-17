BeforeAll {
    $projectRoot = Split-Path -Parent (Split-Path -Parent (Split-Path -Parent $PSScriptRoot))
    . (Join-Path $projectRoot 'src/private/update/ConfirmNovaPrereleaseModuleUpdate.ps1')

    function Get-NovaPrereleaseModuleUpdateConfirmationPrompt {
        param([string]$CurrentVersion, [string]$TargetVersion)
        return [pscustomobject]@{Caption = 'caption'; Message = 'message'; Choice = [ordered]@{Y='Yes';N='No'}; Default = 'N'}
    }

    function Read-AwesomeChoicePrompt {
        param($Ask, $HostUi)
        return 'Y'
    }
}

Describe 'Confirm-NovaPrereleaseModuleUpdate' {
    BeforeAll {
        $script:fakeCmdlet = [pscustomobject]@{Host = [pscustomobject]@{UI = [pscustomobject]@{Name = 'stub'}}}
    }

    It 'returns true when the user selects Yes' {
        Mock Read-AwesomeChoicePrompt {return 'Y'}
        Confirm-NovaPrereleaseModuleUpdate -Cmdlet $script:fakeCmdlet -CurrentVersion '1.0.0' -TargetVersion '2.0.0-beta1' | Should -BeTrue
    }

    It 'returns false when the user selects No' {
        Mock Read-AwesomeChoicePrompt {return 'N'}
        Confirm-NovaPrereleaseModuleUpdate -Cmdlet $script:fakeCmdlet -CurrentVersion '1.0.0' -TargetVersion '2.0.0-beta1' | Should -BeFalse
    }

    It 'builds the prompt from the current and target version inputs' {
        Mock Get-NovaPrereleaseModuleUpdateConfirmationPrompt {return [pscustomobject]@{Caption = 'caption'; Message = 'message'; Choice = [ordered]@{Y='Yes';N='No'}; Default = 'N'}}
        Mock Read-AwesomeChoicePrompt {return 'N'}

        Confirm-NovaPrereleaseModuleUpdate -Cmdlet $script:fakeCmdlet -CurrentVersion '1.0.0' -TargetVersion '2.0.0-beta1' | Out-Null

        Assert-MockCalled Get-NovaPrereleaseModuleUpdateConfirmationPrompt -Times 1 -ParameterFilter {
            $CurrentVersion -eq '1.0.0' -and $TargetVersion -eq '2.0.0-beta1'
        }
    }
}
