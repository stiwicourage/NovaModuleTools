BeforeAll {
    $projectRoot = Split-Path -Parent (Split-Path -Parent (Split-Path -Parent $PSScriptRoot))
    . (Join-Path $projectRoot 'src/private/package/GetNovaPackageWorkflowContext.ps1')
    function Get-NovaProjectInfo {[pscustomobject]@{Name='ProjFromDisk'}}
    function Get-NovaPackageMetadataList {param($ProjectInfo) ,@([pscustomobject]@{Type='NuGet'; PackagePath='/p/a.nupkg'})}
    function Assert-NovaPackageMetadata {param($PackageMetadata)}
}

Describe 'Get-NovaPackageWorkflowProjectInfo' {
    It 'returns supplied project info' {
        $info = [pscustomobject]@{Name='X'}
        Get-NovaPackageWorkflowProjectInfo -ProjectInfo $info | Should -Be $info
    }
    It 'falls back to Get-NovaProjectInfo when not supplied' {
        Mock Get-NovaProjectInfo {[pscustomobject]@{Name='Fallback'}}
        (Get-NovaPackageWorkflowProjectInfo).Name | Should -Be 'Fallback'
    }
}

Describe 'Get-NovaPackageWorkflowTarget' {
    It 'joins package paths with comma' {
        $list = @(
            [pscustomobject]@{PackagePath='/a.nupkg'},
            [pscustomobject]@{PackagePath='/b.zip'}
        )
        Get-NovaPackageWorkflowTarget -PackageMetadataList $list | Should -Be '/a.nupkg, /b.zip'
    }
}

Describe 'Get-NovaPackageWorkflowOperation' {
    It 'describes single-package operation with built-and-tested phrasing' {
        $list = @([pscustomobject]@{Type='NuGet'; PackagePath='/a'})
        Get-NovaPackageWorkflowOperation -PackageMetadataList $list | Should -Be 'Create NuGet package from built and tested module output'
    }
    It 'mentions skipped tests when requested' {
        $list = @([pscustomobject]@{Type='NuGet'; PackagePath='/a'})
        Get-NovaPackageWorkflowOperation -PackageMetadataList $list -SkipTestsRequested | Should -Be 'Create NuGet package from built module output with tests skipped'
    }
    It 'uses plural artifacts phrasing for multiple packages' {
        $list = @([pscustomobject]@{Type='NuGet'; PackagePath='/a'},[pscustomobject]@{Type='Zip'; PackagePath='/b'})
        Get-NovaPackageWorkflowOperation -PackageMetadataList $list | Should -Be 'Create package artifacts from built and tested module output'
    }
}

Describe 'Get-NovaPackageWorkflowContext' {
    It 'builds the workflow context with the resolved metadata list and target' {
        $item = [pscustomobject]@{Type='NuGet'; PackagePath='/p/a.nupkg'}
        Mock Get-NovaPackageMetadataList { @($item) }.GetNewClosure()
        Mock Assert-NovaPackageMetadata {}
        $ctx = Get-NovaPackageWorkflowContext -ProjectInfo ([pscustomobject]@{Name='X'}) -WorkflowParams @{Path='/r'} -SkipTestsRequested -OverrideWarningRequested
        $ctx.SkipTestsRequested | Should -BeTrue
        $ctx.OverrideWarningRequested | Should -BeTrue
        $ctx.PackageMetadataList.Count | Should -Be 1
        $ctx.Target | Should -Be '/p/a.nupkg'
        $ctx.Operation | Should -Match 'tests skipped'
        $ctx.WorkflowParams.Path | Should -Be '/r'
        Should -Invoke Assert-NovaPackageMetadata -Times 1
    }
}
