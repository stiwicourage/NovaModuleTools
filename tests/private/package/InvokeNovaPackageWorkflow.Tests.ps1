BeforeAll {
    $projectRoot = Split-Path -Parent (Split-Path -Parent (Split-Path -Parent $PSScriptRoot))
    . (Join-Path $projectRoot 'src/private/package/InvokeNovaPackageWorkflow.ps1')

    function Invoke-NovaBuildValidation {param($WorkflowContext) $script:validated = $true}
    function Invoke-NovaPackageArtifactCreation {param($WorkflowContext) return @([pscustomobject]@{PackagePath='/p'})}
}

Describe 'Invoke-NovaPackageWorkflow' {
    BeforeEach {
        $script:validated = $false
    }

    It 'validates the build and returns without creating artifacts when ShouldRun is false' {
        Mock Invoke-NovaPackageArtifactCreation {}
        $result = Invoke-NovaPackageWorkflow -WorkflowContext ([pscustomobject]@{})
        $script:validated | Should -BeTrue
        Should -Invoke Invoke-NovaPackageArtifactCreation -Times 0
        $result | Should -BeNullOrEmpty
    }

    It 'creates artifacts when ShouldRun is set' {
        $artifacts = @([pscustomobject]@{PackagePath='/p'})
        Mock Invoke-NovaPackageArtifactCreation {return $artifacts}
        $result = Invoke-NovaPackageWorkflow -WorkflowContext ([pscustomobject]@{}) -ShouldRun
        Should -Invoke Invoke-NovaPackageArtifactCreation -Times 1
        @($result).Count | Should -Be 1
    }
}
