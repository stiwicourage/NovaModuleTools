function Invoke-NovaVersionUpdateWorkflow {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][pscustomobject]$WorkflowContext,
        [switch]$ShouldRun,
        [switch]$WhatIfEnabled
    )

    $versionWriteResult = $null
    if ($ShouldRun) {
        $versionWriteResult = Set-NovaModuleVersion -ProjectInfo $WorkflowContext.ProjectInfo -Label $WorkflowContext.Label -PreviewRelease:$WorkflowContext.PreviewRelease -Confirm:$false
    }

    if (-not (Test-NovaVersionUpdateResultRequired -ShouldRun:$ShouldRun -WhatIfEnabled:$WhatIfEnabled)) {
        return
    }

    return Get-NovaVersionUpdateResult -WorkflowContext $WorkflowContext -Applied:($null -ne $versionWriteResult -and $versionWriteResult.Applied)
}

function Test-NovaVersionUpdateResultRequired {
    [CmdletBinding()]
    param(
        [switch]$ShouldRun,
        [switch]$WhatIfEnabled
    )

    return $ShouldRun -or $WhatIfEnabled
}

function Get-NovaVersionUpdateResult {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][pscustomobject]$WorkflowContext,
        [switch]$Applied
    )

    return [pscustomobject]@{
        PreviousVersion = $WorkflowContext.PreviousVersion
        NewVersion = $WorkflowContext.NewVersion
        Label = $WorkflowContext.Label
        CommitCount = $WorkflowContext.CommitCount
        Applied = [bool]$Applied
    }
}
