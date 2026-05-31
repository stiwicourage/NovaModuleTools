function Stop-NovaOperation {
    param($Message, $ErrorId, $Category, $TargetObject)
    $exception = switch ($Category) {
        ([System.Management.Automation.ErrorCategory]::InvalidData) {[System.IO.InvalidDataException]::new($Message)}
        default {[System.InvalidOperationException]::new($Message)}
    }
    $errorRecord = [System.Management.Automation.ErrorRecord]::new($exception, $ErrorId, $Category, $TargetObject)
    throw $errorRecord
}
function Invoke-NovaBuild {}
function Invoke-NovaPester {param($Configuration)}
function Get-NovaBuildCommandParameterMap {param($WorkflowParams, [switch]$OverrideWarningRequested) return @{}}
function Write-Message {param([string]$Text, [string]$color)}
function Write-Progress {param([string]$Activity, [string]$Status, [int]$PercentComplete, [switch]$Completed)}
function New-NovaInvokeNovaTestWorkflowContext {
    param(
        [hashtable]$Option = @{}
    )

    $pesterSettings = if ($Option.ContainsKey('PesterSettings')) {$Option.PesterSettings} else {@{}}
    $workflowParams = if ($Option.ContainsKey('WorkflowParams')) {$Option.WorkflowParams} else {@{}}
    $buildRequested = if ($Option.ContainsKey('BuildRequested')) {[bool]$Option.BuildRequested} else {$false}
    $testResultDirectory = if ($Option.ContainsKey('TestResultDirectory')) {[string]$Option.TestResultDirectory} else {'/tmp/nova-project/artifacts'}
    $commandName = if ($Option.ContainsKey('CommandName')) {[string]$Option.CommandName} else {'Invoke-NovaTest'}
    $testResultFileName = if ($Option.ContainsKey('TestResultFileName')) {[string]$Option.TestResultFileName} else {'UnitTestResults.xml'}

    return [pscustomobject]@{
        BuildRequested = $buildRequested
        CommandName = $commandName
        WorkflowParams = $workflowParams
        ProjectInfo = [pscustomobject]@{ProjectName = 'NovaModuleTools'; Pester = $pesterSettings}
        PesterSettings = $pesterSettings
        TestResultDirectory = $testResultDirectory
        TestResultPath = Join-Path $testResultDirectory $testResultFileName
        PesterConfig = [pscustomobject]@{TestResult = [pscustomobject]@{OutputPath = $null}}
        TestResultArtifactWriter = [pscustomobject]@{ScriptBlock = {}}
        TestResultReportWriter = [pscustomobject]@{ScriptBlock = {}}
    }
}
