function Write-NovaPesterTestResultArtifact {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][object]$TestResult,
        [Parameter(Mandatory)][string]$OutputPath,
        [scriptblock]$ReportWriter
    )

    if ($TestResult.PSObject.Properties.Name -notcontains 'Tests') {
        return
    }

    $resolvedReportWriter = if ($null -ne $ReportWriter) {
        $ReportWriter
    }
    else {
        (Get-Command -Name Write-NovaPesterTestResultReport -CommandType Function -ErrorAction Stop).ScriptBlock
    }

    & $resolvedReportWriter -TestResult $TestResult -OutputPath $OutputPath
}
