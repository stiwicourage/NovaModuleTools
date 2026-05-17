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
function New-NovaInvokeNovaTestWorkflowContext {
    param(
        [hashtable]$PesterSettings = @{},
        [hashtable]$WorkflowParams = @{},
        [bool]$BuildRequested = $false,
        [string]$TestResultDirectory = '/tmp/nova-project/artifacts'
    )

    return [pscustomobject]@{
        BuildRequested = $BuildRequested
        WorkflowParams = $WorkflowParams
        ProjectInfo = [pscustomobject]@{Pester = $PesterSettings}
        TestResultDirectory = $TestResultDirectory
        TestResultPath = Join-Path $TestResultDirectory 'TestResults.xml'
        PesterConfig = [pscustomobject]@{TestResult = [pscustomobject]@{OutputPath = $null}}
        TestResultArtifactWriter = [pscustomobject]@{ScriptBlock = {}}
        TestResultReportWriter = [pscustomobject]@{ScriptBlock = {}}
    }
}
