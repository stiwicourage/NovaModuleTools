BeforeAll {
    $projectRoot = Split-Path -Parent (Split-Path -Parent (Split-Path -Parent $PSScriptRoot))
    . (Join-Path $projectRoot 'src/private/package/InvokeNovaPackageWorkflow.ps1')
    . (Join-Path $PSScriptRoot 'InvokeNovaPackageWorkflow.TestSupport.ps1')
}

Describe 'Invoke-NovaPackageWorkflow' {
    BeforeEach {
        $script:validated = $false
        Mock Write-Message {}
        Mock Write-Progress {}
    }

    It 'validates the build and returns without creating artifacts when ShouldRun is false' {
        Mock Invoke-NovaPackageArtifactCreation {}
        $result = Invoke-NovaPackageWorkflow -WorkflowContext ([pscustomobject]@{
            WorkflowParams = @{}
            SkipTestsRequested = $false
            ProjectInfo = [pscustomobject]@{ProjectName = 'Demo'}
            Target = '/p/Demo.1.0.0.nupkg'
        })
        $script:validated | Should -BeTrue
        Should -Invoke Invoke-NovaPackageArtifactCreation -Times 0
        Should -Invoke Write-Progress -Times 2
        Should -Invoke Write-Progress -Times 1 -ParameterFilter {
            $Status -eq 'Building and testing package input' -and $PercentComplete -eq 30
        }
        Should -Invoke Write-Progress -Times 1 -ParameterFilter {$Completed}
        $result | Should -BeNullOrEmpty
    }

    It 'creates artifacts, reports progress, and prints the next suggested step when ShouldRun is set' {
        $artifacts = @([pscustomobject]@{PackagePath='/p/Demo.1.0.0.nupkg'; OutputDirectory='/p'})
        Mock Invoke-NovaPackageArtifactCreation {return $artifacts}
        $result = Invoke-NovaPackageWorkflow -WorkflowContext ([pscustomobject]@{
            WorkflowParams = @{}
            SkipTestsRequested = $false
            ProjectInfo = [pscustomobject]@{ProjectName = 'Demo'}
            Target = '/p/Demo.1.0.0.nupkg'
        }) -ShouldRun
        Should -Invoke Invoke-NovaPackageArtifactCreation -Times 1
        Should -Invoke Write-Progress -Times 3
        Should -Invoke Write-Progress -Times 1 -ParameterFilter {
            $Status -eq 'Creating package artifacts' -and $PercentComplete -eq 85
        }
        Should -Invoke Write-Progress -Times 1 -ParameterFilter {$Completed}
        Should -Invoke Write-Message -Times 3
        Should -Invoke Write-Message -Times 1 -ParameterFilter {
            $Text -eq 'Created 1 package artifact for Demo' -and $color -eq 'Green'
        }
        Should -Invoke Write-Message -Times 1 -ParameterFilter {
            $Text -eq 'Deploy-NovaPackage'
        }
        @($result).Count | Should -Be 1
    }

    It 'writes a package plan summary in WhatIf mode' {
        $result = Invoke-NovaPackageWorkflow -WorkflowContext ([pscustomobject]@{
            WorkflowParams = @{WhatIf = $true}
            SkipTestsRequested = $true
            ProjectInfo = [pscustomobject]@{ProjectName = 'Demo'}
            Target = '/p/Demo.1.0.0.nupkg'
        })

        $script:validated | Should -BeTrue
        Should -Invoke Write-Message -Times 3
        Should -Invoke Write-Progress -Times 1 -ParameterFilter {
            $Status -eq 'Building package input with tests skipped' -and $PercentComplete -eq 30
        }
        Should -Invoke Write-Progress -Times 1 -ParameterFilter {$Completed}
        Should -Invoke Write-Message -Times 1 -ParameterFilter {
            $Text -eq 'Package plan ready for Demo' -and $color -eq 'Green'
        }
        Should -Invoke Write-Message -Times 1 -ParameterFilter {
            $Text -eq 'Run New-NovaModulePackage without -WhatIf when you are ready to create the package artifacts.'
        }
        $result | Should -BeNullOrEmpty
    }
}

Describe 'Get-NovaPackageWorkflowStatusMessage' {
    It 'reports the created artifact count when more than one artifact was produced' {
        $workflowContext = [pscustomobject]@{
            ProjectInfo = [pscustomobject]@{
                ProjectName = 'Demo'
            }
        }

        Get-NovaPackageWorkflowStatusMessage -WorkflowContext $workflowContext -ArtifactCount 2 | Should -Be 'Created 2 package artifacts for Demo'
    }
}

Describe 'Get-NovaPackageWorkflowResultTarget' {
    It 'falls back to the workflow target when artifacts do not expose output directories' {
        $workflowContext = [pscustomobject]@{
            Target = '/p/Demo.1.0.0.nupkg'
        }

        $artifacts = @([pscustomobject]@{PackagePath = '/p/Demo.1.0.0.nupkg'; OutputDirectory = $null})
        Get-NovaPackageWorkflowResultTarget -WorkflowContext $workflowContext -Artifacts $artifacts | Should -Be '/p/Demo.1.0.0.nupkg'
    }
}
