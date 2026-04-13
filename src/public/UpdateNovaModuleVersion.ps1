function Update-NovaModuleVersion {
    [CmdletBinding(SupportsShouldProcess = $true)]
    param(
        [string]$Path = (Get-Location).Path
    )

    $projectRoot = (Resolve-Path -LiteralPath $Path).Path
    $before = Get-NovaProjectInfo -Path $projectRoot
    $commitMessages = @(Get-GitCommitMessageForVersionBump -ProjectRoot $projectRoot)
    $label = Get-VersionLabelFromCommitSet -Messages $commitMessages

    Push-Location -LiteralPath $projectRoot
    try {
        $target = $before.ProjectJSON
        $action = "Update module version using $label release label"

        if ( $PSCmdlet.ShouldProcess($target, $action)) {
            Set-NovaModuleVersion -Label $label
            $after = Get-NovaProjectInfo
        }
        else {
            $after = $before
        }
    }
    finally {
        Pop-Location
    }

    return [pscustomobject]@{
        PreviousVersion = $before.Version
        NewVersion = $after.Version
        Label = $label
        CommitCount = $commitMessages.Count
    }
}
