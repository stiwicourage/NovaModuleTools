BeforeAll {
    $projectRoot = Split-Path -Parent (Split-Path -Parent (Split-Path -Parent $PSScriptRoot))
    . (Join-Path $projectRoot 'src/private/release/GetNovaVersionUpdateWorkflowContext.ps1')

    function Get-NovaCurrentVersionForUpdatePlan {param($ProjectInfo) return [semver]$ProjectInfo.Version}
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
