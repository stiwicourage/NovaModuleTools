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

function Invoke-TestAvailableModuleUpdateWarning {
    param([switch]$Prerelease)

    InModuleScope $script:moduleName -Parameters @{Prerelease = $Prerelease.IsPresent} {
        param($Prerelease)

        if ($null -eq $PSStyle -or $PSStyle.PSObject.Properties.Name -notcontains 'OutputRendering') {
            return [pscustomobject]@{IsSupported = $false}
        }

        $script:capturedWarnings = @()
        $previousRendering = $PSStyle.OutputRendering

        try {
            $PSStyle.OutputRendering = 'Host'
            Mock Write-Warning {$script:capturedWarnings += $Message}
            Write-NovaAvailableModuleUpdateWarning -CurrentVersion '1.0.0' -AvailableVersion '1.1.0-preview' -Prerelease:$Prerelease

            return [pscustomobject]@{
                IsSupported = $true
                OutputRendering = $PSStyle.OutputRendering
                Warnings = @($script:capturedWarnings)
            }
        }
        finally {
            $PSStyle.OutputRendering = $previousRendering
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

function Invoke-TestNovaSelfUpdate {
    param(
        [Parameter(Mandatory)][pscustomobject]$Options
    )

    InModuleScope $script:moduleName -Parameters @{
        TestOptions = $Options
    } {
        param($TestOptions)

        $script:preferenceReadCount = 0
        $script:prereleaseConfirmationCount = 0
        $script:hostMessages = @()
        $script:updateInvocation = $null

        Mock Read-NovaUpdateNotificationPreference {
            $script:preferenceReadCount++
            [pscustomobject]@{PrereleaseNotificationsEnabled = $TestOptions.PrereleaseNotificationsEnabled}
        }
        Mock Get-NovaInstalledModuleVersionInfo {
            [pscustomobject]@{
                ModuleName = 'NovaModuleTools'
                Version = '1.0.0'
                SemanticVersion = [semver]'1.0.0'
                IsPrerelease = $false
            }
        }
        Mock Invoke-NovaModuleUpdateLookup {$TestOptions.LookupResult}
        Mock Confirm-NovaPrereleaseModuleUpdate {
            $script:prereleaseConfirmationCount++
            return $TestOptions.ConfirmPrerelease
        }
        Mock Get-NovaModuleReleaseNotesUri {
            if ($TestOptions.PSObject.Properties.Name -contains 'ReleaseNotesUri') {
                return $TestOptions.ReleaseNotesUri
            }

            return 'https://www.novamoduletools.com/release-notes.html'
        }
        Mock Invoke-NovaModuleSelfUpdate {
            param([string]$ModuleName, [switch]$AllowPrerelease)

            $script:updateInvocation = [pscustomobject]@{
                ModuleName = $ModuleName
                AllowPrerelease = $AllowPrerelease.IsPresent
            }
        }
        Mock Write-Host {$script:hostMessages += $Object}

        $result = if ($TestOptions.UseCli) {
            Invoke-NovaCli update -Confirm:$false
        }
        else {
            Update-NovaModuleTool -Confirm:$false
        }

        return [pscustomobject]@{
            Result = $result
            HostMessages = @($script:hostMessages)
            PreferenceReadCount = $script:preferenceReadCount
            PrereleaseConfirmationCount = $script:prereleaseConfirmationCount
            UpdateInvocation = $script:updateInvocation
        }
    }
}
