function Write-NovaAvailableModuleUpdateWarning {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][string]$CurrentVersion,
        [Parameter(Mandatory)][string]$AvailableVersion,
        [switch]$Prerelease
    )

    $moduleName = 'NovaModuleTools'
    $releaseNotesUri = Get-NovaModuleReleaseNotesUri
    $heading = if ($Prerelease) {
        "A newer $moduleName prerelease is available."
    } else {
        "A newer $moduleName release is available."
    }

    $messageLines = @(
        $heading
        "Current: $CurrentVersion"
        "Available: $AvailableVersion"
    )

    if ($null -ne $releaseNotesUri) {
        $messageLines += "Release notes: $releaseNotesUri"
    }

    $messageLines += @(
        ''
        'Update:'
        'PS> Update-NovaModuleTool'
        '% nova update'
    )

    if ($Prerelease) {
        $messageLines += @(
            ''
            'To stop prerelease update notifications:'
            'PS> Set-NovaUpdateNotificationPreference -DisablePrereleaseNotifications'
            '% nova notification --disable'
            'Stable release notifications remain enabled.'
        )
    }

    $message = $messageLines -join [Environment]::NewLine
    Write-Warning $message
}
