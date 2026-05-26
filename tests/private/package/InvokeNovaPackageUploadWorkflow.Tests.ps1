BeforeAll {
    $projectRoot = Split-Path -Parent (Split-Path -Parent (Split-Path -Parent $PSScriptRoot))
    . (Join-Path $projectRoot 'src/private/package/InvokeNovaPackageUploadWorkflow.ps1')
    function Invoke-NovaPackageArtifactUpload {param($UploadArtifact) [pscustomobject]@{StatusCode=200; Artifact=$UploadArtifact}}
}

Describe 'Invoke-NovaPackageUploadWorkflow' {
    BeforeEach {
        Mock Write-Progress {}
    }

    It 'returns empty when neither supplied list nor context list has artifacts' {
        $ctx = [pscustomobject]@{UploadArtifactList=@()}
        $r = Invoke-NovaPackageUploadWorkflow -WorkflowContext $ctx
        @($r).Count | Should -Be 0
        Should -Invoke Write-Progress -Times 0
    }

    It 'uploads each supplied artifact, reports progress, and returns the responses' {
        Mock Invoke-NovaPackageArtifactUpload {[pscustomobject]@{StatusCode=200; Artifact=$UploadArtifact}}
        $ctx = [pscustomobject]@{UploadArtifactList=@([pscustomobject]@{PackageFileName='a.nupkg'})}
        $r = @(Invoke-NovaPackageUploadWorkflow -WorkflowContext $ctx -UploadArtifactList @([pscustomobject]@{PackageFileName='a.nupkg'},[pscustomobject]@{PackageFileName='b.nupkg'}))
        $r.Count | Should -Be 2
        Should -Invoke Invoke-NovaPackageArtifactUpload -Times 2
        Should -Invoke Write-Progress -Times 2 -ParameterFilter {-not $Completed}
        Should -Invoke Write-Progress -Times 1 -ParameterFilter {$Completed}
        Should -Invoke Write-Progress -Times 1 -ParameterFilter {
            (-not $Completed) -and
            $Status -eq 'Uploading a.nupkg (1 of 2)' -and
            $PercentComplete -eq 0
        }
        Should -Invoke Write-Progress -Times 1 -ParameterFilter {
            (-not $Completed) -and
            $Status -eq 'Uploading b.nupkg (2 of 2)' -and
            $PercentComplete -eq 50
        }
    }

    It 'uses a generic progress status when the artifact file name is blank' {
        Mock Invoke-NovaPackageArtifactUpload {[pscustomobject]@{StatusCode=200; Artifact=$UploadArtifact}}
        $ctx = [pscustomobject]@{UploadArtifactList=@()}

        $null = Invoke-NovaPackageUploadWorkflow -WorkflowContext $ctx -UploadArtifactList @([pscustomobject]@{PackageFileName=''})

        Should -Invoke Write-Progress -Times 1 -ParameterFilter {
            (-not $Completed) -and
            $Status -eq 'Uploading artifact 1 of 1'
        }
        Should -Invoke Write-Progress -Times 1 -ParameterFilter {$Completed}
    }

    It 'falls back to the workflow context artifact list when no explicit upload list is supplied' {
        Mock Invoke-NovaPackageArtifactUpload {[pscustomobject]@{StatusCode=200; Artifact=$UploadArtifact}}
        $ctx = [pscustomobject]@{UploadArtifactList=@([pscustomobject]@{PackageFileName='a.nupkg'})}
        $r = @(Invoke-NovaPackageUploadWorkflow -WorkflowContext $ctx)
        $r.Count | Should -Be 1
        Should -Invoke Invoke-NovaPackageArtifactUpload -Times 1
    }
}
