function Write-NovaPesterTestResultReport {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][object]$TestResult,
        [Parameter(Mandatory)][string]$OutputPath,
        [string]$TestSuiteName = 'NovaModuleTools'
    )

    $tests = @($TestResult.Tests)
    $counts = [ordered]@{
        Total = $tests.Count
        Passed = @($tests | Where-Object Result -eq 'Passed').Count
        Failed = @($tests | Where-Object Result -eq 'Failed').Count
        Skipped = @($tests | Where-Object Result -eq 'Skipped').Count
        Inconclusive = @($tests | Where-Object Result -eq 'Inconclusive').Count
    }

    $report = @"
<?xml version="1.0" encoding="utf-8"?>
<test-results name="$TestSuiteName" total="$( $counts.Total )" errors="0" failures="$( $counts.Failed )" inconclusive="$( $counts.Inconclusive )" skipped="$( $counts.Skipped )">
  <test-suite name="$TestSuiteName" executed="True" result="$( if ($counts.Failed -eq 0) {
        'Success'
    } else {
        'Failure'
    } )" success="$( if ($counts.Failed -eq 0) {
        'True'
    } else {
        'False'
    } )" total="$( $counts.Total )" passed="$( $counts.Passed )" failed="$( $counts.Failed )" inconclusive="$( $counts.Inconclusive )" skipped="$( $counts.Skipped )" />
</test-results>
"@

    Set-Content -LiteralPath $OutputPath -Value $report -Encoding utf8
}

