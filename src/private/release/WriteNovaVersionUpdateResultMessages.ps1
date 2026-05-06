function Invoke-NovaVersionUpdateCiActivation {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][string]$ProjectRoot,
        [Parameter(Mandatory)][hashtable]$Parameters,
        [switch]$ContinuousIntegration,
        [switch]$WhatIfEnabled
    )

    if (-not $ContinuousIntegration -or $WhatIfEnabled) {
        return [pscustomobject]@{ShouldReturn = $false; Result = $null}
    }

    $ciActivatedCommand = Get-NovaVersionUpdateCiActivatedCommand -ProjectRoot $ProjectRoot
    if ($null -eq $ciActivatedCommand) {
        return [pscustomobject]@{ShouldReturn = $false; Result = $null}
    }

    return [pscustomobject]@{
        ShouldReturn = $true
        Result = & $ciActivatedCommand @Parameters
    }
}

function Write-NovaVersionUpdateResultOutput {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][object]$Result
    )

    $advisoryMessage = Get-NovaVersionUpdateResultAdvisoryMessage -Result $Result
    if (-not [string]::IsNullOrWhiteSpace($advisoryMessage)) {
        Write-Warning $advisoryMessage
    }

    if ($Result.Applied) {
        Write-Host "Version bumped to : $( $Result.NewVersion )"
    }
}

function Get-NovaVersionUpdateResultAdvisoryMessage {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][object]$Result
    )

    if ($Result.PSObject.Properties.Name -notcontains 'AdvisoryMessage') {
        return $null
    }

    return $Result.AdvisoryMessage
}


