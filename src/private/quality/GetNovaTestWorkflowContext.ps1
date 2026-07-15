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
    param(
        [AllowNull()][pscustomobject]$ProjectInfo
    )

    $moduleSpecification = Get-NovaSupportedPesterModuleSpecification -ProjectInfo $ProjectInfo
    Import-NovaSupportedPesterModule -ModuleSpecification $moduleSpecification
    return $moduleSpecification
}

function Get-NovaSupportedPesterModuleSpecification {
    [CmdletBinding()]
    param(
        [AllowNull()][pscustomobject]$ProjectInfo
    )

    $moduleRequirement = Get-NovaPesterModuleRequirement -ProjectInfo $ProjectInfo
    $availableModule = @(Get-LoadedNovaPesterModule -ModuleRequirement $moduleRequirement)
    if ($availableModule.Count -eq 0) {
        $availableModule = @(Get-AvailableNovaPesterModule -ModuleRequirement $moduleRequirement)
    }

    if ($availableModule.Count -eq 0) {
        Stop-NovaOperation -Message (Get-NovaPesterDependencyMessage -ModuleRequirement $moduleRequirement) -ErrorId 'Nova.Dependency.PesterDependencyMissing' -Category ResourceUnavailable -TargetObject 'Pester'
    }

    $selectedVersion = [version]$availableModule[0].Version
    return [pscustomobject]@{
        Name = 'Pester'
        MinimumVersion = $moduleRequirement.MinimumVersion
        MaximumVersion = $moduleRequirement.MaximumVersion
        SelectedVersion = $selectedVersion
        FullyQualifiedName = @{
            ModuleName = 'Pester'
            RequiredVersion = [string]$selectedVersion
        }
    }
}

function Get-NovaSupportedPesterRange {
    [CmdletBinding()]
    param()

    return [pscustomobject]@{
        Name = 'Pester'
        MinimumVersion = [version]'5.7.1'
        MaximumVersion = [version]'5.10.0'
    }
}

function Get-NovaPesterModuleRequirement {
    [CmdletBinding()]
    param(
        [AllowNull()][pscustomobject]$ProjectInfo
    )

    $supportedRequirement = Get-NovaSupportedPesterRange
    $manifestSettings = Get-NovaPesterSettingValue -InputObject $ProjectInfo -Name 'Manifest'
    $requiredModules = @(Get-NovaPesterSettingValue -InputObject $manifestSettings -Name 'RequiredModules')
    $pesterModule = $requiredModules |
            Where-Object {(Get-NovaPesterSettingValue -InputObject $_ -Name 'ModuleName') -eq 'Pester'} |
            Select-Object -First 1

    if ($null -ne $pesterModule) {
        $manifestRequirement = [pscustomobject]@{
            Name = 'Pester'
            MinimumVersion = [version](Get-NovaPesterVersionText -InputObject $pesterModule -Name 'ModuleVersion' -DefaultValue '5.7.1')
            MaximumVersion = [version](Get-NovaPesterVersionText -InputObject $pesterModule -Name 'MaximumVersion' -DefaultValue '5.10.0')
        }
        Assert-NovaPesterModuleRequirementSupported -ModuleRequirement $manifestRequirement -SupportedRequirement $supportedRequirement
    }

    return $supportedRequirement
}

function Assert-NovaPesterModuleRequirementSupported {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][pscustomobject]$ModuleRequirement,
        [Parameter(Mandatory)][pscustomobject]$SupportedRequirement
    )

    if ($ModuleRequirement.MinimumVersion -eq $SupportedRequirement.MinimumVersion -and $ModuleRequirement.MaximumVersion -eq $SupportedRequirement.MaximumVersion) {
        return
    }

    $supportedVersionText = Get-NovaPesterVersionRangeText -ModuleRequirement $SupportedRequirement
    $declaredVersionText = Get-NovaPesterVersionRangeText -ModuleRequirement $ModuleRequirement
    Stop-NovaOperation -Message "Nova tests support Pester only from $supportedVersionText. project.json declares Pester from $declaredVersionText. Update project.json to match Nova's supported range and try again." -ErrorId 'Nova.Dependency.UnsupportedPesterVersionRequirement' -Category InvalidData -TargetObject 'project.json'
}

function Get-NovaPesterVersionText {
    [CmdletBinding()]
    param(
        [AllowNull()][object]$InputObject,
        [Parameter(Mandatory)][string]$Name,
        [Parameter(Mandatory)][string]$DefaultValue
    )

    $value = [string](Get-NovaPesterSettingValue -InputObject $InputObject -Name $Name)
    if ( [string]::IsNullOrWhiteSpace($value)) {
        return $DefaultValue
    }

    return $value
}

function Get-NovaPesterVersionRangeText {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][pscustomobject]$ModuleRequirement
    )

    return "$( $ModuleRequirement.MinimumVersion ) through $( $ModuleRequirement.MaximumVersion )"
}

function Get-AvailableNovaPesterModule {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][pscustomobject]$ModuleRequirement
    )

    return @(
    Get-Module -Name Pester -ListAvailable |
            Where-Object {Test-NovaPesterModuleVersionSupported -Version $_.Version -ModuleRequirement $ModuleRequirement} |
            Sort-Object Version -Descending
    )
}

function Get-LoadedNovaPesterModule {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][pscustomobject]$ModuleRequirement
    )

    return @(
    Get-Module -Name Pester |
            Where-Object {Test-NovaPesterModuleVersionSupported -Version $_.Version -ModuleRequirement $ModuleRequirement} |
            Sort-Object Version -Descending
    )
}

function Test-NovaPesterModuleVersionSupported {
    [CmdletBinding()]
    param(
        [AllowNull()][object]$Version,
        [Parameter(Mandatory)][pscustomobject]$ModuleRequirement
    )

    if ($null -eq $Version) {
        return $false
    }

    $resolvedVersion = [version]$Version
    return $resolvedVersion -ge $ModuleRequirement.MinimumVersion -and $resolvedVersion -le $ModuleRequirement.MaximumVersion
}

function Get-NovaPesterDependencyMessage {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][pscustomobject]$ModuleRequirement
    )

    $supportedVersionText = Get-NovaPesterVersionRangeText -ModuleRequirement $ModuleRequirement
    $installedVersion = @(
    Get-Module -Name Pester -ListAvailable |
            Sort-Object Version -Descending |
            ForEach-Object {[string]$_.Version} |
            Select-Object -Unique
    )
    if ($installedVersion.Count -eq 0) {
        return "The module Pester must be installed to run Nova tests. Install a supported Pester version from $supportedVersionText and try again."
    }

    return "Nova tests require Pester from $supportedVersionText. Installed versions: $( $installedVersion -join ', ' ). Install a supported Pester 5.x version and try again."
}

function Import-NovaSupportedPesterModule {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][pscustomobject]$ModuleSpecification
    )

    Import-Module -FullyQualifiedName $ModuleSpecification.FullyQualifiedName -Force -ErrorAction Stop | Out-Null
}

function Get-NovaTestWorkflowContext {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][hashtable]$TestOption,
        [Parameter(Mandatory)][hashtable]$BoundParameters
    )

    $projectInfo = Get-NovaProjectInfo
    Test-ProjectSchema | Out-Null
    $pesterModuleSpecification = Assert-NovaPesterAvailable -ProjectInfo $projectInfo
    $workflowProfile = Get-NovaTestWorkflowProfile -TestOption $TestOption
    $pesterConfig = New-PesterConfiguration -Hashtable $projectInfo.Pester
    Add-Member -InputObject $pesterConfig -MemberType NoteProperty -Name PesterModuleSpecification -Value $pesterModuleSpecification -Force
    $coverageConfiguration = Get-NovaPesterCoverageConfigurationState -ProjectInfo $projectInfo -CoverageEnabled:$workflowProfile.CoverageEnabled
    $pesterConfig.CodeCoverage.Enabled = $coverageConfiguration.Enabled
    $pesterConfig.CodeCoverage.Path = $coverageConfiguration.Path
    if ($null -ne $coverageConfiguration.CoveragePercentTarget) {
        $pesterConfig.CodeCoverage.CoveragePercentTarget = $coverageConfiguration.CoveragePercentTarget
    }

    $runPath = @(
        Get-NovaPesterRunPath -ProjectInfo $projectInfo -IncludePattern $workflowProfile.IncludePattern -ExcludePattern $workflowProfile.ExcludePattern
    )
    $testDiscoveryState = Get-NovaDiscoveredTestPathState -RunPath $runPath -ProjectInfo $projectInfo -WorkflowProfile $workflowProfile
    $pesterConfig.Run.Path = $runPath
    $pesterConfig.Run.PassThru = $true
    $pesterConfig.Run.Exit = $true
    $pesterConfig.Run.Throw = $true
    $pesterConfig.Filter.Tag = Get-NovaTestOptionValue -TestOption $TestOption -Name TagFilter
    $pesterConfig.Filter.ExcludeTag = Get-NovaTestOptionValue -TestOption $TestOption -Name ExcludeTagFilter
    Initialize-NovaPesterExecutionConfiguration -PesterConfig $pesterConfig -BoundParameters $BoundParameters -ExecutionOption @{
        PesterConfigurationOverride = Get-NovaTestOptionValue -TestOption $TestOption -Name PesterConfigurationOverride
        ProjectRoot = $projectInfo.ProjectRoot
        OutputVerbosity = Get-NovaTestOptionValue -TestOption $TestOption -Name OutputVerbosity
        OutputRenderMode = Get-NovaTestOptionValue -TestOption $TestOption -Name OutputRenderMode
    }
    $testResultPath = Get-NovaPesterTestResultPath -ProjectRoot $projectInfo.ProjectRoot -FileName $workflowProfile.TestResultFileName

    return [pscustomobject]@{
        BuildRequested = $workflowProfile.BuildRequested
        CommandName = $workflowProfile.CommandName
        OverrideWarningRequested = $BoundParameters.ContainsKey('OverrideWarning') -and [bool]$BoundParameters.OverrideWarning
        ProjectInfo = $projectInfo
        PesterModuleSpecification = $pesterModuleSpecification
        PesterSettings = Get-NovaTestWorkflowPesterConfiguration -ProjectPesterSettings $projectInfo.Pester -CoverageEnabled:$workflowProfile.CoverageEnabled
        PesterConfig = $pesterConfig
        TestResultPath = $testResultPath
        TestResultDirectory = Split-Path -Parent $testResultPath
        TestResultArtifactWriter = Get-Command -Name Write-NovaPesterTestResultArtifact -CommandType Function -ErrorAction Stop
        TestResultReportWriter = Get-Command -Name Write-NovaPesterTestResultReport -CommandType Function -ErrorAction Stop
        TestsDiscovered = $testDiscoveryState.HasDiscoveredTests
        TestDiscoveryMessageLines = $testDiscoveryState.MessageLines
        WorkflowParams = Get-NovaShouldProcessForwardingParameter -WhatIfEnabled:($BoundParameters.ContainsKey('WhatIf') -and [bool]$BoundParameters.WhatIf)
        Target = $testResultPath
        Operation = Get-NovaTestWorkflowOperation -TestMode $workflowProfile.Mode
    }
}

function Get-NovaDiscoveredTestPathState {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][AllowEmptyCollection()][string[]]$RunPath,
        [Parameter(Mandatory)][pscustomobject]$ProjectInfo,
        [Parameter(Mandatory)][pscustomobject]$WorkflowProfile
    )

    if ($WorkflowProfile.Mode -ne 'BuildValidation' -or $RunPath.Count -gt 0) {
        return [pscustomobject]@{
            HasDiscoveredTests = $true
            MessageLines = @()
        }
    }

    return [pscustomobject]@{
        HasDiscoveredTests = $false
        MessageLines = @(Get-NovaMissingBuildValidationTestMessageLine -ProjectInfo $ProjectInfo -WorkflowProfile $WorkflowProfile)
    }
}

function Get-NovaMissingBuildValidationTestMessageLine {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][pscustomobject]$ProjectInfo,
        [Parameter(Mandatory)][pscustomobject]$WorkflowProfile
    )

    $expectedPath = Join-Path $ProjectInfo.TestsDir 'public/Get-CommandName.Integration.Tests.ps1'

    return @(
        "No build-validation integration tests matching '$($WorkflowProfile.IncludePattern)' were discovered for $( $ProjectInfo.ProjectName )."
        "Test-NovaBuild expects build-validation tests under the tests folder, for example $expectedPath."
        'Add at least one *.Integration.Tests.ps1 file, then rerun Test-NovaBuild.'
        'Use Invoke-NovaTest for unit tests and Test-NovaBuild for build-validation integration tests.'
    )
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

function Get-NovaPesterCoverageConfigurationState {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][pscustomobject]$ProjectInfo,
        [Parameter(Mandatory)][bool]$CoverageEnabled
    )

    if (-not $CoverageEnabled) {
        return Get-NovaDisabledPesterCoverageConfiguration
    }

    $codeCoverageSettings = Get-NovaPesterSettingValue -InputObject $ProjectInfo.Pester -Name 'CodeCoverage'
    if ($true -ne [bool](Get-NovaPesterSettingValue -InputObject $codeCoverageSettings -Name 'Enabled')) {
        return Get-NovaDisabledPesterCoverageConfiguration
    }

    $coveragePercentTarget = Get-NovaConfiguredPesterCoveragePercentTarget -ProjectPesterSettings $ProjectInfo.Pester
    $resolvedCoveragePath = @(Get-NovaResolvedPesterCoveragePath -ProjectInfo $ProjectInfo)

    return [pscustomobject]@{
        Enabled = $true
        CoveragePercentTarget = $coveragePercentTarget
        Path = $resolvedCoveragePath
    }
}

function Get-NovaDisabledPesterCoverageConfiguration {
    [CmdletBinding()]
    param()

    return [pscustomobject]@{
        Enabled = $false
        CoveragePercentTarget = $null
        Path = @()
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
