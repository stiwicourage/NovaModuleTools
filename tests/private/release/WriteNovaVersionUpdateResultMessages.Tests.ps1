BeforeAll {
    $projectRoot = Split-Path -Parent (Split-Path -Parent (Split-Path -Parent $PSScriptRoot))
    . (Join-Path $projectRoot 'src/private/release/WriteNovaVersionUpdateResultMessages.ps1')

    function Get-NovaVersionUpdateCiActivatedCommand {param($ProjectRoot) return $null}
    function Write-Message {param($Message, $color) $script:messages += [pscustomobject]@{Text=$Message; Color=$color}}
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
    BeforeEach {
        $script:messages = @()
    }

    It 'writes a warning when an advisory message is present' {
        $r = [pscustomobject]@{AdvisoryMessage='watch out'; Applied=$false; Previewed=$true; NewVersion='1.2.3'; PreviousVersion='1.2.2'; Label='Patch'; EffectiveLabel='Patch'; CommitCount=2}
        Write-NovaVersionUpdateResultOutput -Result $r -WarningVariable w -WarningAction SilentlyContinue 6> $null
        $w[0].Message | Should -Be 'watch out'
    }

    It 'writes a completion summary, details, and next step when Applied is true' {
        $r = [pscustomobject]@{
            AdvisoryMessage = ''
            Applied = $true
            Previewed = $false
            Cancelled = $false
            NewVersion = '1.2.3'
            PreviousVersion = '1.2.2'
            Label = 'Patch'
            EffectiveLabel = 'Patch'
            CommitCount = 2
            ProjectFile = '/p/project.json'
        }
        Write-NovaVersionUpdateResultOutput -Result $r
        $script:messages[0].Text | Should -Be 'Updated project version to 1.2.3'
        $script:messages[0].Color | Should -Be 'Green'
        $script:messages.Text | Should -Contain 'Version file: /p/project.json'
        $script:messages.Text | Should -Contain 'Previous version: 1.2.2'
        $script:messages.Text | Should -Contain 'New version: 1.2.3'
        $script:messages.Text | Should -Contain 'Release label: Patch'
        $script:messages.Text | Should -Contain 'Commits considered: 2'
        $script:messages.Text | Should -Contain 'Invoke-NovaBuild'
    }

    It 'writes a preview summary and next step when WhatIf created the result' {
        $r = [pscustomobject]@{
            AdvisoryMessage = ''
            Applied = $false
            Previewed = $true
            Cancelled = $false
            NewVersion = '0.2.0'
            PreviousVersion = '0.1.0'
            Label = 'Major'
            EffectiveLabel = 'Minor'
            CommitCount = 34
            Target = 'project.json'
        }
        Write-NovaVersionUpdateResultOutput -Result $r
        $script:messages[0].Text | Should -Be 'Version update plan ready -> 0.2.0'
        $script:messages.Text | Should -Contain 'Version file: project.json'
        $script:messages.Text | Should -Contain 'Detected release label: Major'
        $script:messages.Text | Should -Contain 'Applied release label: Minor'
        $script:messages.Text | Should -Contain 'Run Update-NovaModuleVersion without -WhatIf when you are ready to apply the version change.'
    }

    It 'writes a cancellation summary when the command does not proceed past confirmation' {
        $r = [pscustomobject]@{
            AdvisoryMessage = ''
            Applied = $false
            Previewed = $false
            Cancelled = $true
            NewVersion = '1.2.3'
            PreviousVersion = '1.2.2'
            Label = 'Patch'
            EffectiveLabel = 'Patch'
            CommitCount = 2
        }
        Write-NovaVersionUpdateResultOutput -Result $r
        $script:messages[0].Text | Should -Be 'Version update cancelled before changing project.json.'
        $script:messages[0].Color | Should -Be 'Blue'
        $script:messages.Text | Should -Contain 'Run Update-NovaModuleVersion again when you are ready to write the new version to project.json.'
    }
}
