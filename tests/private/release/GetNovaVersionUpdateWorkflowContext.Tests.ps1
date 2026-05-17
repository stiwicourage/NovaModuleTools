BeforeAll {
    $projectRoot = Split-Path -Parent (Split-Path -Parent (Split-Path -Parent $PSScriptRoot))
    . (Join-Path $projectRoot 'src/private/release/GetNovaVersionUpdateWorkflowContext.ps1')

    . (Join-Path $PSScriptRoot 'GetNovaVersionUpdateWorkflowContext.TestSupport.ps1')
}

Describe 'Test-NovaVersionUpdateUsesPreviewPatchFallback' {
    It 'returns false when -PreviewRelease is not set' {
        Test-NovaVersionUpdateUsesPreviewPatchFallback -CurrentVersion ([semver]'1.0.0') | Should -BeFalse
    }

    It 'returns true when previewing without an existing prerelease label' {
        Test-NovaVersionUpdateUsesPreviewPatchFallback -CurrentVersion ([semver]'1.0.0') -PreviewRelease | Should -BeTrue
    }

    It 'returns false when previewing on an existing prerelease' {
        Test-NovaVersionUpdateUsesPreviewPatchFallback -CurrentVersion ([semver]'1.0.0-preview01') -PreviewRelease | Should -BeFalse
    }
}

Describe 'Test-NovaVersionUpdateUsesInitialDevelopmentAdvisory' {
    It 'returns true for major-zero stable releases' {
        Test-NovaVersionUpdateUsesInitialDevelopmentAdvisory -CurrentVersion ([semver]'0.5.0') | Should -BeTrue
    }

    It 'returns false for major>=1' {
        Test-NovaVersionUpdateUsesInitialDevelopmentAdvisory -CurrentVersion ([semver]'1.5.0') | Should -BeFalse
    }

    It 'returns false for preview releases' {
        Test-NovaVersionUpdateUsesInitialDevelopmentAdvisory -CurrentVersion ([semver]'0.5.0') -PreviewRelease | Should -BeFalse
    }
}

Describe 'Test-NovaVersionUpdateUsesMajorZeroFallback' {
    It 'returns true for Major label at version 0.x.x' {
        Test-NovaVersionUpdateUsesMajorZeroFallback -CurrentVersion ([semver]'0.5.0') -Label 'Major' | Should -BeTrue
    }

    It 'returns false for Major label at version 1.x.x' {
        Test-NovaVersionUpdateUsesMajorZeroFallback -CurrentVersion ([semver]'1.5.0') -Label 'Major' | Should -BeFalse
    }

    It 'returns false for non-Major labels' {
        Test-NovaVersionUpdateUsesMajorZeroFallback -CurrentVersion ([semver]'0.5.0') -Label 'Patch' | Should -BeFalse
    }
}

Describe 'Get-NovaInitialDevelopmentVersioningMessage' {
    It 'mentions major version zero' {
        Get-NovaInitialDevelopmentVersioningMessage | Should -Match 'Major version zero'
    }
}

Describe 'Get-NovaVersionBumpInferenceUnavailableMessage' {
    It 'mentions OverrideWarning fallback' {
        Get-NovaVersionBumpInferenceUnavailableMessage | Should -Match 'OverrideWarning'
    }
}

Describe 'Get-NovaVersionUpdateLabelResolution' {
    It 'applies a Patch fallback when previewing on a stable version' {
        $info = [pscustomobject]@{Version='1.0.0'}
        $resolution = Get-NovaVersionUpdateLabelResolution -ProjectInfo $info -Label Minor -PreviewRelease
        $resolution.EffectiveLabel | Should -Be 'Patch'
    }

    It 'adds an advisory for stable bumps on 0.x.y versions' {
        $info = [pscustomobject]@{Version='0.5.0'}
        $resolution = Get-NovaVersionUpdateLabelResolution -ProjectInfo $info -Label Minor
        $resolution.AdvisoryMessage | Should -Match 'initial development'
    }

    It 'downgrades Major to Minor when at 0.x.y' {
        $info = [pscustomobject]@{Version='0.5.0'}
        $resolution = Get-NovaVersionUpdateLabelResolution -ProjectInfo $info -Label Major
        $resolution.EffectiveLabel | Should -Be 'Minor'
    }
}

Describe 'Get-NovaVersionUpdateWorkflowContextObject' {
    It 'composes a workflow context with the expected fields' {
        $info = [pscustomobject]@{ProjectJSON='/p/project.json'; Version='1.0.0'}
        $plan = [pscustomobject]@{NewVersion=[semver]'1.0.1'}
        $ctx = Get-NovaVersionUpdateWorkflowContextObject -ProjectRoot '/p' -ProjectInfo $info -CommitMessages @('feat: a') -Label 'Minor' -EffectiveLabel 'Minor' -AdvisoryMessage '' -VersionUpdatePlan $plan
        $ctx.ProjectRoot | Should -Be '/p'
        $ctx.CommitCount | Should -Be 1
        $ctx.Label | Should -Be 'Minor'
        $ctx.PreviousVersion | Should -Be '1.0.0'
        $ctx.NewVersion | Should -Be '1.0.1'
        $ctx.Target | Should -Be 'project.json'
    }
}

Describe 'Assert-NovaVersionBumpInferenceAvailability' {
    It 'returns silently when commit messages exist' {
        { Assert-NovaVersionBumpInferenceAvailability -ProjectRoot '/r' -CommitMessages @('m') } | Should -Not -Throw
    }
    It 'returns silently when no commits but git repo is available' {
        Mock Test-GitRepositoryIsAvailable {$true}
        { Assert-NovaVersionBumpInferenceAvailability -ProjectRoot '/r' } | Should -Not -Throw
    }
    It 'throws when no commits, no repo, and override not requested' {
        Mock Test-GitRepositoryIsAvailable {$false}
        Mock Write-Warning {}
        { Assert-NovaVersionBumpInferenceAvailability -ProjectRoot '/r' } | Should -Throw -ErrorId 'Nova.Workflow.VersionBumpInferenceUnavailable'
    }
    It 'warns and continues when OverrideWarningRequested' {
        Mock Test-GitRepositoryIsAvailable {$false}
        Mock Write-Warning {}
        Mock Write-Verbose {}
        { Assert-NovaVersionBumpInferenceAvailability -ProjectRoot '/r' -OverrideWarningRequested } | Should -Not -Throw
    }
}

Describe 'Get-NovaVersionUpdateWorkflowContext (entry point)' {
    It 'composes the workflow context end to end with mocked collaborators' {
        Mock Get-NovaProjectInfo {[pscustomobject]@{ProjectJSON='/r/project.json'; Version='1.2.3'}}
        Mock Get-GitCommitMessageForVersionBump {@('feat: x','fix: y')}
        Mock Test-GitRepositoryIsAvailable {$true}
        Mock Get-NovaVersionLabelForBump {'Minor'}
        Mock Get-NovaVersionUpdatePlan {[pscustomobject]@{NewVersion=[semver]'1.3.0'}}
        $ctx = Get-NovaVersionUpdateWorkflowContext -ProjectRoot '/r'
        $ctx.Label | Should -Be 'Minor'
        $ctx.EffectiveLabel | Should -Be 'Minor'
        $ctx.CommitCount | Should -Be 2
        $ctx.NewVersion | Should -Be '1.3.0'
    }
}
