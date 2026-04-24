function Get-NovaVersionUpdateWorkflowContext {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][string]$ProjectRoot,
        [switch]$PreviewRelease
    )

    $projectInfo = Get-NovaProjectInfo -Path $ProjectRoot
    $commitMessages = @(Get-GitCommitMessageForVersionBump -ProjectRoot $ProjectRoot)
    $label = Get-NovaVersionLabelForBump -ProjectRoot $ProjectRoot -CommitMessages $commitMessages
    $versionUpdatePlan = Get-NovaVersionUpdatePlan -ProjectInfo $projectInfo -Label $label -PreviewRelease:$PreviewRelease

    return Get-NovaVersionUpdateWorkflowContextObject -ProjectRoot $ProjectRoot -ProjectInfo $projectInfo -CommitMessages $commitMessages -Label $label -VersionUpdatePlan $versionUpdatePlan -PreviewRelease:$PreviewRelease
}

function Get-NovaVersionUpdateWorkflowContextObject {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][string]$ProjectRoot,
        [Parameter(Mandatory)][pscustomobject]$ProjectInfo,
        [AllowEmptyCollection()][string[]]$CommitMessages = @(),
        [Parameter(Mandatory)][string]$Label,
        [Parameter(Mandatory)][pscustomobject]$VersionUpdatePlan,
        [switch]$PreviewRelease
    )

    return [pscustomobject]@{
        ProjectRoot = $ProjectRoot
        ProjectInfo = $ProjectInfo
        CommitMessages = $CommitMessages
        CommitCount = $CommitMessages.Count
        Label = $Label
        PreviewRelease = [bool]$PreviewRelease
        Target = [System.IO.Path]::GetFileName($ProjectInfo.ProjectJSON)
        Action = "Update module version using $Label release label"
        PreviousVersion = $ProjectInfo.Version
        NewVersion = $VersionUpdatePlan.NewVersion.ToString()
    }
}
