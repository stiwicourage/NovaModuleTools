BeforeAll {
    $projectRoot = Split-Path -Parent (Split-Path -Parent (Split-Path -Parent $PSScriptRoot))
    . (Join-Path $projectRoot 'src/private/cli/GetNovaCliArgumentRoutingState.ps1')

    function Stop-NovaOperation {
        param([string]$Message, [string]$ErrorId, [System.Management.Automation.ErrorCategory]$Category, $TargetObject)
        $exception = [System.Exception]::new($Message)
        $record = [System.Management.Automation.ErrorRecord]::new($exception, $ErrorId, $Category, $TargetObject)
        throw $record
    }
}

Describe 'Merge-NovaCliParameterSet' {
    It 'merges additional parameters over base' {
        $r = Merge-NovaCliParameterSet -BaseParameters @{A=1; B=2} -AdditionalParameters @{B=3; C=4}
        $r.A | Should -Be 1
        $r.B | Should -Be 3
        $r.C | Should -Be 4
    }
}

Describe 'Get-NovaCliNormalizedRootCommand' {
    It 'returns --help for -h' { Get-NovaCliNormalizedRootCommand -Command '-h' | Should -Be '--help' }
    It 'returns --version for -v' { Get-NovaCliNormalizedRootCommand -Command '-v' | Should -Be '--version' }
    It 'returns the input for other commands' { Get-NovaCliNormalizedRootCommand -Command 'build' | Should -Be 'build' }
}

Describe 'Test-NovaCliMutatingCommand' {
    It 'returns true for known mutating commands' {
        foreach ($c in @('build','test','package','deploy','bump','update','notification','publish','release')) {
            Test-NovaCliMutatingCommand -Command $c | Should -BeTrue
        }
    }
    It 'returns false for non-mutating commands' {
        Test-NovaCliMutatingCommand -Command 'list' | Should -BeFalse
    }
}

Describe 'Test-NovaCliConfirmSupportedCommand' {
    It 'mirrors mutating-command behavior' {
        Test-NovaCliConfirmSupportedCommand -Command 'build' | Should -BeTrue
        Test-NovaCliConfirmSupportedCommand -Command 'list' | Should -BeFalse
    }
}

Describe 'Get-NovaCliLegacyOptionReplacement' {
    It 'returns the mapped replacement for a known legacy option' {
        Get-NovaCliLegacyOptionReplacement -Option '-confirm' | Should -Match "'--confirm'"
        Get-NovaCliLegacyOptionReplacement -Option '-WhatIf' | Should -Match "'--what-if'"
    }
    It 'returns null for unknown legacy options' {
        Get-NovaCliLegacyOptionReplacement -Option '-unknownopt' | Should -BeNullOrEmpty
    }
}

Describe 'Test-NovaCliLegacySingleHyphenOption' {
    It 'returns true for single-hyphen long options' {
        Test-NovaCliLegacySingleHyphenOption -Argument '-confirm' | Should -BeTrue
    }
    It 'returns false for double-hyphen options' {
        Test-NovaCliLegacySingleHyphenOption -Argument '--confirm' | Should -BeFalse
    }
    It 'returns false for single-char short options' {
        Test-NovaCliLegacySingleHyphenOption -Argument '-c' | Should -BeFalse
    }
    It 'returns false for positional values' {
        Test-NovaCliLegacySingleHyphenOption -Argument 'foo' | Should -BeFalse
    }
}

Describe 'Assert-NovaCliArgumentSyntax' {
    It 'does nothing for valid arguments' {
        { Assert-NovaCliArgumentSyntax -Arguments @('build','--what-if','-c') } | Should -Not -Throw
    }
    It 'rejects --whatif (legacy spelling)' {
        { Assert-NovaCliArgumentSyntax -Arguments @('--whatif') } | Should -Throw -ErrorId 'Nova.Validation.UnsupportedCliOptionSyntax'
    }
    It 'rejects mapped legacy single-hyphen long options with replacement hint' {
        { Assert-NovaCliArgumentSyntax -Arguments @('-confirm') } | Should -Throw -ErrorId 'Nova.Validation.UnsupportedCliOptionSyntax'
    }
    It 'rejects unmapped legacy single-hyphen long options with generic hint' {
        { Assert-NovaCliArgumentSyntax -Arguments @('-unknownopt') } | Should -Throw -ErrorId 'Nova.Validation.UnsupportedCliOptionSyntax'
    }
    It 'accepts empty argument list' {
        { Assert-NovaCliArgumentSyntax -Arguments @() } | Should -Not -Throw
    }
}

Describe 'Add-NovaCliCommonOption' {
    It 'returns true for --confirm and -c' {
        $fp = @{}
        Add-NovaCliCommonOption -Argument '--confirm' -ForwardedParameters $fp | Should -BeTrue
        Add-NovaCliCommonOption -Argument '-c' -ForwardedParameters $fp | Should -BeTrue
    }
    It 'forwards Verbose for --verbose and -v' {
        $fp = @{}
        Add-NovaCliCommonOption -Argument '--verbose' -ForwardedParameters $fp | Should -BeTrue
        $fp.Verbose | Should -BeTrue
        $fp2 = @{}
        Add-NovaCliCommonOption -Argument '-v' -ForwardedParameters $fp2 | Should -BeTrue
        $fp2.Verbose | Should -BeTrue
    }
    It 'forwards WhatIf for --what-if and -w' {
        $fp = @{}
        Add-NovaCliCommonOption -Argument '--what-if' -ForwardedParameters $fp | Should -BeTrue
        $fp.WhatIf | Should -BeTrue
        $fp2 = @{}
        Add-NovaCliCommonOption -Argument '-w' -ForwardedParameters $fp2 | Should -BeTrue
        $fp2.WhatIf | Should -BeTrue
    }
    It 'returns false for unrelated arguments' {
        Add-NovaCliCommonOption -Argument '--path' -ForwardedParameters @{} | Should -BeFalse
    }
}

Describe 'Test-NovaCliWhatIfOption' {
    It 'matches --what-if and -w' {
        Test-NovaCliWhatIfOption -Argument '--what-if' | Should -BeTrue
        Test-NovaCliWhatIfOption -Argument '-w' | Should -BeTrue
    }
    It 'does not match other options' {
        Test-NovaCliWhatIfOption -Argument '--verbose' | Should -BeFalse
    }
}

Describe 'Test-NovaCliConfirmOption' {
    It 'matches --confirm and -c' {
        Test-NovaCliConfirmOption -Argument '--confirm' | Should -BeTrue
        Test-NovaCliConfirmOption -Argument '-c' | Should -BeTrue
    }
    It 'does not match other options' {
        Test-NovaCliConfirmOption -Argument '--verbose' | Should -BeFalse
    }
}

Describe 'Assert-NovaCliConfirmSupportedCommand' {
    It 'does nothing for non-confirm arguments' {
        { Assert-NovaCliConfirmSupportedCommand -Command 'list' -Argument '--verbose' } | Should -Not -Throw
    }
    It 'does nothing when command supports confirm' {
        { Assert-NovaCliConfirmSupportedCommand -Command 'build' -Argument '--confirm' } | Should -Not -Throw
    }
    It 'throws when command does not support confirm' {
        { Assert-NovaCliConfirmSupportedCommand -Command 'list' -Argument '--confirm' } | Should -Throw -ErrorId 'Nova.Validation.UnsupportedCliConfirm'
    }
}

Describe 'Get-NovaCliArgumentRoutingState' {
    It 'normalizes -h to --help and preserves positional arguments' {
        $state = Get-NovaCliArgumentRoutingState -Command '-h' -Arguments @('package')
        $state.Command | Should -Be '--help'
        $state.Arguments | Should -Be @('package')
        $state.ForwardedParameters.Count | Should -Be 0
        $state.WhatIfEnabled | Should -BeFalse
        $state.CliConfirmEnabled | Should -BeFalse
    }

    It 'forwards Verbose/WhatIf/Confirm for mutating commands' {
        $state = Get-NovaCliArgumentRoutingState -Command 'build' -Arguments @('--verbose','--what-if','--confirm','--mode','Release')
        $state.Command | Should -Be 'build'
        $state.ForwardedParameters.Verbose | Should -BeTrue
        $state.ForwardedParameters.WhatIf | Should -BeTrue
        $state.WhatIfEnabled | Should -BeTrue
        $state.CliConfirmEnabled | Should -BeTrue
        $state.Arguments | Should -Be @('--mode','Release')
    }

    It 'allows --what-if for init even though init is not mutating' {
        $state = Get-NovaCliArgumentRoutingState -Command 'init' -Arguments @('--what-if','MyProj')
        $state.WhatIfEnabled | Should -BeTrue
        $state.Arguments | Should -Be @('MyProj')
    }

    It 'does not forward common options for non-mutating commands' {
        $state = Get-NovaCliArgumentRoutingState -Command 'list' -Arguments @('--verbose')
        $state.Arguments | Should -Be @('--verbose')
        $state.ForwardedParameters.Count | Should -Be 0
    }

    It 'returns empty arguments when none are provided' {
        $state = Get-NovaCliArgumentRoutingState -Command 'build' -Arguments @()
        $state.Arguments.Count | Should -Be 0
    }

    It 'tolerates null arguments' {
        $state = Get-NovaCliArgumentRoutingState -Command 'build' -Arguments $null
        $state.Arguments.Count | Should -Be 0
    }
}
