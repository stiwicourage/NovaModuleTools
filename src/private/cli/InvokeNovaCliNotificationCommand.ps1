function Invoke-NovaCliNotificationCommand {
    [CmdletBinding()]
    param(
        [AllowEmptyCollection()][string[]]$Arguments = @(),
        [Parameter(Mandatory)][hashtable]$CommonParameters,
        [Parameter(Mandatory)][hashtable]$MutatingCommonParameters
    )

    $notificationAction = ConvertFrom-NovaNotificationCliArgument -Arguments $Arguments

    switch ($notificationAction) {
        'status' {
            return Get-NovaUpdateNotificationPreference @CommonParameters
        }
        'enable' {
            return Set-NovaUpdateNotificationPreference -EnablePrereleaseNotifications @MutatingCommonParameters
        }
        default {
            return Set-NovaUpdateNotificationPreference -DisablePrereleaseNotifications @MutatingCommonParameters
        }
    }
}
