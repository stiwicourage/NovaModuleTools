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

function Assert-NovaPesterAvailable {
    [CmdletBinding()]
    param()

    if (-not (Get-Module -Name Pester -ListAvailable)) {
        Stop-NovaOperation -Message 'The module Pester must be installed for Test-NovaBuild to run. Install Pester 5.7.1 and try again.' -ErrorId 'Nova.Dependency.PesterDependencyMissing' -Category ResourceUnavailable -TargetObject 'Pester'
    }
}

function Get-NovaTestWorkflowContext {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][hashtable]$TestOption,
        [Parameter(Mandatory)][hashtable]$BoundParameters
    )

    Test-ProjectSchema Pester | Out-Null
    Assert-NovaPesterAvailable
    $projectInfo = Get-NovaProjectInfo
    $pesterConfig = New-PesterConfiguration -Hashtable $projectInfo.Pester
    Initialize-NovaPesterCoverageConfiguration -PesterConfig $pesterConfig -ProjectInfo $projectInfo

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
        OverrideWarningRequested = $BoundParameters.ContainsKey('OverrideWarning') -and [bool]$BoundParameters.OverrideWarning
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

function Get-NovaConfiguredPesterCoveragePercentTarget {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][object]$ProjectPesterSettings
    )

    $codeCoverageSettings = Get-NovaPesterSettingValue -InputObject $ProjectPesterSettings -Name 'CodeCoverage'
    if ($true -ne [bool](Get-NovaPesterSettingValue -InputObject $codeCoverageSettings -Name 'Enabled')) {
        return $null
    }

    $coveragePercentTarget = Get-NovaPesterSettingValue -InputObject $codeCoverageSettings -Name 'CoveragePercentTarget'
    if ($null -eq $coveragePercentTarget -or [string]::IsNullOrWhiteSpace([string]$coveragePercentTarget)) {
        return $null
    }

    return [double]$coveragePercentTarget
}

function Initialize-NovaPesterCoverageConfiguration {
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseShouldProcessForStateChangingFunctions', '', Justification = 'Mutates PesterConfiguration state, not user-facing resources. ShouldProcess is not appropriate here.')]
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][object]$PesterConfig,
        [Parameter(Mandatory)][pscustomobject]$ProjectInfo
    )

    $codeCoverageSettings = Get-NovaPesterSettingValue -InputObject $ProjectInfo.Pester -Name 'CodeCoverage'
    if ($true -ne [bool](Get-NovaPesterSettingValue -InputObject $codeCoverageSettings -Name 'Enabled')) {
        return
    }

    $coveragePercentTarget = Get-NovaConfiguredPesterCoveragePercentTarget -ProjectPesterSettings $ProjectInfo.Pester
    if ($null -ne $coveragePercentTarget) {
        $PesterConfig.CodeCoverage.CoveragePercentTarget = $coveragePercentTarget
    }
}

function Get-NovaPesterSettingValue {
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
