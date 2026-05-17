BeforeAll {
    $projectRoot = Split-Path -Parent (Split-Path -Parent (Split-Path -Parent $PSScriptRoot))
    . (Join-Path $projectRoot 'src/private/package/GetNovaPackageUploadWorkflowContext.ps1')
    function Get-NovaProjectInfo {[pscustomobject]@{Name='X'}}
    function New-NovaPackageUploadOption {param($BoundParameters) [pscustomobject]@{Repository='Nuget'}}
    function Resolve-NovaPackageUploadInvocation {param($ProjectInfo,$UploadOption) @([pscustomobject]@{ArtifactPath='/a.nupkg'})}
    function Get-NovaPackageUploadWorkflowTarget {param($UploadArtifactList) ($UploadArtifactList.ArtifactPath -join ', ')}
    function Get-NovaPackageUploadWorkflowOperation {param($UploadArtifactList) "Upload $($UploadArtifactList.Count) artifact(s)"}
}

Describe 'Get-NovaPackageUploadWorkflowContext' {
    It 'resolves project info and upload option when not supplied' {
        Mock Get-NovaProjectInfo {[pscustomobject]@{Name='FromDisk'}}
        Mock New-NovaPackageUploadOption {[pscustomobject]@{Repository='R'}}
        $item = [pscustomobject]@{ArtifactPath='/a'}
        Mock Resolve-NovaPackageUploadInvocation { @($item) }.GetNewClosure()
        $ctx = Get-NovaPackageUploadWorkflowContext -BoundParameters @{}
        $ctx.ProjectInfo.Name | Should -Be 'FromDisk'
        $ctx.UploadOption.Repository | Should -Be 'R'
        $ctx.UploadArtifactList.Count | Should -Be 1
        $ctx.Target | Should -Be '/a'
    }

    It 'uses supplied project info and upload option' {
        Mock Get-NovaProjectInfo {throw 'should not be called'}
        Mock New-NovaPackageUploadOption {throw 'should not be called'}
        $x = [pscustomobject]@{ArtifactPath='/x'}
        $y = [pscustomobject]@{ArtifactPath='/y'}
        Mock Resolve-NovaPackageUploadInvocation { @($x, $y) }.GetNewClosure()
        $ctx = Get-NovaPackageUploadWorkflowContext -BoundParameters @{} -ProjectInfo ([pscustomobject]@{Name='Supplied'}) -UploadOption ([pscustomobject]@{Repository='Custom'})
        $ctx.ProjectInfo.Name | Should -Be 'Supplied'
        $ctx.UploadOption.Repository | Should -Be 'Custom'
        $ctx.UploadArtifactList.Count | Should -Be 2
    }
}
