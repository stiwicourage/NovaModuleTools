function Update-NovaModuleVersion {
    [CmdletBinding(SupportsShouldProcess = $true)]
    param(
        [string]$Path = (Get-Location).Path
    )

    $projectRoot = (Resolve-Path -LiteralPath $Path).Path
    $before = Get-NovaProjectInfo -Path $projectRoot
    $commitMessages = @(Get-GitCommitMessageForVersionBump -ProjectRoot $projectRoot)
    $label = Get-VersionLabelFromCommitSet -Messages $commitMessages
    $nextVersion = $null

    Push-Location -LiteralPath $projectRoot
    try {
        $versionUpdatePlan = Get-NovaVersionUpdatePlan -Label $label
        $target = [System.IO.Path]::GetFileName($before.ProjectJSON)
        $action = "Update module version using $label release label"
        $nextVersion = $versionUpdatePlan.NewVersion.ToString()

        if ( $PSCmdlet.ShouldProcess($target, $action)) {
            Set-NovaModuleVersion -Label $label -Confirm:$false
        }
    }
    finally {
        Pop-Location
    }

    return [pscustomobject]@{
        PreviousVersion = $before.Version
        NewVersion = $nextVersion
        Label = $label
        CommitCount = $commitMessages.Count
    }
}
