function Invoke-NovaTestWorkflow {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][pscustomobject]$WorkflowContext,
        [switch]$ShouldRun
    )

    if (Test-NovaTestWorkflowBuildRequested -WorkflowContext $WorkflowContext) {
        $workflowParams = Get-NovaBuildCommandParameterMap -WorkflowParams $WorkflowContext.WorkflowParams -OverrideWarningRequested:(($WorkflowContext.PSObject.Properties.Name -contains 'OverrideWarningRequested') -and $WorkflowContext.OverrideWarningRequested)
        Invoke-NovaBuild @workflowParams
    }

    if (-not (Test-NovaTestWorkflowShouldRun -WorkflowContext $WorkflowContext -BoundParameters $PSBoundParameters -ShouldRun:$ShouldRun)) {
        return
    }

    Initialize-NovaPesterArtifactDirectory -WorkflowContext $WorkflowContext
    $WorkflowContext.PesterConfig.TestResult.OutputPath = $WorkflowContext.TestResultPath
    $coverageTargetAssertion = Get-NovaCoverageTargetAssertionScriptBlock -WorkflowContext $WorkflowContext

    $previousProgressPreference = $global:ProgressPreference
    $global:ProgressPreference = 'SilentlyContinue'
    try {
        $testResult = Invoke-NovaPester -Configuration $WorkflowContext.PesterConfig
    } finally {
        $global:ProgressPreference = $previousProgressPreference
    }

    & $WorkflowContext.TestResultArtifactWriter.ScriptBlock -TestResult $testResult -OutputPath $WorkflowContext.TestResultPath -ReportWriter $WorkflowContext.TestResultReportWriter.ScriptBlock

    if ($testResult.Result -ne 'Passed') {
        Stop-NovaOperation -Message 'Tests failed' -ErrorId 'Nova.Workflow.TestRunFailed' -Category InvalidOperation -TargetObject $WorkflowContext.TestResultPath
    }

    & $coverageTargetAssertion -WorkflowContext $WorkflowContext -TestResult $testResult
}

function Test-NovaTestWorkflowBuildRequested {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][pscustomobject]$WorkflowContext
    )

    return [bool](Get-NovaPropertyValue -InputObject $WorkflowContext -Name 'BuildRequested')
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

    $workflowParams = Get-NovaPropertyValue -InputObject $WorkflowContext -Name 'WorkflowParams'
    return [bool](Get-NovaPropertyValue -InputObject $workflowParams -Name 'WhatIf')
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

function Get-NovaCoverageTargetAssertionScriptBlock {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][pscustomobject]$WorkflowContext
    )

    $coverageTargetAssertion = Get-NovaPropertyValue -InputObject $WorkflowContext -Name 'CoverageTargetAssertion'
    $coverageTargetAssertionScriptBlock = Get-NovaPropertyValue -InputObject $coverageTargetAssertion -Name 'ScriptBlock'
    if ($null -ne $coverageTargetAssertionScriptBlock) {
        return $coverageTargetAssertionScriptBlock
    }

    $coveragePercentTarget = Get-NovaConfiguredCoveragePercentTarget -WorkflowContext $WorkflowContext
    $targetObject = if ($WorkflowContext.PSObject.Properties.Name -contains 'TestResultPath') {
        $WorkflowContext.TestResultPath
    } else {
        'CodeCoverage'
    }

    return Get-NovaDefaultCoverageTargetAssertionScriptBlock -CoveragePercentTarget $coveragePercentTarget -TargetObject $targetObject
}

function Get-NovaDefaultCoverageTargetAssertionScriptBlock {
    [CmdletBinding()]
    param(
        [AllowNull()][Nullable[double]]$CoveragePercentTarget,
        [Parameter(Mandatory)][string]$TargetObject
    )

    $resolvedCoveragePercentTarget = $CoveragePercentTarget
    $resolvedTargetObject = $TargetObject
    $propertyReader = (Get-Command -Name Get-NovaPropertyValue -CommandType Function -ErrorAction Stop).ScriptBlock
    $percentFormatter = (Get-Command -Name Format-NovaCoveragePercentValue -CommandType Function -ErrorAction Stop).ScriptBlock

    return {
        param($WorkflowContext, $TestResult)

        $WorkflowContext | Out-Null

        if ($null -eq $resolvedCoveragePercentTarget) {
            return
        }

        $formattedTarget = & $percentFormatter -Value ([double]$resolvedCoveragePercentTarget)
        $codeCoverage = & $propertyReader -InputObject $TestResult -Name 'CodeCoverage'
        $coveragePercent = & $propertyReader -InputObject $codeCoverage -Name 'CoveragePercent'
        if ($null -eq $coveragePercent -or [string]::IsNullOrWhiteSpace([string]$coveragePercent)) {
            $exception = [System.IO.InvalidDataException]::new("Code coverage target $formattedTarget% is configured, but the Pester result did not include a coverage percentage.")
            $errorRecord = [System.Management.Automation.ErrorRecord]::new($exception, 'Nova.Workflow.CodeCoveragePercentMissing', [System.Management.Automation.ErrorCategory]::InvalidData, $resolvedTargetObject)
            throw $errorRecord
        }

        $coveragePercent = [double]$coveragePercent
        if ($coveragePercent -ge $resolvedCoveragePercentTarget) {
            return
        }

        $formattedCoverage = & $percentFormatter -Value $coveragePercent
        $exception = [System.InvalidOperationException]::new("Code coverage $formattedCoverage% did not meet the configured target $formattedTarget%.")
        $errorRecord = [System.Management.Automation.ErrorRecord]::new($exception, 'Nova.Workflow.CodeCoverageTargetNotMet', [System.Management.Automation.ErrorCategory]::InvalidOperation, $resolvedTargetObject)
        throw $errorRecord
    }.GetNewClosure()
}

function Get-NovaConfiguredCoveragePercentTarget {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][pscustomobject]$WorkflowContext
    )

    $projectInfo = Get-NovaPropertyValue -InputObject $WorkflowContext -Name 'ProjectInfo'
    $pesterSettings = Get-NovaPropertyValue -InputObject $projectInfo -Name 'Pester'
    $codeCoverageSettings = Get-NovaPropertyValue -InputObject $pesterSettings -Name 'CodeCoverage'

    if ($true -ne [bool](Get-NovaPropertyValue -InputObject $codeCoverageSettings -Name 'Enabled')) {
        return $null
    }

    $coveragePercentTarget = Get-NovaPropertyValue -InputObject $codeCoverageSettings -Name 'CoveragePercentTarget'
    if ($null -eq $coveragePercentTarget -or [string]::IsNullOrWhiteSpace([string]$coveragePercentTarget)) {
        return $null
    }

    return [double]$coveragePercentTarget
}

function Get-NovaPropertyValue {
    [CmdletBinding()]
    param(
        [AllowNull()][object]$InputObject,
        [Parameter(Mandatory)][string]$Name
    )

    if ($null -eq $InputObject) {
        return $null
    }

    if ($InputObject -is [System.Collections.IDictionary]) {
        if ( $InputObject.Contains($Name)) {
            return $InputObject[$Name]
        }

        return $null
    }

    if ($InputObject.PSObject.Properties.Name -contains $Name) {
        return $InputObject.$Name
    }

    return $null
}

function Format-NovaCoveragePercentValue {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][double]$Value
    )

    return [string]::Format([System.Globalization.CultureInfo]::InvariantCulture, '{0:0.##}', $Value)
}
