BeforeAll {
    $projectRoot = Split-Path -Parent (Split-Path -Parent (Split-Path -Parent $PSScriptRoot))
    . (Join-Path $projectRoot 'src/private/update/InstallNovaPSModuleUpdate.ps1')

    function Install-PSModuleUpdate {
        [CmdletBinding(SupportsShouldProcess)]
        param($Update, [switch]$TrustRepository, [switch]$AcceptLicense, [switch]$ReplaceUnmanagedInstallation)
    }
    function ConvertFrom-NovaPSModuleUpdateResult {param($Result) $Result}
}

Describe 'Install-NovaPSModuleUpdate' {
    BeforeAll {
        $script:updatePlan = [pscustomobject]@{ModuleName = 'NovaModuleTools'; RequiresRepositoryTrust = $true; RequiresLicenseAcceptance = $false}
    }

    BeforeEach {
        Mock Install-PSModuleUpdate {[pscustomobject]@{Outcome = 'Installed'}}
        Mock ConvertFrom-NovaPSModuleUpdateResult {[pscustomobject]@{Converted = $Result.Outcome}}
    }

    It 'installs the exact plan without a second prompt and with the consents the plan requires' {
        $result = Install-NovaPSModuleUpdate -UpdatePlan $script:updatePlan

        $result.Converted | Should -Be 'Installed'
        Should -Invoke Install-PSModuleUpdate -Times 1 -ParameterFilter {
            $Update.ModuleName -eq 'NovaModuleTools' -and $TrustRepository -and -not $AcceptLicense -and
                    $Confirm -eq $false -and $WhatIf -eq $false
        }
    }

    It 'allows replacing an unmanaged installation when the installed PSModuleUpdate supports it' {
        $null = Install-NovaPSModuleUpdate -UpdatePlan $script:updatePlan

        Should -Invoke Install-PSModuleUpdate -Times 1 -ParameterFilter {$ReplaceUnmanagedInstallation}
    }

    It 'omits unmanaged replacement when the installed PSModuleUpdate does not support it' {
        Mock Get-Command {[pscustomobject]@{Parameters = @{}}} -ParameterFilter {$Name -eq 'Install-PSModuleUpdate'}

        $null = Install-NovaPSModuleUpdate -UpdatePlan $script:updatePlan

        Should -Invoke Install-PSModuleUpdate -Times 1 -ParameterFilter {-not $PSBoundParameters.ContainsKey('ReplaceUnmanagedInstallation')}
    }
}
