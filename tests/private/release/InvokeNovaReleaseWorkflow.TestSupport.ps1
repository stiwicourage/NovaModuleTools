function Get-NovaBuildCommandParameterMap {
    param(
        [hashtable]$WorkflowParams,
        [switch]$OverrideWarningRequested
    )

    $map = @{} + $WorkflowParams
    if ($OverrideWarningRequested) {
        $map.OverrideWarning = $true
    }

    return $map
}

function Invoke-NovaBuild {
    param()

    $script:buildCalls += 1
}

function Test-NovaBuild {
    param()

    $script:testCalls += 1
}

function Update-NovaModuleVersion {
    param()

    $script:versionCalls += 1
    return [pscustomobject]@{Version = '1.0.0'}
}

function Import-NovaBuiltModuleForCi {
    param($ProjectInfo)

    $script:restoreCalls += 1
}

function Write-Message {
    param(
        [string]$Text,
        [string]$color
    )
}

function Write-Progress {
    param(
        $Activity,
        $Status,
        $PercentComplete,
        [switch]$Completed
    )
}
