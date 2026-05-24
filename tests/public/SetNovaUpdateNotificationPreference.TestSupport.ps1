function Get-NovaUpdateNotificationPreferenceChangeContext {
    param(
        [switch]$EnablePrereleaseNotifications,
        [switch]$DisablePrereleaseNotifications,
        [hashtable]$WorkflowParams
    )

    $script:ctxArgs = @{
        Enable = [bool]$EnablePrereleaseNotifications
        Disable = [bool]$DisablePrereleaseNotifications
        WhatIf = $WorkflowParams.WhatIf
    }

    return [pscustomobject]@{
        Target = 'nm'
        Action = 'Set'
        WorkflowParams = $WorkflowParams
    }
}

function Invoke-NovaUpdateNotificationPreferenceChange {
    param(
        $WorkflowContext,
        [switch]$ShouldRun
    )

    $script:invoked = $true
    $script:shouldRun = [bool]$ShouldRun
    return [pscustomobject]@{Changed = $true}
}
