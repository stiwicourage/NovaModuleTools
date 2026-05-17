function Invoke-NovaModuleUpdateNotificationSafely {
    [CmdletBinding()]
    param(
        [int]$TimeoutMilliseconds = 3000
    )

    try {
        Invoke-NovaModuleUpdateNotification -TimeoutMilliseconds $TimeoutMilliseconds
    } catch {
        $null = $_
    }
}

