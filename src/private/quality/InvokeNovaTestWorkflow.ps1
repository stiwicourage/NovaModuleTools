function Invoke-NovaTestWorkflow {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][pscustomobject]$WorkflowContext,
        [switch]$ShouldRun
    )

    if (Test-NovaTestWorkflowBuildRequested -WorkflowContext $WorkflowContext) {
        $workflowParams = $WorkflowContext.WorkflowParams
        Invoke-NovaBuild @workflowParams
    }

    if (-not (Test-NovaTestWorkflowShouldRun -WorkflowContext $WorkflowContext -BoundParameters $PSBoundParameters -ShouldRun:$ShouldRun)) {
        return
    }

    Initialize-NovaPesterArtifactDirectory -WorkflowContext $WorkflowContext
    $WorkflowContext.PesterConfig.TestResult.OutputPath = $WorkflowContext.TestResultPath
    $testResult = Invoke-NovaPester -Configuration $WorkflowContext.PesterConfig
    & $WorkflowContext.TestResultArtifactWriter.ScriptBlock -TestResult $testResult -OutputPath $WorkflowContext.TestResultPath -ReportWriter $WorkflowContext.TestResultReportWriter.ScriptBlock

    if ($testResult.Result -ne 'Passed') {
        Stop-NovaOperation -Message 'Tests failed' -ErrorId 'Nova.Workflow.TestRunFailed' -Category InvalidOperation -TargetObject $WorkflowContext.TestResultPath
    }
}

function Test-NovaTestWorkflowBuildRequested {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][pscustomobject]$WorkflowContext
    )

    if ($WorkflowContext.PSObject.Properties.Name -notcontains 'BuildRequested') {
        return $false
    }

    return [bool]$WorkflowContext.BuildRequested
}

function Test-NovaTestWorkflowShouldRun {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][pscustomobject]$WorkflowContext,
        [Parameter(Mandatory)][hashtable]$BoundParameters,
        [switch]$ShouldRun
    )

    if ( $BoundParameters.ContainsKey('ShouldRun')) {
        return $ShouldRun.IsPresent
    }

    return -not (Test-NovaWhatIfWorkflowContext -WorkflowContext $WorkflowContext)
}

function Test-NovaWhatIfWorkflowContext {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][pscustomobject]$WorkflowContext
    )

    if ($WorkflowContext.PSObject.Properties.Name -notcontains 'WorkflowParams') {
        return $false
    }

    return [bool]$WorkflowContext.WorkflowParams.WhatIf
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
