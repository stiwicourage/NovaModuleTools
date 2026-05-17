BeforeAll {
    $projectRoot = Split-Path -Parent (Split-Path -Parent (Split-Path -Parent $PSScriptRoot))
    . (Join-Path $projectRoot 'src/private/quality/WriteNovaPesterTestResultReport.ps1')
}

Describe 'Write-NovaPesterTestResultReport' {
    BeforeEach {
        $script:out = Join-Path ([IO.Path]::GetTempPath()) ([guid]::NewGuid().ToString() + '.xml')
    }
    AfterEach { Remove-Item $script:out -Force -ErrorAction SilentlyContinue }

    It 'writes a Success report when no failures' {
        $result = [pscustomobject]@{
            Tests = @(
                [pscustomobject]@{Result='Passed'}
                [pscustomobject]@{Result='Passed'}
                [pscustomobject]@{Result='Skipped'}
            )
        }
        Write-NovaPesterTestResultReport -TestResult $result -OutputPath $script:out
        $xml = Get-Content -LiteralPath $script:out -Raw
        $xml | Should -Match 'total="3"'
        $xml | Should -Match 'passed="2"'
        $xml | Should -Match 'skipped="1"'
        $xml | Should -Match 'result="Success"'
        $xml | Should -Match 'success="True"'
    }

    It 'writes a Failure report when any test failed' {
        $result = [pscustomobject]@{
            Tests = @(
                [pscustomobject]@{Result='Passed'}
                [pscustomobject]@{Result='Failed'}
                [pscustomobject]@{Result='Inconclusive'}
            )
        }
        Write-NovaPesterTestResultReport -TestResult $result -OutputPath $script:out -TestSuiteName 'Custom'
        $xml = Get-Content -LiteralPath $script:out -Raw
        $xml | Should -Match 'name="Custom"'
        $xml | Should -Match 'failures="1"'
        $xml | Should -Match 'inconclusive="1"'
        $xml | Should -Match 'result="Failure"'
        $xml | Should -Match 'success="False"'
    }

    It 'handles empty tests collection' {
        $result = [pscustomobject]@{Tests = @()}
        Write-NovaPesterTestResultReport -TestResult $result -OutputPath $script:out
        $xml = Get-Content -LiteralPath $script:out -Raw
        $xml | Should -Match 'total="0"'
    }
}
