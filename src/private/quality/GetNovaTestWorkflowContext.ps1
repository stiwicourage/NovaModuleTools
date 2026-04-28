function Get-NovaTestWorkflowOperation {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][bool]$BuildRequested
    )

    if ($BuildRequested) {
        return 'Build project, run Pester tests, and write test results'
    }

    return 'Run Pester tests and write test results'
}

function Get-NovaTestWorkflowContext {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][hashtable]$TestOption,
        [Parameter(Mandatory)][hashtable]$BoundParameters
    )

    Test-ProjectSchema Pester | Out-Null
    $projectInfo = Get-NovaProjectInfo
    $pesterConfig = New-PesterConfiguration -Hashtable $projectInfo.Pester

    $pesterConfig.Run.Path = Get-NovaPesterRunPath -ProjectInfo $projectInfo
    $pesterConfig.Run.PassThru = $true
    $pesterConfig.Run.Exit = $true
    $pesterConfig.Run.Throw = $true
    $pesterConfig.Filter.Tag = Get-NovaTestOptionValue -TestOption $TestOption -Name TagFilter
    $pesterConfig.Filter.ExcludeTag = Get-NovaTestOptionValue -TestOption $TestOption -Name ExcludeTagFilter
    Initialize-NovaPesterExecutionConfiguration -PesterConfig $pesterConfig -BoundParameters $BoundParameters -OutputVerbosity (Get-NovaTestOptionValue -TestOption $TestOption -Name OutputVerbosity) -OutputRenderMode (Get-NovaTestOptionValue -TestOption $TestOption -Name OutputRenderMode)

    $testResultPath = Get-NovaPesterTestResultPath -ProjectRoot $projectInfo.ProjectRoot
    $buildRequested = [bool](Get-NovaTestOptionValue -TestOption $TestOption -Name Build)

    return [pscustomobject]@{
        BuildRequested = $buildRequested
        ProjectInfo = $projectInfo
        PesterConfig = $pesterConfig
        TestResultPath = $testResultPath
        TestResultDirectory = Split-Path -Parent $testResultPath
        TestResultArtifactWriter = Get-Command -Name Write-NovaPesterTestResultArtifact -CommandType Function -ErrorAction Stop
        TestResultReportWriter = Get-Command -Name Write-NovaPesterTestResultReport -CommandType Function -ErrorAction Stop
        WorkflowParams = Get-NovaShouldProcessForwardingParameter -WhatIfEnabled:($BoundParameters.ContainsKey('WhatIf') -and [bool]$BoundParameters.WhatIf)
        Target = $testResultPath
        Operation = Get-NovaTestWorkflowOperation -BuildRequested:$buildRequested
    }
}

function Get-NovaTestOptionValue {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][hashtable]$TestOption,
        [Parameter(Mandatory)][string]$Name
    )

    if ( $TestOption.ContainsKey($Name)) {
        return $TestOption[$Name]
    }

    return $null
}
