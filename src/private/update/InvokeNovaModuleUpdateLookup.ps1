function Invoke-NovaModuleUpdateLookup {
    [CmdletBinding()]
    param(
        [string]$ModuleName = 'NovaModuleTools',
        [bool]$AllowPrereleaseNotifications,
        [int]$TimeoutMilliseconds = 3000,
        [string]$LookupScript
    )

    if ( [string]::IsNullOrWhiteSpace($LookupScript)) {
        $LookupScript = Get-NovaModuleUpdateLookupScript
    }

    return Invoke-NovaPowerShellScriptWithTimeout -Script $LookupScript -ArgumentList @($ModuleName, $AllowPrereleaseNotifications) -TimeoutMilliseconds $TimeoutMilliseconds
}



