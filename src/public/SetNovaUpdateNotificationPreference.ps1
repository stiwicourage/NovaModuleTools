function Set-NovaUpdateNotificationPreference {
    [CmdletBinding(DefaultParameterSetName = 'Enable', SupportsShouldProcess = $true)]
    param(
        [Parameter(Mandatory, ParameterSetName = 'Enable')]
        [switch]$EnablePrereleaseNotifications,

        [Parameter(Mandatory, ParameterSetName = 'Disable')]
        [switch]$DisablePrereleaseNotifications
    )

    $enablePrerelease = $EnablePrereleaseNotifications.IsPresent
    $target = Get-NovaUpdateSettingsFilePath
    $action = if ($enablePrerelease) {
        'Enable prerelease update notifications'
    }
    elseif ($DisablePrereleaseNotifications.IsPresent) {
        'Disable prerelease update notifications'
    }
    else {
        throw 'Specify either -EnablePrereleaseNotifications or -DisablePrereleaseNotifications.'
    }

    if (-not $PSCmdlet.ShouldProcess($target, $action)) {
        return
    }

    Write-NovaUpdateNotificationPreference -PrereleaseNotificationsEnabled:$enablePrerelease
    return Get-NovaUpdateNotificationPreference
}
