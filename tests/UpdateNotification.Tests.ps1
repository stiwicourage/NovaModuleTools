$script:updateNotificationTestSupportPath = (Resolve-Path -LiteralPath (Join-Path $PSScriptRoot 'UpdateNotification.TestSupport.ps1')).Path
$global:updateNotificationTestSupportFunctionNameList = @(
    'Invoke-TestBuildUpdateNotification'
    'Invoke-TestAvailableModuleUpdateWarning'
    'Invoke-TestNotificationPreferenceToggle'
    'Assert-TestNotificationPreferenceToggleResult'
    'Invoke-TestNovaSelfUpdate'
)

. $script:updateNotificationTestSupportPath

foreach ($functionName in $global:updateNotificationTestSupportFunctionNameList) {
    $scriptBlock = (Get-Command -Name $functionName -CommandType Function -ErrorAction Stop).ScriptBlock
    Set-Item -Path "function:global:$functionName" -Value $scriptBlock
}

BeforeAll {
    $updateNotificationTestSupportPath = (Resolve-Path -LiteralPath (Join-Path $PSScriptRoot 'UpdateNotification.TestSupport.ps1')).Path
    $updateNotificationTestSupportFunctionNameList = $global:updateNotificationTestSupportFunctionNameList

    . $updateNotificationTestSupportPath

    foreach ($functionName in $updateNotificationTestSupportFunctionNameList) {
        $scriptBlock = (Get-Command -Name $functionName -CommandType Function -ErrorAction Stop).ScriptBlock
        Set-Item -Path "function:global:$functionName" -Value $scriptBlock
    }

    $here = Split-Path -Parent $PSCommandPath
    $script:repoRoot = Split-Path -Parent $here
    $script:moduleName = (Get-Content -LiteralPath (Join-Path $script:repoRoot 'project.json') -Raw | ConvertFrom-Json).ProjectName
    $script:distModuleDir = Join-Path $script:repoRoot "dist/$script:moduleName"

    if (-not (Test-Path -LiteralPath $script:distModuleDir)) {
        throw "Expected built $script:moduleName module at: $script:distModuleDir. Run Invoke-NovaBuild in the repo root first."
    }

    Remove-Module $script:moduleName -ErrorAction SilentlyContinue
    Import-Module $script:distModuleDir -Force
}

Describe 'Update notification behavior' {
    It 'Get-NovaUpdateNotificationPreferenceStatus shapes the stored preference and settings path' {
        InModuleScope $script:moduleName {
            Mock Read-NovaUpdateNotificationPreference {
                [pscustomobject]@{PrereleaseNotificationsEnabled = $false}
            }
            Mock Get-NovaUpdateSettingsFilePath {'/tmp/nova/settings.json'}

            $result = Get-NovaUpdateNotificationPreferenceStatus

            $result.PrereleaseNotificationsEnabled | Should -BeFalse
            $result.StableReleaseNotificationsEnabled | Should -BeTrue
            $result.SettingsPath | Should -Be '/tmp/nova/settings.json'
            Assert-MockCalled Read-NovaUpdateNotificationPreference -Times 1
            Assert-MockCalled Get-NovaUpdateSettingsFilePath -Times 1
        }
    }

    It 'Get-NovaUpdateNotificationPreference delegates to the private status helper' {
        InModuleScope $script:moduleName {
            Mock Get-NovaUpdateNotificationPreferenceStatus {
                [pscustomobject]@{
                    PrereleaseNotificationsEnabled = $true
                    StableReleaseNotificationsEnabled = $true
                    SettingsPath = '/tmp/delegated-settings.json'
                }
            }

            $result = Get-NovaUpdateNotificationPreference

            $result.SettingsPath | Should -Be '/tmp/delegated-settings.json'
            Assert-MockCalled Get-NovaUpdateNotificationPreferenceStatus -Times 1
        }
    }

    It 'Get-NovaUpdateNotificationPreferenceChangeContext resolves enable and disable actions' {
        InModuleScope $script:moduleName {
            Mock Get-NovaUpdateSettingsFilePath {'/tmp/nova/settings.json'}

            foreach ($testCase in @(
                @{Enable = $true; Disable = $false; ExpectedEnabled = $true; ExpectedAction = 'Enable prerelease update notifications'}
                @{Enable = $false; Disable = $true; ExpectedEnabled = $false; ExpectedAction = 'Disable prerelease update notifications'}
            )) {
                $result = Get-NovaUpdateNotificationPreferenceChangeContext -EnablePrereleaseNotifications:$testCase.Enable -DisablePrereleaseNotifications:$testCase.Disable

                $result.PrereleaseNotificationsEnabled | Should -Be $testCase.ExpectedEnabled
                $result.Target | Should -Be '/tmp/nova/settings.json'
                $result.Action | Should -Be $testCase.ExpectedAction
            }

            Assert-MockCalled Get-NovaUpdateSettingsFilePath -Times 2
        }
    }

    It 'Invoke-NovaUpdateNotificationPreferenceChange writes the new preference and returns the shared status' {
        InModuleScope $script:moduleName {
            $workflowContext = [pscustomobject]@{
                PrereleaseNotificationsEnabled = $false
                Target = '/tmp/nova/settings.json'
                Action = 'Disable prerelease update notifications'
            }
            Mock Write-NovaUpdateNotificationPreference {}
            Mock Get-NovaUpdateNotificationPreferenceStatus {
                [pscustomobject]@{
                    PrereleaseNotificationsEnabled = $false
                    StableReleaseNotificationsEnabled = $true
                    SettingsPath = '/tmp/nova/settings.json'
                }
            }

            $result = Invoke-NovaUpdateNotificationPreferenceChange -WorkflowContext $workflowContext

            $result.PrereleaseNotificationsEnabled | Should -BeFalse
            $result.SettingsPath | Should -Be '/tmp/nova/settings.json'
            Assert-MockCalled Write-NovaUpdateNotificationPreference -Times 1 -ParameterFilter {
                -not $PrereleaseNotificationsEnabled
            }
            Assert-MockCalled Get-NovaUpdateNotificationPreferenceStatus -Times 1
        }
    }

    It 'Set-NovaUpdateNotificationPreference delegates context resolution and workflow execution to private helpers' {
        InModuleScope $script:moduleName {
            Mock Get-NovaUpdateNotificationPreferenceChangeContext {
                [pscustomobject]@{
                    PrereleaseNotificationsEnabled = $true
                    Target = '/tmp/nova/settings.json'
                    Action = 'Enable prerelease update notifications'
                }
            }
            Mock Invoke-NovaUpdateNotificationPreferenceChange {
                [pscustomobject]@{
                    PrereleaseNotificationsEnabled = $true
                    StableReleaseNotificationsEnabled = $true
                    SettingsPath = '/tmp/nova/settings.json'
                }
            }

            $result = Set-NovaUpdateNotificationPreference -EnablePrereleaseNotifications -Confirm:$false

            $result.PrereleaseNotificationsEnabled | Should -BeTrue
            Assert-MockCalled Get-NovaUpdateNotificationPreferenceChangeContext -Times 1 -ParameterFilter {
                $EnablePrereleaseNotifications -and -not $DisablePrereleaseNotifications
            }
            Assert-MockCalled Invoke-NovaUpdateNotificationPreferenceChange -Times 1 -ParameterFilter {
                $WorkflowContext.PrereleaseNotificationsEnabled -and
                        $WorkflowContext.Target -eq '/tmp/nova/settings.json' -and
                        $WorkflowContext.Action -eq 'Enable prerelease update notifications'
            }
        }
    }

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
        $result = Invoke-TestNotificationPreferenceToggle -ConfigDirectoryName 'config-toggle'

        Assert-TestNotificationPreferenceToggleResult -Result $result
    }

    It 'Invoke-NovaCli notification shows, disables, and re-enables prerelease notifications' {
        $result = Invoke-TestNotificationPreferenceToggle -ConfigDirectoryName 'config-cli-toggle' -UseCli

        Assert-TestNotificationPreferenceToggleResult -Result $result
    }

    It 'Invoke-NovaCli update routes to Update-NovaModuleTool' {
        InModuleScope $script:moduleName {
            Mock Update-NovaModuleTool {[pscustomobject]@{Routed = $true}}

            (Invoke-NovaCli update -Confirm:$false).Routed | Should -BeTrue
            Assert-MockCalled Update-NovaModuleTool -Times 1
        }
    }

    It 'nova update prints a friendly message in PowerShell when no newer version is available' {
        InModuleScope $script:moduleName {
            Mock Update-NovaModuleTool {
                [pscustomobject]@{
                    ModuleName = 'NovaModuleTools'
                    CurrentVersion = '2.0.0-prerelease3'
                    TargetVersion = $null
                    PrereleaseNotificationsEnabled = $true
                    UpdateAvailable = $false
                    Updated = $false
                    Cancelled = $false
                    IsPrereleaseTarget = $false
                    UsedAllowPrerelease = $false
                }
            }

            $result = @(nova update -Confirm:$false)

            $result | Should -HaveCount 2
            $result[0] | Should -Be "You're up to date!"
            $result[1] | Should -Be 'NovaModuleTools 2.0.0-prerelease3 is currently the newest version available.'
            Assert-MockCalled Update-NovaModuleTool -Times 1
        }
    }

    It 'ConvertFrom-NovaUpdateCliArgument allows no arguments and rejects unsupported usage' {
        InModuleScope $script:moduleName {
            (ConvertFrom-NovaUpdateCliArgument).Count | Should -Be 0
            {ConvertFrom-NovaUpdateCliArgument -Arguments @('--bogus')} | Should -Throw "Unsupported 'nova update' usage*"
        }
    }

    It 'Invoke-NovaModuleSelfUpdate promotes Update-Module errors to terminating failures' {
        InModuleScope $script:moduleName {
            Mock Update-Module {
                Write-Error "Module '$Name' was not installed by using Install-Module, so it cannot be updated."
            }

            {Invoke-NovaModuleSelfUpdate -ModuleName 'NovaModuleTools' -AllowPrerelease} | Should -Throw '*was not installed by using Install-Module*'
            Assert-MockCalled Update-Module -Times 1 -ParameterFilter {
                $Name -eq 'NovaModuleTools' -and $AllowPrerelease -and $ErrorAction -eq 'Stop'
            }
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
        $result.Warnings[0] | Should -Match 'Release notes: https://www\.novamoduletools\.com/release-notes\.html'
        $result.Warnings[0] | Should -Match 'Update-Module NovaModuleTools'
        $result.Warnings[0] | Should -Match 'nova update'
    }

    It 'Invoke-NovaBuildUpdateNotification warns about a newer prerelease only when prerelease notifications are enabled' {
        $result = Invoke-TestBuildUpdateNotification -PrereleaseNotificationsEnabled:$true -LookupResult ([pscustomobject]@{
            Stable = $null
            Prerelease = [pscustomobject]@{Version = '1.1.0-preview'}
        })

        $result.Warnings | Should -HaveCount 1
        $result.Warnings[0] | Should -Match 'newer NovaModuleTools prerelease is available'
        $result.Warnings[0] | Should -Match 'Release notes: https://www\.novamoduletools\.com/release-notes\.html'
        $result.Warnings[0] | Should -Match 'Update-Module NovaModuleTools -AllowPrerelease'
        $result.Warnings[0] | Should -Match 'nova update'
        $result.Warnings[0] | Should -Match 'Set-NovaUpdateNotificationPreference -DisablePrereleaseNotifications'
        $result.Warnings[0] | Should -Match 'nova notification -disable'
    }

    It 'Write-NovaAvailableModuleUpdateWarning preserves host rendering so warning text can stay colored' {
        $result = Invoke-TestAvailableModuleUpdateWarning -Prerelease

        if (-not $result.IsSupported) {
            Set-ItResult -Skipped -Because 'PSStyle.OutputRendering is unavailable in this PowerShell host.'
            return
        }

        $result.OutputRendering | Should -Be 'Host'
        $result.Warnings | Should -HaveCount 1
        $result.Warnings[0] | Should -Match 'newer NovaModuleTools prerelease is available'
    }

    It 'Write-NovaAvailableModuleUpdateWarning omits the release-notes line when metadata is unavailable' {
        InModuleScope $script:moduleName {
            $script:warningMessages = @()

            Mock Get-NovaModuleReleaseNotesUri {$null}
            Mock Write-Warning {$script:warningMessages += $Message}

            Write-NovaAvailableModuleUpdateWarning -CurrentVersion '1.0.0' -AvailableVersion '1.1.0'

            $script:warningMessages | Should -HaveCount 1
            $script:warningMessages[0] -split '\r?\n' | Should -Be @(
                'A newer NovaModuleTools release is available.'
                'Current: 1.0.0'
                'Available: 1.1.0'
                ''
                'Update:'
                'PS> Update-Module NovaModuleTools'
                'nova update'
            )
        }
    }

    It 'Update-NovaModuleTool applies a stable update without prerelease confirmation' {
        $result = Invoke-TestNovaSelfUpdate -Options ([pscustomobject]@{
            PrereleaseNotificationsEnabled = $true
            LookupResult = [pscustomobject]@{
                Stable = [pscustomobject]@{Version = '1.1.0'}
                Prerelease = $null
            }
            ConfirmPrerelease = $true
            UseCli = $false
        })

        $result.PreferenceReadCount | Should -Be 1
        $result.PrereleaseConfirmationCount | Should -Be 0
        $result.Result.UpdateAvailable | Should -BeTrue
        $result.Result.Updated | Should -BeTrue
        $result.Result.TargetVersion | Should -Be '1.1.0'
        $result.Result.UsedAllowPrerelease | Should -BeFalse
        $result.UpdateInvocation.AllowPrerelease | Should -BeFalse
    }

    It 'Update-NovaModuleTool prints the release notes link after a successful self-update' {
        $result = Invoke-TestNovaSelfUpdate -Options ([pscustomobject]@{
            PrereleaseNotificationsEnabled = $true
            LookupResult = [pscustomobject]@{
                Stable = [pscustomobject]@{Version = '1.1.0'}
                Prerelease = $null
            }
            ConfirmPrerelease = $true
            ReleaseNotesUri = 'https://www.novamoduletools.com/release-notes.html'
            UseCli = $false
        })

        $result.Result.Updated | Should -BeTrue
        $result.HostMessages | Should -Contain 'Release notes: https://www.novamoduletools.com/release-notes.html'
    }

    It 'nova update prints the release notes link after a successful self-update' {
        $result = Invoke-TestNovaSelfUpdate -Options ([pscustomobject]@{
            PrereleaseNotificationsEnabled = $true
            LookupResult = [pscustomobject]@{
                Stable = [pscustomobject]@{Version = '1.1.0'}
                Prerelease = $null
            }
            ConfirmPrerelease = $true
            ReleaseNotesUri = 'https://www.novamoduletools.com/release-notes.html'
            UseCli = $true
        })

        $result.Result.Updated | Should -BeTrue
        $result.HostMessages | Should -Contain 'Release notes: https://www.novamoduletools.com/release-notes.html'
    }

    It 'Update-NovaModuleTool skips the release notes link when metadata is unavailable' {
        $result = Invoke-TestNovaSelfUpdate -Options ([pscustomobject]@{
            PrereleaseNotificationsEnabled = $true
            LookupResult = [pscustomobject]@{
                Stable = [pscustomobject]@{Version = '1.1.0'}
                Prerelease = $null
            }
            ConfirmPrerelease = $true
            ReleaseNotesUri = $null
            UseCli = $false
        })

        $result.Result.Updated | Should -BeTrue
        $result.HostMessages | Should -HaveCount 0
    }

    It 'nova update stops on self-update failure instead of returning a success object' {
        InModuleScope $script:moduleName {
            Mock Read-NovaUpdateNotificationPreference {
                [pscustomobject]@{PrereleaseNotificationsEnabled = $true}
            }
            Mock Get-NovaInstalledModuleVersionInfo {
                [pscustomobject]@{
                    ModuleName = 'NovaModuleTools'
                    Version = '2.0.0-prerelease2'
                    SemanticVersion = [semver]'2.0.0-prerelease2'
                    IsPrerelease = $true
                }
            }
            Mock Invoke-NovaModuleUpdateLookup {
                [pscustomobject]@{
                    Stable = $null
                    Prerelease = [pscustomobject]@{Version = '2.0.0-prerelease3'}
                }
            }
            Mock Confirm-NovaPrereleaseModuleUpdate {$true}
            Mock Invoke-NovaModuleSelfUpdate {
                throw "Module 'NovaModuleTools' was not installed by using Install-Module, so it cannot be updated."
            }

            {nova update -Confirm:$false} | Should -Throw '*was not installed by using Install-Module*'
            Assert-MockCalled Invoke-NovaModuleSelfUpdate -Times 1
        }
    }

    It 'Update-NovaModuleTool requires explicit confirmation before a prerelease update proceeds' {
        $result = Invoke-TestNovaSelfUpdate -Options ([pscustomobject]@{
            PrereleaseNotificationsEnabled = $true
            LookupResult = [pscustomobject]@{
                Stable = $null
                Prerelease = [pscustomobject]@{Version = '1.1.0-preview'}
            }
            ConfirmPrerelease = $false
            UseCli = $false
        })

        $result.PrereleaseConfirmationCount | Should -Be 1
        $result.Result.UpdateAvailable | Should -BeTrue
        $result.Result.Updated | Should -BeFalse
        $result.Result.Cancelled | Should -BeTrue
        $result.UpdateInvocation | Should -BeNullOrEmpty
    }

    It 'Update-NovaModuleTool respects the shared prerelease preference when both stable and prerelease candidates exist' {
        foreach ($testCase in @(
            @{
                Name = 'disabled preference stays on stable'
                PrereleaseNotificationsEnabled = $false
                ExpectedConfirmationCount = 0
                ExpectedTargetVersion = '1.1.0'
                ExpectedAllowPrerelease = $false
            }
            @{
                Name = 're-enabled preference can target prerelease again'
                PrereleaseNotificationsEnabled = $true
                ExpectedConfirmationCount = 1
                ExpectedTargetVersion = '2.0.0-preview'
                ExpectedAllowPrerelease = $true
            }
        )) {
            $result = Invoke-TestNovaSelfUpdate -Options ([pscustomobject]@{
                PrereleaseNotificationsEnabled = $testCase.PrereleaseNotificationsEnabled
                LookupResult = [pscustomobject]@{
                    Stable = [pscustomobject]@{Version = '1.1.0'}
                    Prerelease = [pscustomobject]@{Version = '2.0.0-preview'}
                }
                ConfirmPrerelease = $true
                UseCli = $false
            })

            $result.PrereleaseConfirmationCount | Should -Be $testCase.ExpectedConfirmationCount -Because $testCase.Name
            $result.Result.TargetVersion | Should -Be $testCase.ExpectedTargetVersion -Because $testCase.Name
            $result.Result.UsedAllowPrerelease | Should -Be $testCase.ExpectedAllowPrerelease -Because $testCase.Name
            $result.UpdateInvocation.AllowPrerelease | Should -Be $testCase.ExpectedAllowPrerelease -Because $testCase.Name
        }
    }

    It 'Invoke-NovaBuildUpdateNotification and Update-NovaModuleTool both use the shared prerelease preference helper' {
        InModuleScope $script:moduleName {
            $script:preferenceReadCount = 0

            Mock Read-NovaUpdateNotificationPreference {
                $script:preferenceReadCount++
                [pscustomobject]@{PrereleaseNotificationsEnabled = $true}
            }
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
                    Stable = $null
                    Prerelease = $null
                }
            }
            Mock Write-Warning {throw 'should stay silent'}
            Mock Confirm-NovaPrereleaseModuleUpdate {throw 'should not prompt'}
            Mock Invoke-NovaModuleSelfUpdate {throw 'should not update'}

            Invoke-NovaBuildUpdateNotification
            $result = Update-NovaModuleTool -Confirm:$false

            $script:preferenceReadCount | Should -Be 2
            $result.PrereleaseNotificationsEnabled | Should -BeTrue
            $result.UpdateAvailable | Should -BeFalse
        }
    }

    It 'CLI and command help include nova update and its prerelease behavior' {
        InModuleScope $script:moduleName {
            $cliHelp = Invoke-NovaCli --help
            $commandHelp = Get-Help Update-NovaModuleTool -Full -ErrorAction Stop | Out-String

            $cliHelp | Should -Match 'update\s+Update the installed NovaModuleTools module using the stored prerelease preference'
            $cliHelp | Should -Match 'nova update'
            $cliHelp | Should -Match 'prerelease targets require explicit confirmation'
            $commandHelp | Should -Match 'stored prerelease preference'
            $commandHelp | Should -Match 'explicit confirmation'
            $commandHelp | Should -Match 'nova update'
        }
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
