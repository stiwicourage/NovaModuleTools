$script:updateNotificationTestSupportPath = (Resolve-Path -LiteralPath (Join-Path $PSScriptRoot 'UpdateNotification.TestSupport.ps1')).Path
$global:updateNotificationTestSupportFunctionNameList = @(
    'Invoke-TestBuildUpdateNotification'
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

    It 'ConvertFrom-NovaUpdateCliArgument allows no arguments and rejects unsupported usage' {
        InModuleScope $script:moduleName {
            (ConvertFrom-NovaUpdateCliArgument).Count | Should -Be 0
            {ConvertFrom-NovaUpdateCliArgument -Arguments @('--bogus')} | Should -Throw "Unsupported 'nova update' usage*"
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
        $result.Warnings[0] | Should -Match 'nova update'
    }

    It 'Invoke-NovaBuildUpdateNotification warns about a newer prerelease only when prerelease notifications are enabled' {
        $result = Invoke-TestBuildUpdateNotification -PrereleaseNotificationsEnabled:$true -LookupResult ([pscustomobject]@{
            Stable = $null
            Prerelease = [pscustomobject]@{Version = '1.1.0-preview'}
        })

        $result.Warnings | Should -HaveCount 1
        $result.Warnings[0] | Should -Match 'newer NovaModuleTools prerelease is available'
        $result.Warnings[0] | Should -Match 'Update-Module NovaModuleTools -AllowPrerelease'
        $result.Warnings[0] | Should -Match 'nova update'
        $result.Warnings[0] | Should -Match 'Set-NovaUpdateNotificationPreference -DisablePrereleaseNotifications'
        $result.Warnings[0] | Should -Match 'nova notification -disable'
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
            $commandHelp | Should -Match 'same stored prerelease preference'
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




