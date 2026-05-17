BeforeAll {
    $projectRoot = Split-Path -Parent (Split-Path -Parent (Split-Path -Parent $PSScriptRoot))
    . (Join-Path $projectRoot 'src/private/build/GetNovaBuildWorkflowContext.ps1')

    function Get-NovaBuildProjectInfo {param([pscustomobject]$ProjectInfo)}
}

Describe 'Get-NovaBuildWorkflowContext' {
    BeforeEach {
        $script:projectInfo = [pscustomobject]@{
            ProjectRoot = '/proj'
            OutputModuleDir = '/proj/dist/Mod'
        }
        Mock Get-NovaBuildProjectInfo {return $script:projectInfo}
    }

    It 'returns a workflow context populated from the resolved project info' {
        $ctx = Get-NovaBuildWorkflowContext

        $ctx.ProjectInfo | Should -Be $script:projectInfo
        $ctx.Target | Should -Be '/proj/dist/Mod'
        $ctx.Operation | Should -Be 'Build Nova module output'
        $ctx.ContinuousIntegrationRequested | Should -BeFalse
        $ctx.OverrideWarningRequested | Should -BeFalse
    }

    It 'reflects the CI and override switches as booleans' {
        $ctx = Get-NovaBuildWorkflowContext -ContinuousIntegrationRequested -OverrideWarningRequested

        $ctx.ContinuousIntegrationRequested | Should -BeTrue
        $ctx.OverrideWarningRequested | Should -BeTrue
    }
}
