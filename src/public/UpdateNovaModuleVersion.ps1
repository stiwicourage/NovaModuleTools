function Update-NovaModuleVersion {
    [CmdletBinding(SupportsShouldProcess = $true)]
    param(
        [string]$Path = (Get-Location).Path
    )

    $projectRoot = (Resolve-Path -LiteralPath $Path).Path
    $before = Get-NovaProjectInfo -Path $projectRoot
    $commitMessages = @(Get-GitCommitMessageForVersionBump -ProjectRoot $projectRoot)
    $label = Get-NovaVersionLabelForBump -ProjectRoot $projectRoot -CommitMessages $commitMessages
    $nextVersion = $null
    $shouldReturnResult = $WhatIfPreference

    Push-Location -LiteralPath $projectRoot
    try {
        $versionUpdatePlan = Get-NovaVersionUpdatePlan -Label $label
        $target = [System.IO.Path]::GetFileName($before.ProjectJSON)
        $action = "Update module version using $label release label"
        $nextVersion = $versionUpdatePlan.NewVersion.ToString()

        if ($env:NOVA_CLI_CONFIRM_BUMP -eq '1' -and -not $WhatIfPreference) {
            $confirmedFromCli = Confirm-NovaCliBumpAction -Target $target -Action $action
            if (-not $confirmedFromCli) {
                return
            }
        }

        if ( $PSCmdlet.ShouldProcess($target, $action)) {
            Set-NovaModuleVersion -Label $label -Confirm:$false
            $shouldReturnResult = $true
        }
    }
    finally {
        Pop-Location
    }

    if (-not $shouldReturnResult) {
        return
    }

    return [pscustomobject]@{
        PreviousVersion = $before.Version
        NewVersion = $nextVersion
        Label = $label
        CommitCount = $commitMessages.Count
    }
}
