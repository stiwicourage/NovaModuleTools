function Set-NovaUpdateNotificationPreference {
    [CmdletBinding(DefaultParameterSetName = 'Enable', SupportsShouldProcess = $true)]
    param(
        [Parameter(Mandatory, ParameterSetName = 'Enable')]
        [switch]$EnablePrereleaseNotifications,

        [Parameter(Mandatory, ParameterSetName = 'Disable')]
        [switch]$DisablePrereleaseNotifications
    )

    $workflowContext = Get-NovaUpdateNotificationPreferenceChangeContext -EnablePrereleaseNotifications:$EnablePrereleaseNotifications -DisablePrereleaseNotifications:$DisablePrereleaseNotifications -WorkflowParams @{WhatIf = [bool]$WhatIfPreference}

    $shouldRun = $PSCmdlet.ShouldProcess($workflowContext.Target, $workflowContext.Action)
    if (-not $shouldRun -and -not $WhatIfPreference) {
        return
    }

    return Invoke-NovaUpdateNotificationPreferenceChange -WorkflowContext $workflowContext -ShouldRun:$shouldRun
}
