function Invoke-TestBuildUpdateNotification {
    param(
        [bool]$PrereleaseNotificationsEnabled,
        [object]$LookupResult
    )

    InModuleScope $script:moduleName -Parameters @{
        PrereleaseNotificationsEnabled = $PrereleaseNotificationsEnabled
        LookupResult = $LookupResult
    } {
        param($PrereleaseNotificationsEnabled, $LookupResult)

        $script:capturedWarnings = @()

        Mock Read-NovaUpdateNotificationPreference {
            [pscustomobject]@{PrereleaseNotificationsEnabled = $PrereleaseNotificationsEnabled}
        }
        Mock Get-NovaInstalledModuleVersionInfo {
            [pscustomobject]@{
                ModuleName = 'NovaModuleTools'
                Version = '1.0.0'
                SemanticVersion = [semver]'1.0.0'
                IsPrerelease = $false
            }
        }
        Mock Invoke-NovaModuleUpdateLookup {$LookupResult}
        Mock Write-Warning {$script:capturedWarnings += $Message}

        Invoke-NovaBuildUpdateNotification
        return [pscustomobject]@{
            Warnings = @($script:capturedWarnings)
        }
    }
}

function Invoke-TestNotificationPreferenceToggle {
    param(
        [Parameter(Mandatory)][string]$ConfigDirectoryName,
        [switch]$UseCli
    )

    $configRoot = Join-Path $TestDrive $ConfigDirectoryName
    $originalConfigHome = $env:XDG_CONFIG_HOME
    $originalAppData = $env:APPDATA

    try {
        $env:XDG_CONFIG_HOME = $configRoot
        $env:APPDATA = $null

        return InModuleScope $script:moduleName -Parameters @{UseCli = $UseCli.IsPresent} {
            param($UseCli)

            if ($UseCli) {
                $status = Invoke-NovaCli notification
                $disabled = Invoke-NovaCli notification -disable -Confirm:$false
                $enabled = Invoke-NovaCli notification -enable -Confirm:$false
            }
            else {
                $status = Get-NovaUpdateNotificationPreference
                $disabled = Set-NovaUpdateNotificationPreference -DisablePrereleaseNotifications -Confirm:$false
                $enabled = Set-NovaUpdateNotificationPreference -EnablePrereleaseNotifications -Confirm:$false
            }

            [pscustomobject]@{
                Status = $status
                Disabled = $disabled
                Enabled = $enabled
            }
        }
    }
    finally {
        $env:XDG_CONFIG_HOME = $originalConfigHome
        $env:APPDATA = $originalAppData
    }
}

function Assert-TestNotificationPreferenceToggleResult {
    param([Parameter(Mandatory)][pscustomobject]$Result)

    $Result.Status.PrereleaseNotificationsEnabled | Should -BeTrue
    $Result.Status.StableReleaseNotificationsEnabled | Should -BeTrue
    $Result.Disabled.PrereleaseNotificationsEnabled | Should -BeFalse
    $Result.Disabled.StableReleaseNotificationsEnabled | Should -BeTrue
    $Result.Enabled.PrereleaseNotificationsEnabled | Should -BeTrue
    $Result.Enabled.StableReleaseNotificationsEnabled | Should -BeTrue
}

