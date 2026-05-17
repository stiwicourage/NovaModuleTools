BeforeAll {
    $projectRoot = Split-Path -Parent (Split-Path -Parent (Split-Path -Parent $PSScriptRoot))
    . (Join-Path $projectRoot 'src/private/package/InvokeNovaPackageUploadWorkflow.ps1')
    function Invoke-NovaPackageArtifactUpload {param($UploadArtifact) [pscustomobject]@{StatusCode=200; Artifact=$UploadArtifact}}
}

Describe 'Invoke-NovaPackageUploadWorkflow' {
    It 'returns empty when neither supplied list nor context list has artifacts' {
        $ctx = [pscustomobject]@{UploadArtifactList=@()}
        $r = Invoke-NovaPackageUploadWorkflow -WorkflowContext $ctx
        @($r).Count | Should -Be 0
    }

    It 'uploads each supplied artifact and returns the responses' {
        Mock Invoke-NovaPackageArtifactUpload {[pscustomobject]@{StatusCode=200; Artifact=$UploadArtifact}}
        $ctx = [pscustomobject]@{UploadArtifactList=@([pscustomobject]@{Name='a'})}
        $r = @(Invoke-NovaPackageUploadWorkflow -WorkflowContext $ctx -UploadArtifactList @([pscustomobject]@{Name='a'},[pscustomobject]@{Name='b'}))
        $r.Count | Should -Be 2
        Should -Invoke Invoke-NovaPackageArtifactUpload -Times 2
    }
}
