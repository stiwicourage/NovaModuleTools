BeforeAll {
    $projectRoot = Split-Path -Parent (Split-Path -Parent (Split-Path -Parent $PSScriptRoot))
    . (Join-Path $projectRoot 'src/private/quality/GetNovaPesterOutputOptionOverride.ps1')
    . (Join-Path $projectRoot 'src/private/quality/InitializeNovaPesterExecutionConfiguration.ps1')
}

Describe 'Initialize-NovaPesterExecutionConfiguration' {
    It 'applies bound Verbosity/RenderMode and disables TestResult' {
        $config = [pscustomobject]@{
            Output = [pscustomobject]@{Verbosity='Default'; RenderMode='Default'}
            TestResult = [pscustomobject]@{Enabled=$true}
        }
        Initialize-NovaPesterExecutionConfiguration -PesterConfig $config -BoundParameters @{OutputVerbosity='Detailed'; OutputRenderMode='Plaintext'} -OutputVerbosity 'Detailed' -OutputRenderMode 'Plaintext'
        $config.Output.Verbosity | Should -Be 'Detailed'
        $config.Output.RenderMode | Should -Be 'Plaintext'
        $config.TestResult.Enabled | Should -BeFalse
    }

    It 'leaves Output untouched when nothing is bound' {
        $config = [pscustomobject]@{
            Output = [pscustomobject]@{Verbosity='Default'; RenderMode='Default'}
            TestResult = [pscustomobject]@{Enabled=$true}
        }
        Initialize-NovaPesterExecutionConfiguration -PesterConfig $config -BoundParameters @{}
        $config.Output.Verbosity | Should -Be 'Default'
        $config.Output.RenderMode | Should -Be 'Default'
        $config.TestResult.Enabled | Should -BeFalse
    }

    It 'does not touch TestResult when it has no Enabled property' {
        $config = [pscustomobject]@{
            Output = [pscustomobject]@{Verbosity='Default'; RenderMode='Default'}
            TestResult = [pscustomobject]@{Other='x'}
        }
        { Initialize-NovaPesterExecutionConfiguration -PesterConfig $config -BoundParameters @{} } | Should -Not -Throw
    }
}
