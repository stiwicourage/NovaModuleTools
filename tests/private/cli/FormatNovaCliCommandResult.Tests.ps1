BeforeAll {
    $projectRoot = Split-Path -Parent (Split-Path -Parent (Split-Path -Parent $PSScriptRoot))
    . (Join-Path $projectRoot 'src/private/cli/FormatNovaCliCommandResult.ps1')
}

Describe 'Test-NovaCliNoUpdateResult' {
    It 'returns true for update result with no update available' {
        $result = [pscustomobject]@{UpdateAvailable = $false; CurrentVersion = '1.0.0'}
        Test-NovaCliNoUpdateResult -Command 'update' -Result $result | Should -BeTrue
    }

    It 'returns false when an update is available' {
        $result = [pscustomobject]@{UpdateAvailable = $true; CurrentVersion = '1.0.0'}
        Test-NovaCliNoUpdateResult -Command 'update' -Result $result | Should -BeFalse
    }

    It 'returns false for non-update commands' {
        Test-NovaCliNoUpdateResult -Command 'bump' -Result $null | Should -BeFalse
    }
}

Describe 'Test-NovaCliVersionUpdateResult' {
    It 'requires all bump properties on the result' {
        $result = [pscustomobject]@{PreviousVersion='1';NewVersion='2';Label='minor';CommitCount=3;Applied=$true}
        Test-NovaCliVersionUpdateResult -Command 'bump' -Result $result | Should -BeTrue
    }

    It 'returns false when the result is missing a required property' {
        Test-NovaCliVersionUpdateResult -Command 'bump' -Result ([pscustomobject]@{PreviousVersion='1'}) | Should -BeFalse
    }
}

Describe 'Format-NovaCliVersionUpdateResult' {
    It 'uses the applied summary prefix when Applied is true' {
        $result = [pscustomobject]@{Applied=$true;PreviousVersion='1.0.0';NewVersion='1.1.0';Label='minor';CommitCount=4}
        Format-NovaCliVersionUpdateResult -Result $result | Should -Match '^Version bump completed:'
    }

    It 'uses the plan prefix when Applied is false' {
        $result = [pscustomobject]@{Applied=$false;PreviousVersion='1.0.0';NewVersion='1.1.0';Label='minor';CommitCount=4}
        Format-NovaCliVersionUpdateResult -Result $result | Should -Match '^Version plan:'
    }
}

Describe 'Format-NovaCliCommandResult' {
    It 'formats no-update results into the user-facing lines' {
        $result = [pscustomobject]@{UpdateAvailable=$false;ModuleName='NovaModuleTools';CurrentVersion='1.0.0'}
        $lines = Format-NovaCliCommandResult -Command 'update' -Result $result
        $lines[0] | Should -Be "You're up to date!"
        $lines[1] | Should -Match 'NovaModuleTools 1.0.0'
    }

    It 'passes through other results' {
        Format-NovaCliCommandResult -Command 'build' -Result 'raw' | Should -Be 'raw'
    }

    It 'formats version update results for the bump command' {
        $result = [pscustomobject]@{Applied=$true;PreviousVersion='1.0.0';NewVersion='1.1.0';Label='minor';CommitCount=4}
        Format-NovaCliCommandResult -Command 'bump' -Result $result | Should -Be (Format-NovaCliVersionUpdateResult -Result $result)
    }

    It 'passes through a structured result that does not match update or bump shapes' {
        $result = [pscustomobject]@{Custom = 'value'}
        Format-NovaCliCommandResult -Command 'package' -Result $result | Should -Be $result
    }
}
