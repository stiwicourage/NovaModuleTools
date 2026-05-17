BeforeAll {
    $projectRoot = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
    . (Join-Path $projectRoot 'src/public/InstallNovaCli.ps1')

    function Get-NovaCliInstallWorkflowContext {param($DestinationDirectory, [switch]$Force)
        $script:ctxArgs = @{Destination=$DestinationDirectory; Force=[bool]$Force}
        return [pscustomobject]@{TargetPath='/usr/local/bin/nova'; Action='Install'}
    }
    function Invoke-NovaCliInstallWorkflow {param($WorkflowContext)
        $script:invoked = $true
        return [pscustomobject]@{ReleaseNotesUri='https://x/rel'}
    }
    function Write-NovaModuleReleaseNotesLink {param($ReleaseNotesUri) $script:notesUri = $ReleaseNotesUri}
}

Describe 'Install-NovaCli' {
    BeforeEach {$script:ctxArgs = $null; $script:invoked = $false; $script:notesUri = $null}

    It 'forwards parameters and writes the release notes link' {
        $result = Install-NovaCli -DestinationDirectory '/dest' -Force
        $script:ctxArgs.Destination | Should -Be '/dest'
        $script:ctxArgs.Force | Should -BeTrue
        $script:invoked | Should -BeTrue
        $script:notesUri | Should -Be 'https://x/rel'
        $result.ReleaseNotesUri | Should -Be 'https://x/rel'
    }

    It 'returns without invoking the workflow when -WhatIf is set' {
        Install-NovaCli -WhatIf
        $script:invoked | Should -BeFalse
    }
}
