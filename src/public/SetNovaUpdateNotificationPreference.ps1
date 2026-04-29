function Set-NovaUpdateNotificationPreference {
    [CmdletBinding(DefaultParameterSetName = 'Enable', SupportsShouldProcess = $true)]
    param(
        [Parameter(Mandatory, ParameterSetName = 'Enable')]
        [switch]$EnablePrereleaseNotifications,

        [Parameter(Mandatory, ParameterSetName = 'Disable')]
        [switch]$DisablePrereleaseNotifications
    )

    $workflowContext = Get-NovaUpdateNotificationPreferenceChangeContext -EnablePrereleaseNotifications:$EnablePrereleaseNotifications -DisablePrereleaseNotifications:$DisablePrereleaseNotifications

    if (-not $PSCmdlet.ShouldProcess($workflowContext.Target, $workflowContext.Action)) {
        return
    }

    return Invoke-NovaUpdateNotificationPreferenceChange -WorkflowContext $workflowContext
}
