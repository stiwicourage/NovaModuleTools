function Get-NovaProjectInfo {[pscustomobject]@{Name='X'}}
function New-NovaPackageUploadOption {param($BoundParameters) [pscustomobject]@{Repository='Nuget'}}
function Resolve-NovaPackageUploadInvocation {param($ProjectInfo,$UploadOption) @([pscustomobject]@{ArtifactPath='/a.nupkg'})}
function Get-NovaPackageUploadWorkflowTarget {param($UploadArtifactList) ($UploadArtifactList.ArtifactPath -join ', ')}
function Get-NovaPackageUploadWorkflowOperation {param($UploadArtifactList) "Upload $($UploadArtifactList.Count) artifact(s)"}
