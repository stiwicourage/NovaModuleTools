function Get-NovaVersionUpdateWorkflowContext {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][string]$ProjectRoot,
        [switch]$PreviewRelease,
        [switch]$ContinuousIntegrationRequested,
        [switch]$OverrideWarningRequested
    )

    $projectInfo = Get-NovaProjectInfo -Path $ProjectRoot
    $commitMessages = @(Get-GitCommitMessageForVersionBump -ProjectRoot $ProjectRoot)
    Assert-NovaVersionBumpInferenceAvailability -ProjectRoot $ProjectRoot -CommitMessages $commitMessages -OverrideWarningRequested:$OverrideWarningRequested
    $label = Get-NovaVersionLabelForBump -ProjectRoot $ProjectRoot -CommitMessages $commitMessages -ContinuousIntegrationRequested:$ContinuousIntegrationRequested
    $labelResolution = Get-NovaVersionUpdateLabelResolution -ProjectInfo $projectInfo -Label $label -PreviewRelease:$PreviewRelease
    $versionUpdatePlan = Get-NovaVersionUpdatePlan -ProjectInfo $projectInfo -Label $labelResolution.EffectiveLabel -PreviewRelease:$PreviewRelease

    return Get-NovaVersionUpdateWorkflowContextObject -ProjectRoot $ProjectRoot -ProjectInfo $projectInfo -CommitMessages $commitMessages -Label $label -EffectiveLabel $labelResolution.EffectiveLabel -AdvisoryMessage $labelResolution.AdvisoryMessage -VersionUpdatePlan $versionUpdatePlan -PreviewRelease:$PreviewRelease -ContinuousIntegrationRequested:$ContinuousIntegrationRequested
}

function Assert-NovaVersionBumpInferenceAvailability {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][string]$ProjectRoot,
        [AllowEmptyCollection()][string[]]$CommitMessages = @(),
        [switch]$OverrideWarningRequested
    )

    if ($CommitMessages.Count -gt 0) {
        return
    }

    if (Test-GitRepositoryIsAvailable -ProjectRoot $ProjectRoot) {
        return
    }

    $message = Get-NovaVersionBumpInferenceUnavailableMessage
    Write-Warning $message

    if ($OverrideWarningRequested) {
        Write-Verbose 'Continuing version bump because OverrideWarning was specified and Git-based bump inference is unavailable.'
        return
    }

    Stop-NovaOperation -Message $message -ErrorId 'Nova.Workflow.VersionBumpInferenceUnavailable' -Category InvalidOperation -TargetObject $ProjectRoot
}

function Get-NovaVersionBumpInferenceUnavailableMessage {
    [CmdletBinding()]
    param()

    return 'Cannot infer the version bump label from Git history because no Git repository was found for this project path. Use -OverrideWarning / --override-warning / -o to continue intentionally with a Patch fallback, for example in example or template flows.'
}

function Get-NovaVersionUpdateLabelResolution {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][pscustomobject]$ProjectInfo,
        [Parameter(Mandatory)][string]$Label,
        [switch]$PreviewRelease
    )

    $effectiveLabel = $Label
    $advisoryMessage = $null
    $currentVersion = Get-NovaCurrentVersionForUpdatePlan -ProjectInfo $ProjectInfo
    if (Test-NovaVersionUpdateUsesPreviewPatchFallback -CurrentVersion $currentVersion -PreviewRelease:$PreviewRelease) {
        $effectiveLabel = 'Patch'
    }

    if (Test-NovaVersionUpdateUsesInitialDevelopmentAdvisory -CurrentVersion $currentVersion -PreviewRelease:$PreviewRelease) {
        $advisoryMessage = Get-NovaInitialDevelopmentVersioningMessage
    }

    if (Test-NovaVersionUpdateUsesMajorZeroFallback -CurrentVersion $currentVersion -Label $Label -PreviewRelease:$PreviewRelease) {
        $effectiveLabel = 'Minor'
    }

    return [pscustomobject]@{
        EffectiveLabel = $effectiveLabel
        AdvisoryMessage = $advisoryMessage
    }
}

function Test-NovaVersionUpdateUsesPreviewPatchFallback {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][semver]$CurrentVersion,
        [switch]$PreviewRelease
    )

    if (-not $PreviewRelease) {
        return $false
    }

    return [string]::IsNullOrWhiteSpace($CurrentVersion.PreReleaseLabel)
}

function Test-NovaVersionUpdateUsesInitialDevelopmentAdvisory {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][semver]$CurrentVersion,
        [switch]$PreviewRelease
    )

    if ($PreviewRelease) {
        return $false
    }

    return $CurrentVersion.Major -eq 0
}

function Test-NovaVersionUpdateUsesMajorZeroFallback {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][semver]$CurrentVersion,
        [Parameter(Mandatory)][string]$Label,
        [switch]$PreviewRelease
    )

    if ($PreviewRelease) {
        return $false
    }

    if ($Label -ne 'Major') {
        return $false
    }

    return $CurrentVersion.Major -eq 0
}

function Get-NovaInitialDevelopmentVersioningMessage {
    [CmdletBinding()]
    param()

    return 'Major version zero (0.y.z) is for initial development, so Nova keeps stable bumps on the 0.y.z line and plans breaking-change bumps as the next minor version instead of 1.0.0. Set 1.0.0 manually once the software is stable; after that, automatic major-version bumps work normally.'
}

function Get-NovaVersionUpdateWorkflowContextObject {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][string]$ProjectRoot,
        [Parameter(Mandatory)][pscustomobject]$ProjectInfo,
        [AllowEmptyCollection()][string[]]$CommitMessages = @(),
        [Parameter(Mandatory)][string]$Label,
        [Parameter(Mandatory)][string]$EffectiveLabel,
        [AllowEmptyString()][string]$AdvisoryMessage,
        [Parameter(Mandatory)][pscustomobject]$VersionUpdatePlan,
        [switch]$PreviewRelease,
        [switch]$ContinuousIntegrationRequested
    )

    return [pscustomobject]@{
        ProjectRoot = $ProjectRoot
        ProjectInfo = $ProjectInfo
        CommitMessages = $CommitMessages
        CommitCount = $CommitMessages.Count
        Label = $Label
        EffectiveLabel = $EffectiveLabel
        AdvisoryMessage = $AdvisoryMessage
        PreviewRelease = [bool]$PreviewRelease
        ContinuousIntegrationRequested = [bool]$ContinuousIntegrationRequested
        Target = [System.IO.Path]::GetFileName($ProjectInfo.ProjectJSON)
        Action = "Update module version using $Label release label"
        PreviousVersion = $ProjectInfo.Version
        NewVersion = $VersionUpdatePlan.NewVersion.ToString()
    }
}
