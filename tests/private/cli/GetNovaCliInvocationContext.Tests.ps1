BeforeAll {
    $projectRoot = Split-Path -Parent (Split-Path -Parent (Split-Path -Parent $PSScriptRoot))
    . (Join-Path $projectRoot 'src/private/cli/GetNovaCliInvocationContext.ps1')

    . (Join-Path $PSScriptRoot 'GetNovaCliInvocationContext.TestSupport.ps1')
}

Describe 'Get-NovaCliResolvedInvocationContext' {
    It 'wraps inputs into a context object' {
        $r = Get-NovaCliResolvedInvocationContext -Command 'a' -Arguments @('x') -CommonParameters @{V=1} -MutatingCommonParameters @{W=2} -ModuleName 'M' -WhatIfEnabled $true -CliConfirmEnabled $false
        $r.Command | Should -Be 'a'
        $r.Arguments | Should -Be @('x')
        $r.IsHelpRequest | Should -BeFalse
        $r.ModuleName | Should -Be 'M'
        $r.WhatIfEnabled | Should -BeTrue
    }

    It 'marks help request when HelpRequest is provided' {
        $r = Get-NovaCliResolvedInvocationContext -Command 'a' -CommonParameters @{} -MutatingCommonParameters @{} -ModuleName 'M' -WhatIfEnabled $false -CliConfirmEnabled $false -HelpRequest ([pscustomobject]@{X=1})
        $r.IsHelpRequest | Should -BeTrue
        $r.HelpRequest.X | Should -Be 1
    }
}

Describe 'Get-NovaCliInvocationWhatIfState' {
    It 'returns true when -WhatIfEnabled is set' {
        Get-NovaCliInvocationWhatIfState -WhatIfEnabled -MutatingCommonParameters @{} | Should -BeTrue
    }
    It 'returns true when -RoutingWhatIfEnabled is set' {
        Get-NovaCliInvocationWhatIfState -MutatingCommonParameters @{} -RoutingWhatIfEnabled | Should -BeTrue
    }
    It 'returns true when MutatingCommonParameters contains WhatIf' {
        Get-NovaCliInvocationWhatIfState -MutatingCommonParameters @{WhatIf=$true} | Should -BeTrue
    }
    It 'returns false when no flag is set' {
        Get-NovaCliInvocationWhatIfState -MutatingCommonParameters @{} | Should -BeFalse
    }
}

Describe 'Get-NovaCliInvocationConfirmState' {
    It 'returns false when Confirm not present' {
        Get-NovaCliInvocationConfirmState -MutatingCommonParameters @{} | Should -BeFalse
    }
    It 'returns true and removes Confirm when set' {
        $m = @{Confirm = $true}
        Get-NovaCliInvocationConfirmState -MutatingCommonParameters $m | Should -BeTrue
        $m.ContainsKey('Confirm') | Should -BeFalse
    }
    It 'returns false and removes Confirm when explicit false' {
        $m = @{Confirm = $false}
        Get-NovaCliInvocationConfirmState -MutatingCommonParameters $m | Should -BeFalse
        $m.ContainsKey('Confirm') | Should -BeFalse
    }
}

Describe 'Get-NovaCliInvocationContext' {
    BeforeEach {
        . (Join-Path $PSScriptRoot 'GetNovaCliInvocationContext.Describe.TestSupport.ps1')
    }

    It 'returns a help-targeted context when a help request is detected' {
        Mock Get-NovaCliForwardingParameterSet {
            if ($IncludeShouldProcess) { return @{WhatIf=$true} }
            return @{Verbose=$true}
        }
        Mock ConvertTo-NovaCliArgumentArray { @('--help') }
        Mock Get-NovaCliHelpRequest { [pscustomobject]@{Command='publish'; View='Short'; TargetType='Command'} }
        Mock Assert-NovaCliArgumentSyntax {}

        $req = [pscustomobject]@{Command='publish'; BoundParameters=@{Verbose=$true; Arguments=@('--help')}; Arguments=@('--help')}
        $result = Get-NovaCliInvocationContext -InvocationRequest $req -WhatIfEnabled

        $result.Command | Should -Be 'publish'
        $result.IsHelpRequest | Should -BeTrue
        $result.HelpRequest.View | Should -Be 'Short'
        $result.WhatIfEnabled | Should -BeTrue
        $result.CliConfirmEnabled | Should -BeFalse
        Should -Invoke Get-NovaCliForwardingParameterSet -Times 1 -ParameterFilter {-not $IncludeShouldProcess}
        Should -Invoke Get-NovaCliForwardingParameterSet -Times 1 -ParameterFilter {$IncludeShouldProcess}
    }

    It 'routes to argument routing state when no help request' {
        Mock Get-NovaCliForwardingParameterSet { @{} }
        Mock ConvertTo-NovaCliArgumentArray { @('--verbose') }
        Mock Get-NovaCliHelpRequest { $null }
        Mock Assert-NovaCliArgumentSyntax {}
        Mock Get-NovaCliArgumentRoutingState {
            [pscustomobject]@{
                Command='build'; Arguments=@('--mode','Release')
                ForwardedParameters=@{Verbose=$true}
                CliConfirmEnabled=$true; WhatIfEnabled=$false
            }
        }
        Mock Merge-NovaCliParameterSet { param($BaseParameters,$AdditionalParameters) return $BaseParameters }

        $req = [pscustomobject]@{Command='build'; BoundParameters=@{Arguments=@('--verbose')}; Arguments=@('--verbose')}
        $result = Get-NovaCliInvocationContext -InvocationRequest $req

        $result.Command | Should -Be 'build'
        $result.CliConfirmEnabled | Should -BeTrue
        $result.CommonParameters.Verbose | Should -BeTrue
        Should -Invoke Get-NovaCliArgumentRoutingState -Times 1
        Should -Invoke Merge-NovaCliParameterSet -Times 1
    }

    It 'honors -WhatIfEnabled even when routing state does not request it' {
        Mock Get-NovaCliForwardingParameterSet { @{} }
        Mock ConvertTo-NovaCliArgumentArray { @() }
        Mock Get-NovaCliHelpRequest { $null }
        Mock Assert-NovaCliArgumentSyntax {}
        Mock Get-NovaCliArgumentRoutingState {
            [pscustomobject]@{
                Command='package'; Arguments=@()
                ForwardedParameters=@{}
                CliConfirmEnabled=$false; WhatIfEnabled=$false
            }
        }
        Mock Merge-NovaCliParameterSet { param($BaseParameters,$AdditionalParameters) return $BaseParameters }

        $req = [pscustomobject]@{Command='package'; BoundParameters=@{}; Arguments=@()}
        $result = Get-NovaCliInvocationContext -InvocationRequest $req -WhatIfEnabled

        $result.WhatIfEnabled | Should -BeTrue
    }
}
