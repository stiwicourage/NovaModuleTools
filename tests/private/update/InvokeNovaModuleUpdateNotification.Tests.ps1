BeforeAll {
    $script:repoRoot = (Resolve-Path (Join-Path $PSScriptRoot '../../..')).Path
    $script:moduleName = (Get-Content -LiteralPath (Join-Path $script:repoRoot 'project.json') -Raw | ConvertFrom-Json).ProjectName
    $script:distModuleDir = Join-Path $script:repoRoot "dist/$script:moduleName"

    if (-not (Test-Path -LiteralPath $script:distModuleDir)) {
        throw "Expected built $script:moduleName module at: $script:distModuleDir. Run Invoke-NovaBuild in the repo root first."
    }

    Remove-Module $script:moduleName -ErrorAction SilentlyContinue
    Import-Module $script:distModuleDir -Force
}

Describe 'Invoke-NovaModuleUpdateNotification' {
    It 'warns about a newer stable release even when prerelease notifications are disabled' {
        InModuleScope $script:moduleName {
            $script:warningMessages = @()

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
            Mock Write-Warning {$script:warningMessages += $Message}

            Invoke-NovaModuleUpdateNotification

            $script:warningMessages | Should -HaveCount 1
            $script:warningMessages[0] | Should -Match 'newer NovaModuleTools release is available'
            $script:warningMessages[0] | Should -Match 'Update-Module NovaModuleTools'
            $script:warningMessages[0] | Should -Match '% nova update'
        }
    }

    It 'stays silent when the update lookup returns nothing' {
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

            {Invoke-NovaModuleUpdateNotification} | Should -Not -Throw
            Assert-MockCalled Write-Warning -Times 0
        }
    }
}

