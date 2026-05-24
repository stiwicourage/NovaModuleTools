function Invoke-NovaUpdateNotificationPreferenceChange {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][pscustomobject]$WorkflowContext,
        [switch]$ShouldRun
    )

    $whatIfEnabled = Test-NovaUpdateNotificationPreferenceChangeWhatIfEnabled -WorkflowContext $WorkflowContext
    if (-not $ShouldRun) {
        if ($whatIfEnabled) {
            Write-NovaUpdateNotificationPreferenceChangeResult -WorkflowContext $WorkflowContext -WhatIfEnabled
        }

        return
    }

    Write-NovaUpdateNotificationPreference -PrereleaseNotificationsEnabled:$WorkflowContext.PrereleaseNotificationsEnabled
    $status = Get-NovaUpdateNotificationPreferenceStatus
    Write-NovaUpdateNotificationPreferenceChangeResult -WorkflowContext $WorkflowContext -Status $status
    return $status
}

function Test-NovaUpdateNotificationPreferenceChangeWhatIfEnabled {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][pscustomobject]$WorkflowContext
    )

    return $WorkflowContext.WorkflowParams.ContainsKey('WhatIf') -and $WorkflowContext.WorkflowParams.WhatIf
}

function Write-NovaUpdateNotificationPreferenceChangeResult {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][pscustomobject]$WorkflowContext,
        [AllowNull()][pscustomobject]$Status,
        [switch]$WhatIfEnabled
    )

    Write-Message (Get-NovaUpdateNotificationPreferenceChangeStatusMessage -WorkflowContext $WorkflowContext -WhatIfEnabled:$WhatIfEnabled) -color Green
    Write-Message "Settings file: $( Get-NovaUpdateNotificationPreferenceChangeSettingsPath -WorkflowContext $WorkflowContext -Status $Status )"
    Write-Message (Get-NovaUpdateNotificationPreferenceChangeAvailabilityMessage -WhatIfEnabled:$WhatIfEnabled)

    foreach ($line in (Get-NovaUpdateNotificationPreferenceChangeNextStepLine -WorkflowContext $WorkflowContext -WhatIfEnabled:$WhatIfEnabled)) {
        Write-Message $line
    }
}

function Get-NovaUpdateNotificationPreferenceChangeStatusMessage {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][pscustomobject]$WorkflowContext,
        [switch]$WhatIfEnabled
    )

    $stateText = Get-NovaUpdateNotificationPreferenceChangeStateText -PrereleaseNotificationsEnabled:$WorkflowContext.PrereleaseNotificationsEnabled
    if ($WhatIfEnabled) {
        return "Notification preference plan ready: prerelease self-updates $stateText"
    }

    return "Prerelease self-updates are now $stateText."
}

function Get-NovaUpdateNotificationPreferenceChangeSettingsPath {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][pscustomobject]$WorkflowContext,
        [AllowNull()][pscustomobject]$Status
    )

    if ($null -ne $Status -and ($Status.PSObject.Properties.Name -contains 'SettingsPath')) {
        return $Status.SettingsPath
    }

    return $WorkflowContext.Target
}

function Get-NovaUpdateNotificationPreferenceChangeAvailabilityMessage {
    [CmdletBinding()]
    param(
        [switch]$WhatIfEnabled
    )

    if ($WhatIfEnabled) {
        return 'Stable self-updates would remain available.'
    }

    return 'Stable self-updates remain available.'
}

function Get-NovaUpdateNotificationPreferenceChangeNextStepLine {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][pscustomobject]$WorkflowContext,
        [switch]$WhatIfEnabled
    )

    if ($WhatIfEnabled) {
        return @(
            'Next step:'
            "Run $( Get-NovaUpdateNotificationPreferenceChangeCommandLine -WorkflowContext $WorkflowContext ) without -WhatIf when you are ready to store the preference."
        )
    }

    return @(
        'Next step:'
        'Get-NovaUpdateNotificationPreference'
    )
}

function Get-NovaUpdateNotificationPreferenceChangeCommandLine {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][pscustomobject]$WorkflowContext
    )

    if ($WorkflowContext.PrereleaseNotificationsEnabled) {
        return 'Set-NovaUpdateNotificationPreference -EnablePrereleaseNotifications'
    }

    return 'Set-NovaUpdateNotificationPreference -DisablePrereleaseNotifications'
}

function Get-NovaUpdateNotificationPreferenceChangeStateText {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][bool]$PrereleaseNotificationsEnabled
    )

    if ($PrereleaseNotificationsEnabled) {
        return 'enabled'
    }

    return 'disabled'
}
