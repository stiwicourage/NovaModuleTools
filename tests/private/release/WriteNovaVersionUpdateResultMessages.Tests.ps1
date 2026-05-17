BeforeAll {
    $projectRoot = Split-Path -Parent (Split-Path -Parent (Split-Path -Parent $PSScriptRoot))
    . (Join-Path $projectRoot 'src/private/release/WriteNovaVersionUpdateResultMessages.ps1')

    function Get-NovaVersionUpdateCiActivatedCommand {param($ProjectRoot) return $null}
}

Describe 'Invoke-NovaVersionUpdateCiActivation' {
    It 'returns ShouldReturn=$false when not in CI mode' {
        $result = Invoke-NovaVersionUpdateCiActivation -ProjectRoot '/p' -Parameters @{}
        $result.ShouldReturn | Should -BeFalse
        $result.Result | Should -BeNullOrEmpty
    }

    It 'returns ShouldReturn=$false when CI but WhatIf' {
        $result = Invoke-NovaVersionUpdateCiActivation -ProjectRoot '/p' -Parameters @{} -ContinuousIntegration -WhatIfEnabled
        $result.ShouldReturn | Should -BeFalse
    }

    It 'returns ShouldReturn=$false when CI activated command is missing' {
        Mock Get-NovaVersionUpdateCiActivatedCommand {return $null}
        $result = Invoke-NovaVersionUpdateCiActivation -ProjectRoot '/p' -Parameters @{} -ContinuousIntegration
        $result.ShouldReturn | Should -BeFalse
    }

    It 'invokes the activated command and returns its result when present' {
        $activated = {param($x) return "ran-$x"}
        Mock Get-NovaVersionUpdateCiActivatedCommand {return $activated}
        $result = Invoke-NovaVersionUpdateCiActivation -ProjectRoot '/p' -Parameters @{x='a'} -ContinuousIntegration
        $result.ShouldReturn | Should -BeTrue
        $result.Result | Should -Be 'ran-a'
    }
}

Describe 'Get-NovaVersionUpdateResultAdvisoryMessage' {
    It 'returns $null when no AdvisoryMessage property exists' {
        Get-NovaVersionUpdateResultAdvisoryMessage -Result ([pscustomobject]@{Other='x'}) | Should -BeNullOrEmpty
    }

    It 'returns the message when present' {
        Get-NovaVersionUpdateResultAdvisoryMessage -Result ([pscustomobject]@{AdvisoryMessage='hi'}) | Should -Be 'hi'
    }
}

Describe 'Write-NovaVersionUpdateResultOutput' {
    It 'writes a warning when an advisory message is present' {
        $r = [pscustomobject]@{AdvisoryMessage='watch out'; Applied=$false}
        Write-NovaVersionUpdateResultOutput -Result $r -WarningVariable w -WarningAction SilentlyContinue 6> $null
        $w[0].Message | Should -Be 'watch out'
    }

    It 'writes the bumped version host message when Applied is true' {
        $r = [pscustomobject]@{AdvisoryMessage=''; Applied=$true; NewVersion='1.2.3'}
        $output = Write-NovaVersionUpdateResultOutput -Result $r 6>&1 | Out-String
        $output | Should -Match 'Version bumped to : 1.2.3'
    }
}
