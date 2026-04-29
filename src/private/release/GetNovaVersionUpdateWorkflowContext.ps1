function Get-NovaVersionUpdateWorkflowContext {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][string]$ProjectRoot,
        [switch]$PreviewRelease,
        [switch]$ContinuousIntegrationRequested
    )

    $projectInfo = Get-NovaProjectInfo -Path $ProjectRoot
    $commitMessages = @(Get-GitCommitMessageForVersionBump -ProjectRoot $ProjectRoot)
    $label = Get-NovaVersionLabelForBump -ProjectRoot $ProjectRoot -CommitMessages $commitMessages -ContinuousIntegrationRequested:$ContinuousIntegrationRequested
    $labelResolution = Get-NovaVersionUpdateLabelResolution -ProjectInfo $projectInfo -Label $label -PreviewRelease:$PreviewRelease
    $versionUpdatePlan = Get-NovaVersionUpdatePlan -ProjectInfo $projectInfo -Label $labelResolution.EffectiveLabel -PreviewRelease:$PreviewRelease

    return Get-NovaVersionUpdateWorkflowContextObject -ProjectRoot $ProjectRoot -ProjectInfo $projectInfo -CommitMessages $commitMessages -Label $label -EffectiveLabel $labelResolution.EffectiveLabel -AdvisoryMessage $labelResolution.AdvisoryMessage -VersionUpdatePlan $versionUpdatePlan -PreviewRelease:$PreviewRelease -ContinuousIntegrationRequested:$ContinuousIntegrationRequested
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
    if (Test-NovaVersionUpdateUsesMajorZeroFallback -CurrentVersion $currentVersion -Label $Label -PreviewRelease:$PreviewRelease) {
        $effectiveLabel = 'Minor'
        $advisoryMessage = Get-NovaInitialDevelopmentVersioningMessage
    }

    return [pscustomobject]@{
        EffectiveLabel = $effectiveLabel
        AdvisoryMessage = $advisoryMessage
    }
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

    return 'Major version zero (0.y.z) is for initial development, so Nova keeps breaking-change bumps on the 0.y.z line and plans the next minor version instead of 1.0.0. Set 1.0.0 manually once the software is stable; after that, automatic major-version bumps work normally.'
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
