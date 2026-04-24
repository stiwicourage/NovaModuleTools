function Invoke-NovaTestWorkflow {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][pscustomobject]$WorkflowContext
    )

    Initialize-NovaPesterArtifactDirectory -WorkflowContext $WorkflowContext
    $WorkflowContext.PesterConfig.TestResult.OutputPath = $WorkflowContext.TestResultPath
    $testResult = Invoke-NovaPester -Configuration $WorkflowContext.PesterConfig
    & $WorkflowContext.TestResultArtifactWriter.ScriptBlock -TestResult $testResult -OutputPath $WorkflowContext.TestResultPath -ReportWriter $WorkflowContext.TestResultReportWriter.ScriptBlock

    if ($testResult.Result -ne 'Passed') {
        Stop-NovaOperation -Message 'Tests failed' -ErrorId 'Nova.Workflow.TestRunFailed' -Category InvalidOperation -TargetObject $WorkflowContext.TestResultPath
    }
}

function Initialize-NovaPesterArtifactDirectory {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][pscustomobject]$WorkflowContext
    )

    if (Test-Path -LiteralPath $WorkflowContext.TestResultDirectory) {
        return
    }

    $null = New-Item -ItemType Directory -Path $WorkflowContext.TestResultDirectory -Force
}


