function Write-NovaAvailableModuleUpdateWarning {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][string]$CurrentVersion,
        [Parameter(Mandatory)][string]$AvailableVersion,
        [switch]$Prerelease
    )

    $moduleName = 'NovaModuleTools'
    $releaseNotesUri = Get-NovaModuleReleaseNotesUri
    $updateCommand = if ($Prerelease) {
        "PS> Update-Module $moduleName -AllowPrerelease"
    }
    else {
        "PS> Update-Module $moduleName"
    }

    $heading = if ($Prerelease) {
        "A newer $moduleName prerelease is available."
    }
    else {
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
        $updateCommand
        'nova update'
    )

    if ($Prerelease) {
        $messageLines += @(
            ''
            'To stop prerelease update notifications:'
            'PS> Set-NovaUpdateNotificationPreference -DisablePrereleaseNotifications'
            'nova notification -disable'
            'Stable release notifications remain enabled.'
        )
    }

    $message = $messageLines -join [Environment]::NewLine
    Write-Warning $message
}
