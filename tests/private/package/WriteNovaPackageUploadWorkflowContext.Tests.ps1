BeforeAll {
    $projectRoot = Split-Path -Parent (Split-Path -Parent (Split-Path -Parent $PSScriptRoot))
    . (Join-Path $projectRoot 'src/private/package/WriteNovaPackageUploadWorkflowContext.ps1')
}

Describe 'Write-NovaPackageUploadWorkflowContext' {
    BeforeEach {
        Mock Write-Host {}
        Mock Write-Verbose {}
    }

    It 'writes a ready message and verbose target for multiple artifacts' {
        $workflowContext = [pscustomobject]@{
            UploadArtifactList = @([pscustomobject]@{}, [pscustomobject]@{})
            Target = 'https://packages.example/raw/'
            Operation = 'Upload 2 package artifacts'
        }

        Write-NovaPackageUploadWorkflowContext -WorkflowContext $workflowContext

        Should -Invoke Write-Host -Times 1 -ParameterFilter {$Object -eq 'Ready to upload 2 package artifacts.'}
        Should -Invoke Write-Verbose -Times 1 -ParameterFilter {$Message -eq 'Target: https://packages.example/raw/'}
    }

    It 'writes the operation message for a single artifact' {
        $workflowContext = [pscustomobject]@{
            UploadArtifactList = @([pscustomobject]@{})
            Target = ''
            Operation = 'Upload NuGet package artifact NovaModuleTools.1.0.0.nupkg'
        }

        Write-NovaPackageUploadWorkflowContext -WorkflowContext $workflowContext

        Should -Invoke Write-Host -Times 1 -ParameterFilter {$Object -eq 'Upload NuGet package artifact NovaModuleTools.1.0.0.nupkg.'}
        Should -Invoke Write-Verbose -Times 0
    }
}
