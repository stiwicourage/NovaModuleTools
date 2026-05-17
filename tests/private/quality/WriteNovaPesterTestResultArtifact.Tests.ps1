BeforeAll {
    $projectRoot = Split-Path -Parent (Split-Path -Parent (Split-Path -Parent $PSScriptRoot))
    . (Join-Path $projectRoot 'src/private/quality/WriteNovaPesterTestResultArtifact.ps1')

    function Write-NovaPesterTestResultReport {
        param($TestResult, $OutputPath)
        $script:defaultWriterCalled = $true
        $script:defaultWriterOutputPath = $OutputPath
    }
}

Describe 'Write-NovaPesterTestResultArtifact' {
    BeforeEach {
        $script:defaultWriterCalled = $false
        $script:defaultWriterOutputPath = $null
    }

    It 'returns without invoking any writer when the result has no Tests property' {
        $result = [pscustomobject]@{Result = 'Passed'}
        $custom = {param($TestResult, $OutputPath) throw 'should not be called'}

        {Write-NovaPesterTestResultArtifact -TestResult $result -OutputPath '/tmp/x.xml' -ReportWriter $custom} | Should -Not -Throw
        $script:defaultWriterCalled | Should -BeFalse
    }

    It 'invokes the provided report writer when one is supplied' {
        $script:customCalled = $false
        $custom = {param($TestResult, $OutputPath) $script:customCalled = $true}
        $result = [pscustomobject]@{Tests = @(); Result = 'Passed'}

        Write-NovaPesterTestResultArtifact -TestResult $result -OutputPath '/tmp/x.xml' -ReportWriter $custom

        $script:customCalled | Should -BeTrue
        $script:defaultWriterCalled | Should -BeFalse
    }

    It 'falls back to the default writer when no report writer is provided' {
        $result = [pscustomobject]@{Tests = @(); Result = 'Passed'}

        Write-NovaPesterTestResultArtifact -TestResult $result -OutputPath '/tmp/x.xml'

        $script:defaultWriterCalled | Should -BeTrue
        $script:defaultWriterOutputPath | Should -Be '/tmp/x.xml'
    }
}
