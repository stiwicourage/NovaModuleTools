BeforeAll {
    $projectRoot = Split-Path -Parent (Split-Path -Parent (Split-Path -Parent $PSScriptRoot))
    . (Join-Path $projectRoot 'src/private/release/GetNovaVersionUpdatePlan.ps1')
    . (Join-Path $projectRoot 'src/private/release/GetNovaVersionPartForLabel.ps1')
    . (Join-Path $projectRoot 'src/private/release/GetNovaVersionPreReleaseLabel.ps1')

    function Get-NovaProjectInfo {return [pscustomobject]@{ProjectJSON='/project.json'; Version='1.2.3'}}
    function Read-ProjectJsonData {param($ProjectJsonPath) return [pscustomobject]@{Version='1.2.3'}}
}

Describe 'Get-NovaVersionUpdateProjectInfo' {
    It 'returns provided ProjectInfo unchanged' {
        $info = [pscustomobject]@{ProjectName='X'}
        Get-NovaVersionUpdateProjectInfo -ProjectInfo $info | Should -Be $info
    }

    It 'falls back to Get-NovaProjectInfo when null' {
        Get-NovaVersionUpdateProjectInfo -ProjectInfo $null | Should -Not -BeNullOrEmpty
    }
}

Describe 'Get-NovaCurrentVersionForUpdatePlan' {
    It 'reads version from ProjectInfo when available' {
        $info = [pscustomobject]@{Version='1.2.3'; ProjectJSON='/project.json'}
        (Get-NovaCurrentVersionForUpdatePlan -ProjectInfo $info).ToString() | Should -Be '1.2.3'
    }

    It 'falls back to project.json data when ProjectInfo.Version is blank' {
        $info = [pscustomobject]@{Version=''; ProjectJSON='/project.json'}
        (Get-NovaCurrentVersionForUpdatePlan -ProjectInfo $info).ToString() | Should -Be '1.2.3'
    }
}

Describe 'Get-NovaVersionPartForUpdatePlan' {
    It 'returns the current parts when PreviewRelease and there is already a prerelease label' {
        $version = [semver]'1.2.3-preview01'
        $parts = Get-NovaVersionPartForUpdatePlan -CurrentVersion $version -Label Patch -PreviewRelease
        $parts.Major | Should -Be 1
        $parts.Patch | Should -Be 3
    }

    It 'returns a Patch bump when PreviewRelease but no prerelease label' {
        $version = [semver]'1.2.3'
        $parts = Get-NovaVersionPartForUpdatePlan -CurrentVersion $version -Label Major -PreviewRelease
        $parts.Patch | Should -Be 4
    }

    It 'delegates to Get-NovaVersionPartForLabel for stable releases' {
        $version = [semver]'1.2.3'
        $parts = Get-NovaVersionPartForUpdatePlan -CurrentVersion $version -Label Minor
        $parts.Minor | Should -Be 3
        $parts.Patch | Should -Be 0
    }
}

Describe 'Test-NovaVersionShouldPreserveInitialStableReleaseTarget' {
    It 'returns true for exact stable 1.0.0 without preview mode' {
        Test-NovaVersionShouldPreserveInitialStableReleaseTarget -CurrentVersion ([semver]'1.0.0') | Should -BeTrue
    }

    It 'returns false when preview mode is requested' {
        Test-NovaVersionShouldPreserveInitialStableReleaseTarget -CurrentVersion ([semver]'1.0.0') -PreviewRelease | Should -BeFalse
    }

    It 'returns false when the current version is already a prerelease' {
        Test-NovaVersionShouldPreserveInitialStableReleaseTarget -CurrentVersion ([semver]'1.0.0-preview01') | Should -BeFalse
    }
}

Describe 'Get-NovaVersionUpdatePlan' {
    It 'returns a plan with project file and new version' {
        $info = [pscustomobject]@{ProjectJSON='/project.json'; Version='1.2.3'}
        $plan = Get-NovaVersionUpdatePlan -ProjectInfo $info -Label Patch
        $plan.ProjectFile | Should -Be '/project.json'
        $plan.NewVersion.ToString() | Should -Be '1.2.4'
    }

    It 'keeps exact stable 1.0.0 regardless of inferred release label' -ForEach @(
        @{ Scenario = 'fix commits'; Label = 'Patch' }
        @{ Scenario = 'feature commits'; Label = 'Minor' }
        @{ Scenario = 'breaking commits'; Label = 'Major' }
    ) {
        $info = [pscustomobject]@{ProjectJSON='/project.json'; Version='1.0.0'}

        $plan = Get-NovaVersionUpdatePlan -ProjectInfo $info -Label $Label

        $plan.NewVersion.ToString() | Should -Be '1.0.0' -Because "$Scenario should respect a manually selected initial stable release target"
    }

    It 'keeps preview mode on the next patch preview track for exact stable 1.0.0' {
        $info = [pscustomobject]@{ProjectJSON='/project.json'; Version='1.0.0'}

        $plan = Get-NovaVersionUpdatePlan -ProjectInfo $info -Label Major -PreviewRelease

        $plan.NewVersion.ToString() | Should -Be '1.0.1-preview'
    }
}
