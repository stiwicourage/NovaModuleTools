BeforeAll {
    $projectRoot = Split-Path -Parent (Split-Path -Parent (Split-Path -Parent $PSScriptRoot))
    . (Join-Path $projectRoot 'src/private/update/InvokeNovaModuleUpdateNotification.ps1')

    . (Join-Path $PSScriptRoot 'InvokeNovaModuleUpdateNotification.TestSupport.ps1')
}

Describe 'Invoke-NovaModuleUpdateNotification' {
    It 'warns about a newer stable release even when prerelease notifications are disabled' {
        Mock Read-NovaUpdateNotificationPreference {[pscustomobject]@{PrereleaseNotificationsEnabled = $false}}
        Mock Get-NovaInstalledModuleVersionInfo {
            [pscustomobject]@{
                ModuleName = 'NovaModuleTools'
                Version = '1.0.0'
                SemanticVersion = [semver]'1.0.0'
                IsPrerelease = $false
            }
        }
        Mock Invoke-NovaModuleUpdateLookup {
            [pscustomobject]@{
                Stable = [pscustomobject]@{Version = '1.1.0'}
                Prerelease = [pscustomobject]@{Version = '1.2.0-preview'}
            }
        }
        Mock Get-NovaAvailableSemanticVersion {[semver]'1.1.0'}
        Mock Test-NovaStableUpdateAvailable {$true}
        Mock Test-NovaPrereleaseUpdateAvailable {$false}
        Mock Write-NovaAvailableModuleUpdateWarning {}

        Invoke-NovaModuleUpdateNotification

        Assert-MockCalled Write-NovaAvailableModuleUpdateWarning -Times 1 -Exactly -ParameterFilter {
            $CurrentVersion -eq '1.0.0' -and $AvailableVersion -eq '1.1.0' -and -not $Prerelease
        }
    }

    It 'stays silent when the update lookup returns nothing' {
        Mock Read-NovaUpdateNotificationPreference {[pscustomobject]@{PrereleaseNotificationsEnabled = $true}}
        Mock Get-NovaInstalledModuleVersionInfo {
            [pscustomobject]@{
                ModuleName = 'NovaModuleTools'
                Version = '1.0.0'
                SemanticVersion = [semver]'1.0.0'
                IsPrerelease = $false
            }
        }
        Mock Invoke-NovaModuleUpdateLookup {$null}
        Mock Write-NovaAvailableModuleUpdateWarning {throw 'should stay silent'}

        {Invoke-NovaModuleUpdateNotification} | Should -Not -Throw
        Assert-MockCalled Write-NovaAvailableModuleUpdateWarning -Times 0
    }
}
