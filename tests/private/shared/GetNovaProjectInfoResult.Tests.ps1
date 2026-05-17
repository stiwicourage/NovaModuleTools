BeforeAll {
    $projectRoot = Split-Path -Parent (Split-Path -Parent (Split-Path -Parent $PSScriptRoot))
    . (Join-Path $projectRoot 'src/private/shared/GetNovaProjectInfoResult.ps1')

    . (Join-Path $PSScriptRoot 'GetNovaProjectInfoResult.TestSupport.ps1')
}

Describe 'Get-NovaProjectInfoResult' {
    BeforeEach {
        $script:jsonData = [ordered]@{
            ProjectName = 'Mod'
            Version = '1.2.3'
            Description = 'Desc'
        }
        $script:context = [pscustomobject]@{
            ProjectRoot = '/repo'
            ProjectJson = '/repo/project.json'
            JsonData = $script:jsonData
        }
    }

    It 'returns just the version when -Version is set' {
        Get-NovaProjectInfoResult -WorkflowContext $script:context -Version | Should -Be '1.2.3'
    }

    It 'fills boolean defaults when JSON omits them' {
        $info = Get-NovaProjectInfoResult -WorkflowContext $script:context
        $info.BuildRecursiveFolders | Should -BeTrue
        $info.FailOnDuplicateFunctionNames | Should -BeTrue
        $info.SetSourcePath | Should -BeTrue
        $info.CopyResourcesToModuleRoot | Should -BeFalse
    }

    It 'honors boolean overrides from JSON' {
        $script:jsonData['CopyResourcesToModuleRoot'] = $true
        $script:jsonData['SetSourcePath'] = $false
        $info = Get-NovaProjectInfoResult -WorkflowContext $script:context
        $info.CopyResourcesToModuleRoot | Should -BeTrue
        $info.SetSourcePath | Should -BeFalse
    }

    It 'computes the derived paths off the project root' {
        $info = Get-NovaProjectInfoResult -WorkflowContext $script:context
        $info.PublicDir | Should -Be ([IO.Path]::Combine('/repo','src','public'))
        $info.PrivateDir | Should -Be ([IO.Path]::Combine('/repo','src','private'))
        $info.ClassesDir | Should -Be ([IO.Path]::Combine('/repo','src','classes'))
        $info.ResourcesDir | Should -Be ([IO.Path]::Combine('/repo','src','resources'))
        $info.TestsDir | Should -Be ([IO.Path]::Combine('/repo','tests'))
        $info.DocsDir | Should -Be ([IO.Path]::Combine('/repo','docs'))
        $info.OutputDir | Should -Be ([IO.Path]::Combine('/repo','dist'))
        $info.OutputModuleDir | Should -Be ([IO.Path]::Combine('/repo','dist','Mod'))
        $info.ModuleFilePSM1 | Should -Be ([IO.Path]::Combine('/repo','dist','Mod','Mod.psm1'))
        $info.ManifestFilePSD1 | Should -Be ([IO.Path]::Combine('/repo','dist','Mod','Mod.psd1'))
    }

    It 'attaches Manifest and Package settings via collaborators' {
        Mock Get-NovaResolvedProjectManifestSettings { @{Author='Alice'} }
        Mock Get-NovaResolvedProjectPackageSettings { @{Id='Pkg'} }
        $info = Get-NovaProjectInfoResult -WorkflowContext $script:context
        $info.Manifest.Author | Should -Be 'Alice'
        $info.Package.Id | Should -Be 'Pkg'
        Assert-MockCalled Get-NovaResolvedProjectManifestSettings -Times 1
        Assert-MockCalled Get-NovaResolvedProjectPackageSettings -Times 1
    }

    It 'invokes Get-ProjectPreamble and stores the result' {
        Mock Get-ProjectPreamble { @('# generated','# preamble') }
        $info = Get-NovaProjectInfoResult -WorkflowContext $script:context
        $info.Preamble.Count | Should -Be 2
    }
}
