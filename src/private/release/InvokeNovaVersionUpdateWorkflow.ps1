function Invoke-NovaVersionUpdateWorkflow {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][pscustomobject]$WorkflowContext,
        [switch]$ShouldRun,
        [switch]$WhatIfEnabled
    )

    $versionWriteResult = $null
    if ($ShouldRun) {
        $versionWriteResult = Set-NovaModuleVersion -ProjectInfo $WorkflowContext.ProjectInfo -Label (Get-NovaVersionUpdateEffectiveLabel -WorkflowContext $WorkflowContext) -PreviewRelease:$WorkflowContext.PreviewRelease -Confirm:$false
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

function Get-NovaVersionUpdateEffectiveLabel {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][pscustomobject]$WorkflowContext
    )

    if ($WorkflowContext.PSObject.Properties.Name -contains 'EffectiveLabel' -and -not [string]::IsNullOrWhiteSpace($WorkflowContext.EffectiveLabel)) {
        return $WorkflowContext.EffectiveLabel
    }

    return $WorkflowContext.Label
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
        EffectiveLabel = Get-NovaVersionUpdateEffectiveLabel -WorkflowContext $WorkflowContext
        AdvisoryMessage = Get-NovaVersionUpdateAdvisoryMessage -WorkflowContext $WorkflowContext
        CommitCount = $WorkflowContext.CommitCount
        Applied = [bool]$Applied
    }
}

function Get-NovaVersionUpdateAdvisoryMessage {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][pscustomobject]$WorkflowContext
    )

    if ($WorkflowContext.PSObject.Properties.Name -notcontains 'AdvisoryMessage') {
        return $null
    }

    return $WorkflowContext.AdvisoryMessage
}

