function Update-NovaModuleVersion {
    [CmdletBinding(SupportsShouldProcess = $true)]
    param(
        [string]$Path = (Get-Location).Path
    )

    $projectRoot = (Resolve-Path -LiteralPath $Path).Path
    $before = Get-MTProjectInfo -Path $projectRoot
    $commitMessages = Get-GitCommitMessageForVersionBump -ProjectRoot $projectRoot
    $label = Get-VersionLabelFromCommitSet -Messages $commitMessages

    Push-Location -LiteralPath $projectRoot
    try {
        Update-MTModuleVersion -Label $label
        $after = Get-MTProjectInfo
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

