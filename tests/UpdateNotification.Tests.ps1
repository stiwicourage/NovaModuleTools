BeforeAll {
    $here = Split-Path -Parent $PSCommandPath
    $script:repoRoot = Split-Path -Parent $here
    $script:moduleName = (Get-Content -LiteralPath (Join-Path $script:repoRoot 'project.json') -Raw | ConvertFrom-Json).ProjectName
    $script:distModuleDir = Join-Path $script:repoRoot "dist/$script:moduleName"

    if (-not (Test-Path -LiteralPath $script:distModuleDir)) {
        throw "Expected built $script:moduleName module at: $script:distModuleDir. Run Invoke-NovaBuild in the repo root first."
    }

    Remove-Module $script:moduleName -ErrorAction SilentlyContinue
    Import-Module $script:distModuleDir -Force

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
}

Describe 'Update notification behavior' {
    It 'Get-NovaUpdateNotificationPreference defaults prerelease notifications to enabled when no settings file exists' {
        $configRoot = Join-Path $TestDrive 'config-default'
        $originalConfigHome = $env:XDG_CONFIG_HOME
        $originalAppData = $env:APPDATA

        try {
            $env:XDG_CONFIG_HOME = $configRoot
            $env:APPDATA = $null

            InModuleScope $script:moduleName {
                $result = Get-NovaUpdateNotificationPreference

                $result.PrereleaseNotificationsEnabled | Should -BeTrue
                $result.StableReleaseNotificationsEnabled | Should -BeTrue
            }
        }
        finally {
            $env:XDG_CONFIG_HOME = $originalConfigHome
            $env:APPDATA = $originalAppData
        }
    }

    It 'Set-NovaUpdateNotificationPreference can disable and re-enable prerelease notifications' {
        $configRoot = Join-Path $TestDrive 'config-toggle'
        $originalConfigHome = $env:XDG_CONFIG_HOME
        $originalAppData = $env:APPDATA

        try {
            $env:XDG_CONFIG_HOME = $configRoot
            $env:APPDATA = $null

            InModuleScope $script:moduleName {
                $disabled = Set-NovaUpdateNotificationPreference -DisablePrereleaseNotifications -Confirm:$false
                $disabled.PrereleaseNotificationsEnabled | Should -BeFalse
                $disabled.StableReleaseNotificationsEnabled | Should -BeTrue

                $enabled = Set-NovaUpdateNotificationPreference -EnablePrereleaseNotifications -Confirm:$false
                $enabled.PrereleaseNotificationsEnabled | Should -BeTrue
                $enabled.StableReleaseNotificationsEnabled | Should -BeTrue
            }
        }
        finally {
            $env:XDG_CONFIG_HOME = $originalConfigHome
            $env:APPDATA = $originalAppData
        }
    }

    It 'Invoke-NovaModuleUpdateLookup returns nothing when the lookup exceeds the timeout' {
        InModuleScope $script:moduleName {
            $started = [datetime]::UtcNow
            $result = Invoke-NovaModuleUpdateLookup -AllowPrereleaseNotifications:$true -TimeoutMilliseconds 200 -LookupScript @'
param($ResolvedModuleName, $IncludePrerelease)
Start-Sleep -Milliseconds 1000
[pscustomobject]@{
    Stable = $null
    Prerelease = $null
}
'@
            $elapsedMilliseconds = ([datetime]::UtcNow - $started).TotalMilliseconds

            $result | Should -BeNullOrEmpty
            $elapsedMilliseconds | Should -BeLessThan 900
        }
    }

    It 'Invoke-NovaModuleUpdateLookup stays silent when the lookup throws' {
        InModuleScope $script:moduleName {
            $result = Invoke-NovaModuleUpdateLookup -AllowPrereleaseNotifications:$true -TimeoutMilliseconds 200 -LookupScript @'
param($ResolvedModuleName, $IncludePrerelease)
throw 'offline'
'@

            $result | Should -BeNullOrEmpty
        }
    }

    It 'Invoke-NovaBuildUpdateNotification warns about a newer stable release even when prerelease notifications are disabled' {
        $result = Invoke-TestBuildUpdateNotification -PrereleaseNotificationsEnabled:$false -LookupResult ([pscustomobject]@{
            Stable = [pscustomobject]@{Version = '1.1.0'}
            Prerelease = [pscustomobject]@{Version = '1.2.0-preview'}
        })

        $result.Warnings | Should -HaveCount 1
        $result.Warnings[0] | Should -Match 'newer NovaModuleTools release is available'
        $result.Warnings[0] | Should -Match 'Update-Module NovaModuleTools'
    }

    It 'Invoke-NovaBuildUpdateNotification warns about a newer prerelease only when prerelease notifications are enabled' {
        $result = Invoke-TestBuildUpdateNotification -PrereleaseNotificationsEnabled:$true -LookupResult ([pscustomobject]@{
            Stable = $null
            Prerelease = [pscustomobject]@{Version = '1.1.0-preview'}
        })

        $result.Warnings | Should -HaveCount 1
        $result.Warnings[0] | Should -Match 'newer NovaModuleTools prerelease is available'
        $result.Warnings[0] | Should -Match 'Update-Module NovaModuleTools -AllowPrerelease'
        $result.Warnings[0] | Should -Match 'Set-NovaUpdateNotificationPreference -DisablePrereleaseNotifications'
    }

    It 'Invoke-NovaBuildUpdateNotification stays silent when lookup returns nothing' {
        InModuleScope $script:moduleName {
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
            Mock Write-Warning {throw 'should stay silent'}

            {Invoke-NovaBuildUpdateNotification} | Should -Not -Throw
            Assert-MockCalled Write-Warning -Times 0
        }
    }
}




