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

        if (-not (Test-NovaTestWorkflowHasDiscoveredTest -WorkflowContext $WorkflowContext)) {
            Write-NovaTestWorkflowNoTestsDiscoveredResult -WorkflowContext $WorkflowContext
            return
        }

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

function Write-NovaTestWorkflowNoTestsDiscoveredResult {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][pscustomobject]$WorkflowContext
    )

    $messageLines = @(Get-NovaPropertyValue -InputObject $WorkflowContext -Name 'TestDiscoveryMessageLines')
    if ($messageLines.Count -eq 0) {
        return
    }

    Write-Warning $messageLines[0]
    foreach ($line in $messageLines | Select-Object -Skip 1) {
        Write-Message $line
    }
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
    $testProgressContext = [pscustomobject]@{
        Activity = $Activity
        StartPercentComplete = 70
        EndPercentComplete = 94
    }
    $testResult = Invoke-NovaPesterWithSuppressedProgress -Configuration $WorkflowContext.PesterConfig -ProgressContext $testProgressContext

    Invoke-NovaTestWorkflowStep -Activity $Activity -Status 'Writing the test result report' -PercentComplete 96 -Action {
        & $WorkflowContext.TestResultArtifactWriter.ScriptBlock -TestResult $testResult -OutputPath $WorkflowContext.TestResultPath -ReportWriter $WorkflowContext.TestResultReportWriter.ScriptBlock
    }

    if ($testResult.Result -ne 'Passed') {
        Stop-NovaOperation -Message (Get-NovaTestWorkflowFailureMessage -WorkflowContext $WorkflowContext) -ErrorId 'Nova.Workflow.TestRunFailed' -Category InvalidOperation -TargetObject $WorkflowContext.TestResultPath
    }

    Invoke-NovaTestWorkflowStep -Activity $Activity -Status 'Checking the configured code coverage target' -PercentComplete 99 -Action {
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
        [Parameter(Mandatory)][object]$Configuration,
        [Parameter(Mandatory)][pscustomobject]$ProgressContext
    )

    $heartbeatMilliseconds = Get-NovaPropertyValue -InputObject $ProgressContext -Name 'HeartbeatMilliseconds'
    if ($null -eq $heartbeatMilliseconds) {
        $heartbeatMilliseconds = 2000
    }

    $moduleSpecification = Get-NovaPropertyValue -InputObject $Configuration -Name 'PesterModuleSpecification'
    $execution = Get-NovaPesterExecution -Configuration $Configuration -ModuleSpecification $moduleSpecification
    try {
        Write-NovaTestWorkflowPesterProgress -Execution $execution -ProgressContext $ProgressContext
        while (-not (Wait-NovaPesterExecution -Execution $execution -TimeoutMilliseconds $HeartbeatMilliseconds)) {
            Write-NovaPesterExecutionOutput -Execution $execution
            Write-NovaTestWorkflowPesterProgress -Execution $execution -ProgressContext $ProgressContext
        }

        Write-NovaPesterExecutionOutput -Execution $execution
        Write-NovaTestWorkflowPesterProgress -Execution $execution -ProgressContext $ProgressContext
        return Receive-NovaPesterExecutionResult -Execution $execution
    } finally {
        Complete-NovaPesterExecution -Execution $execution
    }
}

function Write-NovaPesterExecutionOutput {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][pscustomobject]$Execution
    )

    $informationRecords = @(Get-NovaPesterExecutionInformationRecordBuffer -Execution $Execution)
    $nextInformationRecordIndex = Get-NovaPropertyValue -InputObject $Execution -Name 'NextInformationRecordIndex'
    if ($null -eq $nextInformationRecordIndex) {
        $nextInformationRecordIndex = 0
    }

    while ($nextInformationRecordIndex -lt $informationRecords.Count) {
        $record = $informationRecords[$nextInformationRecordIndex]
        Invoke-NovaPesterExecutionProgressStateUpdate -Execution $Execution -Record $record
        Write-NovaPesterInformationRecord -Record $record
        $nextInformationRecordIndex += 1
    }

    $Execution.NextInformationRecordIndex = $nextInformationRecordIndex
}

function Get-NovaPesterExecutionInformationRecordBuffer {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][pscustomobject]$Execution
    )

    $powershell = Get-NovaPropertyValue -InputObject $Execution -Name 'PowerShell'
    if ($null -eq $powershell) {
        return @()
    }

    return @(Get-NovaPropertyValue -InputObject $powershell.Streams -Name 'Information')
}

function Write-NovaPesterInformationRecord {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][object]$Record
    )

    $messageData = Get-NovaPropertyValue -InputObject $Record -Name 'MessageData'
    $tags = @(Get-NovaPropertyValue -InputObject $Record -Name 'Tags')
    if (($tags -contains 'PSHOST') -and (Test-NovaPesterHostInformationMessage -MessageData $messageData)) {
        Write-NovaPesterHostInformationMessage -MessageData $messageData
        return
    }

    Write-Information -MessageData $messageData -Tags $tags -InformationAction Continue
}

function Invoke-NovaPesterExecutionProgressStateUpdate {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][pscustomobject]$Execution,
        [Parameter(Mandatory)][object]$Record
    )

    $messageText = Get-NovaPesterInformationMessageText -Record $Record
    $discoveredTestCount = Get-NovaPesterDiscoveredTestCount -MessageText $messageText
    if ($null -ne $discoveredTestCount) {
        $Execution.TotalTestCount = $discoveredTestCount
        return
    }

    if (Test-NovaPesterTestCompletionMessage -Record $Record -MessageText $messageText) {
        $Execution.CompletedTestCount = (Get-NovaPropertyValue -InputObject $Execution -Name 'CompletedTestCount') + 1
    }
}

function Get-NovaPesterInformationMessageText {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][object]$Record
    )

    $messageData = Get-NovaPropertyValue -InputObject $Record -Name 'MessageData'
    if (Test-NovaPesterHostInformationMessage -MessageData $messageData) {
        return [string](Get-NovaPropertyValue -InputObject $messageData -Name 'Message')
    }

    return [string]$messageData
}

function Get-NovaPesterDiscoveredTestCount {
    [CmdletBinding()]
    param(
        [AllowNull()][string]$MessageText
    )

    $match = [System.Text.RegularExpressions.Regex]::Match([string]$MessageText, 'Discovery found (?<Count>\d+) tests? in')
    if (-not $match.Success) {
        return $null
    }

    return [int]$match.Groups['Count'].Value
}

function Test-NovaPesterTestCompletionMessage {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][object]$Record,
        [AllowNull()][string]$MessageText
    )

    $messageData = Get-NovaPropertyValue -InputObject $Record -Name 'MessageData'
    if (-not (Test-NovaPesterHostInformationMessage -MessageData $messageData)) {
        return $false
    }

    if ($true -ne [bool](Get-NovaPropertyValue -InputObject $messageData -Name 'NoNewLine')) {
        return $false
    }

    return [string]$MessageText -match '^\s+\[(\+|-|!|\?)\]\s+'
}

function Test-NovaPesterHostInformationMessage {
    [CmdletBinding()]
    param(
        [AllowNull()][object]$MessageData
    )

    return $null -ne $MessageData -and $MessageData.PSObject.Properties.Name -contains 'Message'
}

function Write-NovaPesterHostInformationMessage {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][object]$MessageData
    )

    $writeHostParameters = @{
        Object = $MessageData.Message
    }

    if ($true -eq [bool](Get-NovaPropertyValue -InputObject $MessageData -Name 'NoNewLine')) {
        $writeHostParameters.NoNewline = $true
    }

    foreach ($colorName in 'ForegroundColor', 'BackgroundColor') {
        $colorValue = Get-NovaPropertyValue -InputObject $MessageData -Name $colorName
        if ($null -ne $colorValue) {
            $writeHostParameters[$colorName] = $colorValue
        }
    }

    Write-Host @writeHostParameters
}

function Get-NovaPesterExecution {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][object]$Configuration,
        [AllowNull()][object]$ModuleSpecification
    )

    $powershell = [powershell]::Create()
    $command = @'
param($Configuration, $ModuleSpecification)
if ($null -ne $ModuleSpecification) {
    Import-Module -FullyQualifiedName $ModuleSpecification -Force -ErrorAction Stop
}
else {
    Import-Module Pester -ErrorAction Stop
}
$previousProgressPreference = $global:ProgressPreference
$global:ProgressPreference = 'SilentlyContinue'
try {
    Invoke-Pester -Configuration $Configuration
} finally {
    $global:ProgressPreference = $previousProgressPreference
}
'@
    $moduleImportSpecification = $null
    if ($null -ne $ModuleSpecification) {
        $moduleImportSpecification = Get-NovaPropertyValue -InputObject $ModuleSpecification -Name 'FullyQualifiedName'
    }

    $null = $powershell.AddScript($command).AddArgument($Configuration).AddArgument($moduleImportSpecification)

    return [pscustomobject]@{
        PowerShell = $powershell
        AsyncResult = $powershell.BeginInvoke()
        CompletedTestCount = 0
        NextInformationRecordIndex = 0
        TotalTestCount = $null
        LastProgressStatus = $null
        LastProgressPercentComplete = $null
    }
}

function Wait-NovaPesterExecution {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][pscustomobject]$Execution,
        [Parameter(Mandatory)][int]$TimeoutMilliseconds
    )

    return $Execution.AsyncResult.AsyncWaitHandle.WaitOne($TimeoutMilliseconds)
}

function Receive-NovaPesterExecutionResult {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][pscustomobject]$Execution
    )

    $output = $Execution.PowerShell.EndInvoke($Execution.AsyncResult)
    return @($output | Select-Object -Last 1)[0]
}

function Complete-NovaPesterExecution {
    [CmdletBinding()]
    param(
        [AllowNull()][pscustomobject]$Execution
    )

    if ($null -eq $Execution) {
        return
    }

    $powershell = Get-NovaPropertyValue -InputObject $Execution -Name 'PowerShell'
    if ($null -eq $powershell) {
        return
    }

    $powershell.Dispose()
}

function Write-NovaTestWorkflowPesterProgress {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][pscustomobject]$Execution,
        [Parameter(Mandatory)][pscustomobject]$ProgressContext
    )

    $activity = Get-NovaPropertyValue -InputObject $ProgressContext -Name 'Activity'
    $startPercentComplete = Get-NovaPropertyValue -InputObject $ProgressContext -Name 'StartPercentComplete'
    $endPercentComplete = Get-NovaPropertyValue -InputObject $ProgressContext -Name 'EndPercentComplete'
    $totalTestCount = Get-NovaPropertyValue -InputObject $Execution -Name 'TotalTestCount'
    $completedTestCount = Get-NovaPropertyValue -InputObject $Execution -Name 'CompletedTestCount'
    $status = Get-NovaTestWorkflowPesterStatus -TotalTestCount $totalTestCount
    $percentComplete = Get-NovaTestWorkflowPesterPercentComplete -StartPercentComplete $startPercentComplete -EndPercentComplete $endPercentComplete -CompletedTestCount $completedTestCount -TotalTestCount $totalTestCount

    if (($Execution.LastProgressStatus -eq $status) -and ($Execution.LastProgressPercentComplete -eq $percentComplete)) {
        return
    }

    Write-Progress -Activity $activity -Status $status -PercentComplete $percentComplete
    $Execution.LastProgressStatus = $status
    $Execution.LastProgressPercentComplete = $percentComplete
}

function Get-NovaTestWorkflowPesterStatus {
    [CmdletBinding()]
    param(
        [AllowNull()][object]$TotalTestCount
    )

    if ($null -eq $TotalTestCount) {
        return 'Discovering Pester tests'
    }

    return 'Running Pester tests'
}

function Get-NovaTestWorkflowPesterPercentComplete {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][int]$StartPercentComplete,
        [Parameter(Mandatory)][int]$EndPercentComplete,
        [Parameter(Mandatory)][int]$CompletedTestCount,
        [AllowNull()][object]$TotalTestCount
    )

    if ($null -eq $TotalTestCount) {
        return $StartPercentComplete
    }

    if ($TotalTestCount -le 0) {
        return $EndPercentComplete
    }

    $progressRange = $EndPercentComplete - $StartPercentComplete
    $percentComplete = $StartPercentComplete + [int][math]::Floor(($CompletedTestCount / $TotalTestCount) * $progressRange)
    if ($percentComplete -gt $EndPercentComplete) {
        return $EndPercentComplete
    }

    if ($percentComplete -lt $StartPercentComplete) {
        return $StartPercentComplete
    }

    return $percentComplete
}

function Get-NovaTestWorkflowFailureMessage {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][pscustomobject]$WorkflowContext
    )

    $commandName = Get-NovaTestWorkflowCommandName -WorkflowContext $WorkflowContext
    return "Pester reported one or more failing tests. Review the output above and the test result file at $( $WorkflowContext.TestResultPath ), then rerun $commandName."
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

    foreach ($line in (Get-NovaTestWorkflowNextStepLine -WorkflowContext $WorkflowContext -WhatIfEnabled:$WhatIfEnabled)) {
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
        [Parameter(Mandatory)][pscustomobject]$WorkflowContext,
        [switch]$WhatIfEnabled
    )

    if ($WhatIfEnabled) {
        $commandName = Get-NovaTestWorkflowCommandName -WorkflowContext $WorkflowContext
        return @(
            'Next step:'
            "Run $commandName without -WhatIf when you are ready to execute the test workflow."
        )
    }

    return @(
        'Next step:'
        'Publish-NovaModule -Local'
    )
}

function Test-NovaTestWorkflowHasDiscoveredTest {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][pscustomobject]$WorkflowContext
    )

    if ($WorkflowContext.PSObject.Properties.Name -notcontains 'TestsDiscovered') {
        return $true
    }

    return [bool]$WorkflowContext.TestsDiscovered
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

    return Get-NovaDefaultCoverageTargetAssertionScriptBlock -CoveragePercentTarget $coveragePercentTarget -TargetObject $targetObject -CommandName (Get-NovaTestWorkflowCommandName -WorkflowContext $WorkflowContext)
}

function Get-NovaDefaultCoverageTargetAssertionScriptBlock {
    [CmdletBinding()]
    param(
        [AllowNull()][Nullable[double]]$CoveragePercentTarget,
        [Parameter(Mandatory)][string]$TargetObject,
        [Parameter(Mandatory)][string]$CommandName
    )

    $resolvedCoveragePercentTarget = $CoveragePercentTarget
    $resolvedTargetObject = $TargetObject
    $resolvedCommandName = $CommandName
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
        $exception = [System.InvalidOperationException]::new("Code coverage $formattedCoverage% did not meet the configured target $formattedTarget%. Review the failing tests or coverage settings, then rerun $resolvedCommandName.")
        $errorRecord = [System.Management.Automation.ErrorRecord]::new($exception, 'Nova.Workflow.CodeCoverageTargetNotMet', [System.Management.Automation.ErrorCategory]::InvalidOperation, $resolvedTargetObject)
        throw $errorRecord
    }.GetNewClosure()
}

function Get-NovaConfiguredCoveragePercentTarget {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][pscustomobject]$WorkflowContext
    )

    $pesterSettings = Get-NovaPropertyValue -InputObject $WorkflowContext -Name 'PesterSettings'
    if ($null -eq $pesterSettings) {
        $projectInfo = Get-NovaPropertyValue -InputObject $WorkflowContext -Name 'ProjectInfo'
        $pesterSettings = Get-NovaPropertyValue -InputObject $projectInfo -Name 'Pester'
    }
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

function Get-NovaTestWorkflowCommandName {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][pscustomobject]$WorkflowContext
    )

    $commandName = Get-NovaPropertyValue -InputObject $WorkflowContext -Name 'CommandName'
    if ([string]::IsNullOrWhiteSpace([string]$commandName)) {
        return 'Invoke-NovaTest'
    }

    return [string]$commandName
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
