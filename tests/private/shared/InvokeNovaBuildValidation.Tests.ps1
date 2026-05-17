BeforeAll {
    $projectRoot = Split-Path -Parent (Split-Path -Parent (Split-Path -Parent $PSScriptRoot))
    . (Join-Path $projectRoot 'src/private/shared/InvokeNovaBuildValidation.ps1')

    function Get-NovaBuildCommandParameterMap {param([hashtable]$WorkflowParams, [switch]$OverrideWarningRequested)
        return $WorkflowParams
    }
    function Invoke-NovaBuild {param()}
    function Test-NovaBuild {param()}
}

Describe 'Invoke-NovaBuildValidation' {
    BeforeEach {
        Mock Invoke-NovaBuild {}
        Mock Test-NovaBuild {}
    }

    It 'invokes both build and test by default' {
        $context = [pscustomobject]@{WorkflowParams = @{Path = '/p'}}

        Invoke-NovaBuildValidation -WorkflowContext $context

        Assert-MockCalled Invoke-NovaBuild -Times 1
        Assert-MockCalled Test-NovaBuild -Times 1
    }

    It 'skips Test-NovaBuild when SkipTestsRequested is true' {
        $context = [pscustomobject]@{WorkflowParams = @{Path = '/p'}; SkipTestsRequested = $true}

        Invoke-NovaBuildValidation -WorkflowContext $context

        Assert-MockCalled Invoke-NovaBuild -Times 1
        Assert-MockCalled Test-NovaBuild -Times 0
    }
}
