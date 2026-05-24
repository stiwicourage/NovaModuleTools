function Invoke-NovaTestWorkflow {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][pscustomobject]$WorkflowContext,
        [switch]$ShouldRun
    )

    $progressActivity = 'Running Nova test workflow'
    $whatIfEnabled = Test-NovaWhatIfWorkflowContext -WorkflowContext $WorkflowContext
    $testResult = $null
    $shouldRunWorkflow = Test-NovaTestWorkflowShouldRun -WorkflowContext $WorkflowContext -BoundParameters $PSBoundParameters -ShouldRun:$ShouldRun

    try {
        Invoke-NovaTestWorkflowBuildStep -WorkflowContext $WorkflowContext -Activity $progressActivity -WhatIfEnabled:$whatIfEnabled

        if (-not $shouldRunWorkflow) {
            Write-NovaTestWorkflowPreviewResult -WorkflowContext $WorkflowContext -WhatIfEnabled:$whatIfEnabled
            return
        }

        $testResult = Invoke-NovaTestWorkflowExecution -WorkflowContext $WorkflowContext -Activity $progressActivity
    } finally {
        Write-Progress -Activity $progressActivity -Completed
    }

    Write-NovaTestWorkflowResult -WorkflowContext $WorkflowContext -TestResult $testResult
}

function Invoke-NovaTestWorkflowBuildStep {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][pscustomobject]$WorkflowContext,
        [Parameter(Mandatory)][string]$Activity,
        [switch]$WhatIfEnabled
    )

    if (-not (Test-NovaTestWorkflowBuildRequested -WorkflowContext $WorkflowContext)) {
        return
    }

    $buildCommandParameters = Get-NovaBuildCommandParameterMap -WorkflowParams (Get-NovaPropertyValue -InputObject $WorkflowContext -Name 'WorkflowParams') -OverrideWarningRequested:(($WorkflowContext.PSObject.Properties.Name -contains 'OverrideWarningRequested') -and $WorkflowContext.OverrideWarningRequested)
    Invoke-NovaTestWorkflowStep -Activity $Activity -Status (Get-NovaTestWorkflowBuildStatus -WhatIfEnabled:$WhatIfEnabled) -PercentComplete 20 -Action {
        Invoke-NovaBuild @buildCommandParameters
    }
}

function Write-NovaTestWorkflowPreviewResult {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][pscustomobject]$WorkflowContext,
        [switch]$WhatIfEnabled
    )

    if (-not $WhatIfEnabled) {
        return
    }

    Write-NovaTestWorkflowResult -WorkflowContext $WorkflowContext -WhatIfEnabled
}

function Invoke-NovaTestWorkflowExecution {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][pscustomobject]$WorkflowContext,
        [Parameter(Mandatory)][string]$Activity
    )

    Invoke-NovaTestWorkflowStep -Activity $Activity -Status 'Preparing the test result directory' -PercentComplete 40 -Action {
        Initialize-NovaPesterArtifactDirectory -WorkflowContext $WorkflowContext
    }

    $WorkflowContext.PesterConfig.TestResult.OutputPath = $WorkflowContext.TestResultPath
    $coverageTargetAssertion = Get-NovaCoverageTargetAssertionScriptBlock -WorkflowContext $WorkflowContext
    $testResult = Invoke-NovaTestWorkflowStep -Activity $Activity -Status 'Running Pester tests' -PercentComplete 70 -Action {
        Invoke-NovaPesterWithSuppressedProgress -Configuration $WorkflowContext.PesterConfig
    }

    Invoke-NovaTestWorkflowStep -Activity $Activity -Status 'Writing the test result report' -PercentComplete 85 -Action {
        & $WorkflowContext.TestResultArtifactWriter.ScriptBlock -TestResult $testResult -OutputPath $WorkflowContext.TestResultPath -ReportWriter $WorkflowContext.TestResultReportWriter.ScriptBlock
    }

    if ($testResult.Result -ne 'Passed') {
        Stop-NovaOperation -Message (Get-NovaTestWorkflowFailureMessage -WorkflowContext $WorkflowContext) -ErrorId 'Nova.Workflow.TestRunFailed' -Category InvalidOperation -TargetObject $WorkflowContext.TestResultPath
    }

    Invoke-NovaTestWorkflowStep -Activity $Activity -Status 'Checking the configured code coverage target' -PercentComplete 95 -Action {
        & $coverageTargetAssertion -WorkflowContext $WorkflowContext -TestResult $testResult
    }

    return $testResult
}

function Invoke-NovaTestWorkflowStep {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][string]$Activity,
        [Parameter(Mandatory)][string]$Status,
        [Parameter(Mandatory)][int]$PercentComplete,
        [Parameter(Mandatory)][scriptblock]$Action
    )

    Write-Progress -Activity $Activity -Status $Status -PercentComplete $PercentComplete
    & $Action
}

function Get-NovaTestWorkflowBuildStatus {
    [CmdletBinding()]
    param(
        [switch]$WhatIfEnabled
    )

    if ($WhatIfEnabled) {
        return 'Previewing the build-before-test workflow'
    }

    return 'Building the current project state'
}

function Invoke-NovaPesterWithSuppressedProgress {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][object]$Configuration
    )

    $previousProgressPreference = $global:ProgressPreference
    $global:ProgressPreference = 'SilentlyContinue'
    try {
        return Invoke-NovaPester -Configuration $Configuration
    } finally {
        $global:ProgressPreference = $previousProgressPreference
    }
}

function Get-NovaTestWorkflowFailureMessage {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][pscustomobject]$WorkflowContext
    )

    return "Pester reported one or more failing tests. Review the output above and the test result file at $( $WorkflowContext.TestResultPath ), then rerun Test-NovaBuild."
}

function Write-NovaTestWorkflowResult {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][pscustomobject]$WorkflowContext,
        [AllowNull()][object]$TestResult,
        [switch]$WhatIfEnabled
    )

    Write-Message (Get-NovaTestWorkflowStatusMessage -WorkflowContext $WorkflowContext -WhatIfEnabled:$WhatIfEnabled) -color Green
    Write-Message "Results file: $( $WorkflowContext.TestResultPath )"

    $coverageMessage = Get-NovaTestWorkflowCoverageMessage -WorkflowContext $WorkflowContext -TestResult $TestResult -WhatIfEnabled:$WhatIfEnabled
    if (-not [string]::IsNullOrWhiteSpace($coverageMessage)) {
        Write-Message $coverageMessage
    }

    foreach ($line in (Get-NovaTestWorkflowNextStepLine -WhatIfEnabled:$WhatIfEnabled)) {
        Write-Message $line
    }
}

function Get-NovaTestWorkflowStatusMessage {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][pscustomobject]$WorkflowContext,
        [switch]$WhatIfEnabled
    )

    if ($WhatIfEnabled) {
        return "Test plan ready for $( $WorkflowContext.ProjectInfo.ProjectName )"
    }

    return "Pester tests passed for $( $WorkflowContext.ProjectInfo.ProjectName )"
}

function Get-NovaTestWorkflowCoverageMessage {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][pscustomobject]$WorkflowContext,
        [AllowNull()][object]$TestResult,
        [switch]$WhatIfEnabled
    )

    $coveragePercentTarget = Get-NovaConfiguredCoveragePercentTarget -WorkflowContext $WorkflowContext
    if ($WhatIfEnabled) {
        if ($null -eq $coveragePercentTarget) {
            return $null
        }

        return "Configured coverage target: $( Format-NovaCoveragePercentValue -Value ([double]$coveragePercentTarget) )%"
    }

    $codeCoverage = Get-NovaPropertyValue -InputObject $TestResult -Name 'CodeCoverage'
    $coveragePercent = Get-NovaPropertyValue -InputObject $codeCoverage -Name 'CoveragePercent'
    if ($null -eq $coveragePercent -or [string]::IsNullOrWhiteSpace([string]$coveragePercent)) {
        return $null
    }

    $formattedCoverage = Format-NovaCoveragePercentValue -Value ([double]$coveragePercent)
    if ($null -eq $coveragePercentTarget) {
        return "Measured code coverage: $formattedCoverage%"
    }

    $formattedTarget = Format-NovaCoveragePercentValue -Value ([double]$coveragePercentTarget)
    return "Measured code coverage: $formattedCoverage% (target: $formattedTarget%)"
}

function Get-NovaTestWorkflowNextStepLine {
    [CmdletBinding()]
    param(
        [switch]$WhatIfEnabled
    )

    if ($WhatIfEnabled) {
        return @(
            'Next step:'
            'Run Test-NovaBuild without -WhatIf when you are ready to execute the test workflow.'
        )
    }

    return @(
        'Next step:'
        'Publish-NovaModule -Local'
    )
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
            $exception = [System.IO.InvalidDataException]::new("Code coverage target $formattedTarget% is configured, but the Pester result did not include a coverage percentage. Review the coverage settings in project.json and the test result file at $resolvedTargetObject.")
            $errorRecord = [System.Management.Automation.ErrorRecord]::new($exception, 'Nova.Workflow.CodeCoveragePercentMissing', [System.Management.Automation.ErrorCategory]::InvalidData, $resolvedTargetObject)
            throw $errorRecord
        }

        $coveragePercent = [double]$coveragePercent
        if ($coveragePercent -ge $resolvedCoveragePercentTarget) {
            return
        }

        $formattedCoverage = & $percentFormatter -Value $coveragePercent
        $exception = [System.InvalidOperationException]::new("Code coverage $formattedCoverage% did not meet the configured target $formattedTarget%. Review the failing tests or coverage settings, then rerun Test-NovaBuild.")
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
