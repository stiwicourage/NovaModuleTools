function Get-NovaTestWorkflowOperation {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][string]$TestMode
    )

    if ($TestMode -eq 'BuildValidation') {
        return 'Build project, run build-validation integration tests, and write test results'
    }

    return 'Run unit tests and write test results'
}

function Assert-NovaPesterAvailable {
    [CmdletBinding()]
    param()

    if (-not (Get-Module -Name Pester -ListAvailable)) {
        Stop-NovaOperation -Message 'The module Pester must be installed to run Nova tests. Install Pester 5.7.1 and try again.' -ErrorId 'Nova.Dependency.PesterDependencyMissing' -Category ResourceUnavailable -TargetObject 'Pester'
    }
}

function Get-NovaTestWorkflowContext {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][hashtable]$TestOption,
        [Parameter(Mandatory)][hashtable]$BoundParameters
    )

    Test-ProjectSchema | Out-Null
    Assert-NovaPesterAvailable
    $projectInfo = Get-NovaProjectInfo
    $workflowProfile = Get-NovaTestWorkflowProfile -TestOption $TestOption
    $pesterConfig = New-PesterConfiguration -Hashtable $projectInfo.Pester
    if ($workflowProfile.CoverageEnabled) {
        Initialize-NovaPesterCoverageConfiguration -PesterConfig $pesterConfig -ProjectInfo $projectInfo
    } else {
        Disable-NovaPesterCoverageConfiguration -PesterConfig $pesterConfig
    }

    $pesterConfig.Run.Path = @(
        Get-NovaPesterRunPath -ProjectInfo $projectInfo -IncludePattern $workflowProfile.IncludePattern -ExcludePattern $workflowProfile.ExcludePattern
    )
    $pesterConfig.Run.PassThru = $true
    $pesterConfig.Run.Exit = $true
    $pesterConfig.Run.Throw = $true
    $pesterConfig.Filter.Tag = Get-NovaTestOptionValue -TestOption $TestOption -Name TagFilter
    $pesterConfig.Filter.ExcludeTag = Get-NovaTestOptionValue -TestOption $TestOption -Name ExcludeTagFilter
    Initialize-NovaPesterExecutionConfiguration -PesterConfig $pesterConfig -BoundParameters $BoundParameters -OutputVerbosity (Get-NovaTestOptionValue -TestOption $TestOption -Name OutputVerbosity) -OutputRenderMode (Get-NovaTestOptionValue -TestOption $TestOption -Name OutputRenderMode)

    $testResultPath = Get-NovaPesterTestResultPath -ProjectRoot $projectInfo.ProjectRoot -FileName $workflowProfile.TestResultFileName

    return [pscustomobject]@{
        BuildRequested = $workflowProfile.BuildRequested
        CommandName = $workflowProfile.CommandName
        OverrideWarningRequested = $BoundParameters.ContainsKey('OverrideWarning') -and [bool]$BoundParameters.OverrideWarning
        ProjectInfo = $projectInfo
        PesterSettings = Get-NovaTestWorkflowPesterConfiguration -ProjectPesterSettings $projectInfo.Pester -CoverageEnabled:$workflowProfile.CoverageEnabled
        PesterConfig = $pesterConfig
        TestResultPath = $testResultPath
        TestResultDirectory = Split-Path -Parent $testResultPath
        TestResultArtifactWriter = Get-Command -Name Write-NovaPesterTestResultArtifact -CommandType Function -ErrorAction Stop
        TestResultReportWriter = Get-Command -Name Write-NovaPesterTestResultReport -CommandType Function -ErrorAction Stop
        WorkflowParams = Get-NovaShouldProcessForwardingParameter -WhatIfEnabled:($BoundParameters.ContainsKey('WhatIf') -and [bool]$BoundParameters.WhatIf)
        Target = $testResultPath
        Operation = Get-NovaTestWorkflowOperation -TestMode $workflowProfile.Mode
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

function Get-NovaTestWorkflowProfile {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][hashtable]$TestOption
    )

    $testMode = Get-NovaTestWorkflowMode -TestOption $TestOption
    if ($testMode -eq 'BuildValidation') {
        return [pscustomobject]@{
            Mode = $testMode
            BuildRequested = $true
            CommandName = 'Test-NovaBuild'
            CoverageEnabled = $false
            IncludePattern = '*.Integration.Tests.ps1'
            ExcludePattern = @()
            TestResultFileName = 'TestResults.xml'
        }
    }

    return [pscustomobject]@{
        Mode = $testMode
        BuildRequested = $false
        CommandName = 'Invoke-NovaTest'
        CoverageEnabled = $true
        IncludePattern = '*.Tests.ps1'
        ExcludePattern = @('*.Integration.Tests.ps1')
        TestResultFileName = 'UnitTestResults.xml'
    }
}

function Get-NovaTestWorkflowMode {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][hashtable]$TestOption
    )

    $requestedMode = Get-NovaTestOptionValue -TestOption $TestOption -Name TestMode
    if ([string]::IsNullOrWhiteSpace([string]$requestedMode)) {
        return 'Unit'
    }

    return [string]$requestedMode
}

function Get-NovaTestWorkflowPesterConfiguration {
    [CmdletBinding()]
    param(
        [AllowNull()][object]$ProjectPesterSettings,
        [Parameter(Mandatory)][bool]$CoverageEnabled
    )

    if ($CoverageEnabled) {
        return $ProjectPesterSettings
    }

    return [pscustomobject]@{
        CodeCoverage = [pscustomobject]@{
            Enabled = $false
        }
    }
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

function Get-NovaConfiguredPesterCoveragePath {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][object]$ProjectPesterSettings
    )

    $codeCoverageSettings = Get-NovaPesterSettingValue -InputObject $ProjectPesterSettings -Name 'CodeCoverage'
    if ($true -ne [bool](Get-NovaPesterSettingValue -InputObject $codeCoverageSettings -Name 'Enabled')) {
        return @()
    }

    return @(
        Get-NovaPesterSettingValue -InputObject $codeCoverageSettings -Name 'Path' |
            Where-Object {-not [string]::IsNullOrWhiteSpace([string]$_)}
    )
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

    $resolvedCoveragePath = @(Get-NovaResolvedPesterCoveragePath -ProjectInfo $ProjectInfo)
    if ($resolvedCoveragePath.Count -gt 0) {
        $PesterConfig.CodeCoverage.Path = $resolvedCoveragePath
    }
}

function Disable-NovaPesterCoverageConfiguration {
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseShouldProcessForStateChangingFunctions', '', Justification = 'Mutates PesterConfiguration state, not user-facing resources. ShouldProcess is not appropriate here.')]
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][object]$PesterConfig
    )

    if ($PesterConfig.PSObject.Properties.Name -contains 'CodeCoverage') {
        if ($PesterConfig.CodeCoverage.PSObject.Properties.Name -contains 'Enabled') {
            $PesterConfig.CodeCoverage.Enabled = $false
        }

        if ($PesterConfig.CodeCoverage.PSObject.Properties.Name -contains 'Path') {
            $PesterConfig.CodeCoverage.Path = @()
        }
    }
}

function Get-NovaResolvedPesterCoveragePath {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][pscustomobject]$ProjectInfo
    )

    $coveragePath = @(Get-NovaConfiguredPesterCoveragePath -ProjectPesterSettings $ProjectInfo.Pester)
    if ($coveragePath.Count -eq 0) {
        return @()
    }

    $coverageFile = @(Get-NovaPesterCoverageFile -ProjectRoot $ProjectInfo.ProjectRoot)
    $resolvedPath = New-Object 'System.Collections.Generic.List[string]'
    foreach ($pattern in $coveragePath) {
        Add-NovaResolvedCoveragePath -ResolvedPath $resolvedPath -CoverageFile $coverageFile -Pattern $pattern
    }

    return @($resolvedPath)
}

function Get-NovaPesterCoverageFile {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][string]$ProjectRoot
    )

    $resolvedProjectRoot = (Resolve-Path -LiteralPath $ProjectRoot -ErrorAction Stop).Path
    foreach ($file in (Get-ChildItem -LiteralPath $resolvedProjectRoot -Recurse -File | Sort-Object FullName)) {
        [pscustomobject]@{
            FullPath = ConvertTo-NovaCoveragePathString -Path $file.FullName
            RelativePath = ConvertTo-NovaCoveragePathString -Path ([System.IO.Path]::GetRelativePath($resolvedProjectRoot, $file.FullName))
        }
    }
}

function Add-NovaResolvedCoveragePath {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][AllowEmptyCollection()][System.Collections.Generic.List[string]]$ResolvedPath,
        [Parameter(Mandatory)][object[]]$CoverageFile,
        [Parameter(Mandatory)][string]$Pattern
    )

    $patternVariant = @(Get-NovaCoveragePathPatternVariant -Pattern $Pattern)

    foreach ($file in $CoverageFile) {
        if ((Test-NovaCoveragePathMatch -CoverageFile $file -Pattern $patternVariant) -and -not $ResolvedPath.Contains($file.RelativePath)) {
            $ResolvedPath.Add($file.RelativePath)
        }
    }
}

function Test-NovaCoveragePathMatch {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][pscustomobject]$CoverageFile,
        [Parameter(Mandatory)][string[]]$Pattern
    )

    foreach ($item in $Pattern) {
        $wildcardPattern = [System.Management.Automation.WildcardPattern]::new($item, [System.Management.Automation.WildcardOptions]::IgnoreCase)
        if ($wildcardPattern.IsMatch($CoverageFile.RelativePath) -or $wildcardPattern.IsMatch($CoverageFile.FullPath)) {
            return $true
        }
    }

    return $false
}

function Get-NovaCoveragePathPatternVariant {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][string]$Pattern
    )

    $patternVariant = New-Object 'System.Collections.Generic.List[string]'
    $normalizedPattern = ConvertTo-NovaCoveragePathString -Path $Pattern
    $patternVariant.Add($normalizedPattern)

    $collapsedPattern = $normalizedPattern
    while ($collapsedPattern.Contains('/**/')) {
        $collapsedPattern = $collapsedPattern.Replace('/**/', '/')
        if (-not $patternVariant.Contains($collapsedPattern)) {
            $patternVariant.Add($collapsedPattern)
        }
    }

    return @($patternVariant)
}

function ConvertTo-NovaCoveragePathString {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][string]$Path
    )

    return $Path -replace '\\', '/'
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
