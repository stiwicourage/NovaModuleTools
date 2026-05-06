$script:updateNotificationTestSupportPath = (Resolve-Path -LiteralPath (Join-Path $PSScriptRoot 'UpdateNotification.TestSupport.ps1')).Path
$global:updateNotificationTestSupportFunctionNameList = @(
    'Invoke-TestBuildUpdateNotification'
    'Invoke-TestAvailableModuleUpdateWarning'
    'Invoke-TestNotificationPreferenceToggle'
    'Assert-TestNotificationPreferenceToggleResult'
    'Invoke-TestNovaSelfUpdate'
    'New-TestPowerShellRunnerState'
    'New-TestPowerShellWaitHandle'
    'Add-TestPowerShellRunnerMethods'
    'New-TestPowerShellRunner'
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

    It 'Get-NovaUpdateNotificationPreferenceChangeContext throws when neither enable nor disable was requested' {
        InModuleScope $script:moduleName {
            $thrown = $null
            try {
                Get-NovaUpdateNotificationPreferenceChangeContext
            }
            catch {
                $thrown = $_
            }

            $thrown | Should -Not -BeNullOrEmpty
            $thrown.Exception.Message | Should -Be 'Specify either -EnablePrereleaseNotifications or -DisablePrereleaseNotifications.'
            $thrown.FullyQualifiedErrorId | Should -Be 'Nova.Validation.UpdateNotificationPreferenceChangeRequired'
            $thrown.CategoryInfo.Category | Should -Be ([System.Management.Automation.ErrorCategory]::InvalidArgument)
            $thrown.TargetObject | Should -Be 'PrereleaseNotifications'
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

    It 'Read-NovaUpdateNotificationPreference delegates settings file parsing to the shared JSON adapter' {
        InModuleScope $script:moduleName {
            Mock Get-NovaUpdateSettingsFilePath {'/tmp/nova/settings.json'}
            Mock Read-NovaJsonFileData {
                [pscustomobject]@{PrereleaseNotificationsEnabled = $false}
            }

            $result = Read-NovaUpdateNotificationPreference

            $result.PrereleaseNotificationsEnabled | Should -BeFalse
            Assert-MockCalled Read-NovaJsonFileData -Times 1 -ParameterFilter {$LiteralPath -eq '/tmp/nova/settings.json'}
        }
    }

    It 'Write-NovaUpdateNotificationPreference delegates settings persistence to the shared JSON adapter' {
        InModuleScope $script:moduleName {
            Mock Get-NovaUpdateSettingsFilePath {'/tmp/nova/settings.json'}
            Mock Write-NovaJsonFileData {}

            Write-NovaUpdateNotificationPreference -PrereleaseNotificationsEnabled:$false

            Assert-MockCalled Write-NovaJsonFileData -Times 1 -ParameterFilter {
                $LiteralPath -eq '/tmp/nova/settings.json' -and
                        -not $Value.PrereleaseNotificationsEnabled
            }
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

    It 'Get-NovaModuleSelfUpdateWorkflowContext resolves the update plan and action text' {
        InModuleScope $script:moduleName {
            $preference = [pscustomobject]@{PrereleaseNotificationsEnabled = $true}
            $installedModule = [pscustomobject]@{
                ModuleName = 'NovaModuleTools'
                Version = '1.0.0'
                SemanticVersion = [semver]'1.0.0'
                IsPrerelease = $false
            }
            $lookupResult = [pscustomobject]@{
                Stable = $null
                Prerelease = [pscustomobject]@{Version = '1.1.0-preview'}
            }
            Mock Get-NovaModuleSelfUpdatePlan {
                [pscustomobject]@{
                    ModuleName = 'NovaModuleTools'
                    CurrentVersion = '1.0.0'
                    TargetVersion = '1.1.0-preview'
                    PrereleaseNotificationsEnabled = $true
                    UpdateAvailable = $true
                    Updated = $false
                    Cancelled = $false
                    IsPrereleaseTarget = $true
                    UsedAllowPrerelease = $true
                }
            }

            $result = Get-NovaModuleSelfUpdateWorkflowContext -Preference $preference -InstalledModule $installedModule -LookupResult $lookupResult

            $result.Preference.PrereleaseNotificationsEnabled | Should -BeTrue
            $result.InstalledModule.ModuleName | Should -Be 'NovaModuleTools'
            $result.LookupResult.Prerelease.Version | Should -Be '1.1.0-preview'
            $result.Plan.TargetVersion | Should -Be '1.1.0-preview'
            $result.Action | Should -Be 'Update NovaModuleTools to prerelease version 1.1.0-preview'
            Assert-MockCalled Get-NovaModuleSelfUpdatePlan -Times 1 -ParameterFilter {
                $InstalledModule.ModuleName -eq 'NovaModuleTools' -and
                        $LookupResult.Prerelease.Version -eq '1.1.0-preview' -and
                        $PrereleaseNotificationsEnabled
            }
        }
    }

    It 'Get-NovaModuleSelfUpdatePlan preserves the lookup candidate and repository for no-update results' {
        InModuleScope $script:moduleName {
            $installedModule = [pscustomobject]@{
                ModuleName = 'NovaModuleTools'
                Version = '2.0.0-preview9920'
                SemanticVersion = [semver]'2.0.0-preview9920'
                IsPrerelease = $true
            }
            $lookupResult = [pscustomobject]@{
                SourceRepository = 'PSGallery'
                Stable = [pscustomobject]@{
                    Version = '1.9.1'
                    Channel = 'Stable'
                    Repository = 'PSGallery'
                }
                Prerelease = [pscustomobject]@{
                    Version = '2.0.0-beta'
                    Channel = 'Prerelease'
                    Repository = 'PSGallery'
                }
            }

            $result = Get-NovaModuleSelfUpdatePlan -InstalledModule $installedModule -LookupResult $lookupResult -PrereleaseNotificationsEnabled:$true

            $result.UpdateAvailable | Should -BeFalse
            $result.TargetVersion | Should -BeNullOrEmpty
            $result.LookupCandidateVersion | Should -Be '2.0.0-beta'
            $result.LookupCandidateChannel | Should -Be 'Prerelease'
            $result.LookupRepository | Should -Be 'PSGallery'
        }
    }

    It 'Get-NovaModuleSelfUpdatePlanContext returns empty lookup fields when no lookup result is available' {
        InModuleScope $script:moduleName {
            $result = Get-NovaModuleSelfUpdatePlanContext -LookupResult $null -PrereleaseNotificationsEnabled:$true

            $result.LookupCandidateVersion | Should -BeNullOrEmpty
            $result.LookupCandidateChannel | Should -BeNullOrEmpty
            $result.LookupRepository | Should -BeNullOrEmpty
            $result.PrereleaseNotificationsEnabled | Should -BeTrue
        }
    }

    It 'Get-NovaModuleSelfUpdatePlanContext falls back to SourceRepository when the selected lookup candidate omits Repository' {
        InModuleScope $script:moduleName {
            $lookupResult = [pscustomobject]@{
                SourceRepository = 'PSGallery'
                Stable = [pscustomobject]@{
                    Version = '1.9.1'
                    Channel = 'Stable'
                }
                Prerelease = [pscustomobject]@{
                    Version = '2.0.0-beta'
                    Channel = 'Prerelease'
                }
            }

            $result = Get-NovaModuleSelfUpdatePlanContext -LookupResult $lookupResult -PrereleaseNotificationsEnabled:$true

            $result.LookupCandidateVersion | Should -Be '2.0.0-beta'
            $result.LookupCandidateChannel | Should -Be 'Prerelease'
            $result.LookupRepository | Should -Be 'PSGallery'
        }
    }

    It 'Get-NovaModuleSelfUpdateWorkflowContext throws when update lookup cannot resolve a candidate' {
        InModuleScope $script:moduleName {
            Mock Read-NovaUpdateNotificationPreference {[pscustomobject]@{PrereleaseNotificationsEnabled = $true}}
            Mock Get-NovaInstalledModuleVersionInfo {[pscustomobject]@{ModuleName = 'NovaModuleTools'}}
            Mock Invoke-NovaModuleUpdateLookup {$null}

            $thrown = $null
            try {
                Get-NovaModuleSelfUpdateWorkflowContext
            }
            catch {
                $thrown = $_
            }

            $thrown | Should -Not -BeNullOrEmpty
            $thrown.Exception.Message | Should -Be 'Unable to determine a NovaModuleTools update candidate. Try again when the PowerShell Gallery is reachable.'
            $thrown.FullyQualifiedErrorId | Should -Be 'Nova.Dependency.ModuleSelfUpdateCandidateUnavailable'
            $thrown.CategoryInfo.Category | Should -Be ([System.Management.Automation.ErrorCategory]::ResourceUnavailable)
            $thrown.TargetObject | Should -Be 'NovaModuleTools'

            Assert-MockCalled Invoke-NovaModuleUpdateLookup -Times 1 -ParameterFilter {
                $AllowPrereleaseNotifications -and $TimeoutMilliseconds -eq 10000
            }
        }
    }

    It 'Invoke-NovaModuleSelfUpdateWorkflow handles both update and no-update paths correctly' {
        foreach ($testCase in @(
            @{
                Name = 'update available'
                TargetVersion = '1.1.0'
                UpdateAvailable = $true
                ExpectedUpdated = $true
                ExpectedUpdateCalls = 1
                ExpectedReleaseNotesUri = 'https://www.novamoduletools.com/release-notes.html'
                ExpectedReleaseNotesLookups = 1
            }
            @{
                Name = 'no update available'
                TargetVersion = $null
                UpdateAvailable = $false
                ExpectedUpdated = $false
                ExpectedUpdateCalls = 0
                ExpectedReleaseNotesUri = $null
                ExpectedReleaseNotesLookups = 0
            }
        )) {
            InModuleScope $script:moduleName -Parameters @{TestCase = $testCase} {
                param($TestCase)

                $script:releaseNotesLookupCount = 0
                $workflowContext = [pscustomobject]@{
                    Plan = [pscustomobject]@{
                        ModuleName = 'NovaModuleTools'
                        CurrentVersion = '1.0.0'
                        TargetVersion = $TestCase.TargetVersion
                        PrereleaseNotificationsEnabled = $true
                        UpdateAvailable = $TestCase.UpdateAvailable
                        Updated = $false
                        Cancelled = $false
                        IsPrereleaseTarget = $false
                        UsedAllowPrerelease = $false
                    }
                    Action = 'Update NovaModuleTools to version 1.1.0'
                }
                if ($TestCase.ExpectedUpdateCalls -eq 0) {
                    Mock Invoke-NovaModuleSelfUpdate {throw 'should not update'}
                    Mock Get-NovaModuleReleaseNotesUri {
                        $script:releaseNotesLookupCount++
                        throw 'should not look up release notes'
                    }
                }
                else {
                    Mock Invoke-NovaModuleSelfUpdate {}
                    Mock Get-NovaModuleReleaseNotesUri {
                        $script:releaseNotesLookupCount++
                        'https://www.novamoduletools.com/release-notes.html'
                    }
                }

                $result = Invoke-NovaModuleSelfUpdateWorkflow -WorkflowContext $workflowContext

                $result.Updated | Should -Be $TestCase.ExpectedUpdated -Because $TestCase.Name
                if ($null -eq $TestCase.ExpectedReleaseNotesUri) {
                    $result.ReleaseNotesUri | Should -BeNullOrEmpty -Because $TestCase.Name
                }
                else {
                    $result.ReleaseNotesUri | Should -Be $TestCase.ExpectedReleaseNotesUri -Because $TestCase.Name
                }
                if ($TestCase.ExpectedUpdateCalls -gt 0) {
                    Assert-MockCalled Invoke-NovaModuleSelfUpdate -Times $TestCase.ExpectedUpdateCalls
                }

                $script:releaseNotesLookupCount | Should -Be $TestCase.ExpectedReleaseNotesLookups
            }
        }
    }

    It 'Complete-NovaModuleSelfUpdateResult overwrites an existing release-notes property in place' {
        InModuleScope $script:moduleName {
            $plan = [pscustomobject]@{
                ModuleName = 'NovaModuleTools'
                UpdateAvailable = $true
                ReleaseNotesUri = 'https://old.example/release-notes'
            }

            $result = Complete-NovaModuleSelfUpdateResult -Plan $plan -ReleaseNotesUri 'https://www.novamoduletools.com/release-notes.html'

            $result.ReleaseNotesUri | Should -Be 'https://www.novamoduletools.com/release-notes.html'
            @($result.PSObject.Properties.Name | Where-Object {$_ -eq 'ReleaseNotesUri'}).Count | Should -Be 1
        }
    }

    It 'Update-NovaModuleTool delegates workflow context resolution and execution to private helpers' {
        InModuleScope $script:moduleName {
            Mock Get-NovaModuleSelfUpdateWorkflowContext {
                [pscustomobject]@{
                    Plan = [pscustomobject]@{
                        ModuleName = 'NovaModuleTools'
                        CurrentVersion = '1.0.0'
                        TargetVersion = '1.1.0'
                        PrereleaseNotificationsEnabled = $true
                        UpdateAvailable = $true
                        Updated = $false
                        Cancelled = $false
                        IsPrereleaseTarget = $false
                        UsedAllowPrerelease = $false
                    }
                    Action = 'Update NovaModuleTools to version 1.1.0'
                }
            }
            Mock Invoke-NovaModuleSelfUpdateWorkflow {
                $WorkflowContext.Plan | Add-Member -NotePropertyName 'ReleaseNotesUri' -NotePropertyValue 'https://www.novamoduletools.com/release-notes.html'
                $WorkflowContext.Plan.Updated = $true
                return $WorkflowContext.Plan
            }
            Mock Write-NovaModuleReleaseNotesLink {}

            $result = Update-NovaModuleTool -Confirm:$false

            $result.Updated | Should -BeTrue
            $result.ReleaseNotesUri | Should -Be 'https://www.novamoduletools.com/release-notes.html'
            Assert-MockCalled Get-NovaModuleSelfUpdateWorkflowContext -Times 1
            Assert-MockCalled Invoke-NovaModuleSelfUpdateWorkflow -Times 1 -ParameterFilter {
                $WorkflowContext.Action -eq 'Update NovaModuleTools to version 1.1.0' -and
                        $WorkflowContext.Plan.ModuleName -eq 'NovaModuleTools'
            }
            Assert-MockCalled Write-NovaModuleReleaseNotesLink -Times 1 -ParameterFilter {
                $ReleaseNotesUri -eq 'https://www.novamoduletools.com/release-notes.html'
            }
        }
    }

    It 'Update-NovaModuleTool returns the unchanged plan and skips update execution when WhatIf declines the update action' {
        InModuleScope $script:moduleName {
            Mock Get-NovaModuleSelfUpdateWorkflowContext {
                [pscustomobject]@{
                    Plan = [pscustomobject]@{
                        ModuleName = 'NovaModuleTools'
                        CurrentVersion = '1.0.0'
                        TargetVersion = '1.1.0'
                        PrereleaseNotificationsEnabled = $true
                        UpdateAvailable = $true
                        Updated = $false
                        Cancelled = $false
                        IsPrereleaseTarget = $false
                        UsedAllowPrerelease = $false
                    }
                    Action = 'Update NovaModuleTools to version 1.1.0'
                }
            }
            Mock Invoke-NovaModuleSelfUpdateWorkflow {throw 'should not update during WhatIf'}
            Mock Write-NovaModuleReleaseNotesLink {throw 'should not write release notes during WhatIf'}

            $result = Update-NovaModuleTool -WhatIf

            $result.UpdateAvailable | Should -BeTrue
            $result.Updated | Should -BeFalse
            $result.ReleaseNotesUri | Should -BeNullOrEmpty
            Assert-MockCalled Get-NovaModuleSelfUpdateWorkflowContext -Times 1
            Assert-MockCalled Invoke-NovaModuleSelfUpdateWorkflow -Times 0
            Assert-MockCalled Write-NovaModuleReleaseNotesLink -Times 0
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

    It 'Get-NovaUpdateSettingsFilePath keeps platform settings-root precedence explicit' {
        $configRoot = Join-Path $TestDrive 'config-shared-root'
        $appDataRoot = Join-Path $TestDrive 'appdata-shared-root'
        $originalConfigHome = $env:XDG_CONFIG_HOME
        $originalAppData = $env:APPDATA

        try {
            $env:XDG_CONFIG_HOME = $configRoot
            $env:APPDATA = $appDataRoot

            InModuleScope $script:moduleName -Parameters @{
                ExpectedPath = if ($IsWindows) {
                    Join-Path $appDataRoot 'NovaModuleTools/settings.json'
                }
                else {
                    Join-Path $configRoot 'NovaModuleTools/settings.json'
                }
            } {
                param($ExpectedPath)

                Get-NovaUpdateSettingsFilePath | Should -Be $ExpectedPath
            }
        }
        finally {
            $env:XDG_CONFIG_HOME = $originalConfigHome
            $env:APPDATA = $originalAppData
        }
    }

    It 'Get-NovaSettingsRootPath prefers APPDATA when the Windows platform branch is used' {
        $configRoot = Join-Path $TestDrive 'config-unused-root'
        $appDataRoot = Join-Path $TestDrive 'appdata-preferred-root'
        $originalConfigHome = $env:XDG_CONFIG_HOME
        $originalAppData = $env:APPDATA

        try {
            $env:XDG_CONFIG_HOME = $configRoot
            $env:APPDATA = $appDataRoot

            InModuleScope $script:moduleName -Parameters @{ExpectedRoot = $appDataRoot} {
                param($ExpectedRoot)

                Get-NovaSettingsRootPath -IsWindowsPlatform $true | Should -Be $ExpectedRoot
            }
        }
        finally {
            $env:XDG_CONFIG_HOME = $originalConfigHome
            $env:APPDATA = $originalAppData
        }
    }

    It 'Get-NovaSettingsRootPath falls back to HOME dot-config when environment roots are blank' {
        $originalConfigHome = $env:XDG_CONFIG_HOME
        $originalAppData = $env:APPDATA

        try {
            $env:XDG_CONFIG_HOME = '   '
            $env:APPDATA = '   '

            InModuleScope $script:moduleName -Parameters @{ExpectedRoot = (Join-Path $HOME '.config')} {
                param($ExpectedRoot)

                Get-NovaSettingsRootPath | Should -Be $ExpectedRoot
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

    It 'Invoke-NovaCli update prints a friendly message in PowerShell when no newer version is available' {
        InModuleScope $script:moduleName {
            Mock Update-NovaModuleTool {
                [pscustomobject]@{
                    ModuleName = 'NovaModuleTools'
                    CurrentVersion = '2.0.0-prerelease3'
                    TargetVersion = $null
                    LookupCandidateVersion = '2.0.0-beta'
                    LookupCandidateChannel = 'Prerelease'
                    LookupRepository = 'PSGallery'
                    PrereleaseNotificationsEnabled = $true
                    UpdateAvailable = $false
                    Updated = $false
                    Cancelled = $false
                    IsPrereleaseTarget = $false
                    UsedAllowPrerelease = $false
                }
            }

            $result = @(Invoke-NovaCli update)

            $result | Should -HaveCount 2
            $result[0] | Should -Be "You're up to date!"
            $result[1] | Should -Be 'NovaModuleTools 2.0.0-prerelease3 is currently the newest version available.'
            Assert-MockCalled Update-NovaModuleTool -Times 1
        }
    }

    It 'Get-NovaModuleUpdateLookupScript pins lookups to PSGallery and returns repository metadata' {
        InModuleScope $script:moduleName {
            $scriptText = Get-NovaModuleUpdateLookupScript

            $scriptText | Should -Match 'Find-Module \$ResolvedModuleName -Repository \$repositoryName'
            $scriptText | Should -Match 'Find-Module \$ResolvedModuleName -Repository \$repositoryName -AllowPrerelease'
            $scriptText | Should -Match 'SourceRepository = \$repositoryName'
            $scriptText | Should -Match 'Repository = \$repositoryName'
        }
    }

    It 'ConvertFrom-NovaUpdateCliArgument allows no arguments and rejects unsupported usage' {
        InModuleScope $script:moduleName {
            (ConvertFrom-NovaUpdateCliArgument).Count | Should -Be 0

            $unsupportedUsageError = $null
            try {
                ConvertFrom-NovaUpdateCliArgument -Arguments @('--bogus')
            }
            catch {
                $unsupportedUsageError = $_
            }

            $unsupportedUsageError | Should -Not -BeNullOrEmpty
            $unsupportedUsageError.Exception.Message | Should -BeLike "Unsupported 'nova update' usage*"
            $unsupportedUsageError.FullyQualifiedErrorId | Should -Be 'Nova.Validation.UnsupportedUpdateCliUsage'
            $unsupportedUsageError.CategoryInfo.Category | Should -Be ([System.Management.Automation.ErrorCategory]::InvalidArgument)
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

    It 'Invoke-NovaModuleSelfUpdate delegates through the self-update adapter with the resolved parameter map' {
        InModuleScope $script:moduleName {
            Mock Invoke-NovaModuleUpdateCommand {}

            Invoke-NovaModuleSelfUpdate -ModuleName 'NovaModuleTools' -AllowPrerelease

            Assert-MockCalled Invoke-NovaModuleUpdateCommand -Times 1 -ParameterFilter {
                $UpdateParameters.Name -eq 'NovaModuleTools' -and
                        $UpdateParameters.AllowPrerelease -and
                        $UpdateParameters.ErrorAction -eq 'Stop'
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

    It 'Get-NovaPrereleaseModuleUpdateConfirmationPrompt returns the expected caption and message text' {
        InModuleScope $script:moduleName {
            $prompt = Get-NovaPrereleaseModuleUpdateConfirmationPrompt -CurrentVersion '1.2.3' -TargetVersion '1.3.0-preview1'

            $prompt.Caption | Should -Be 'Confirm prerelease NovaModuleTools update'
            $prompt.Message | Should -Be @"
NovaModuleTools would update from 1.2.3 to prerelease 1.3.0-preview1.

Prerelease updates may be less stable than released versions.
Continue with the prerelease update?
"@
        }
    }

    It 'Confirm-NovaPrereleaseModuleUpdate delegates the generated prompt to ShouldContinue and returns the decision' {
        InModuleScope $script:moduleName {
            $calls = [System.Collections.Generic.List[object]]::new()
            $cmdlet = [pscustomobject]@{
                Calls = $calls
                ShouldContinueResult = $false
            }
            $cmdlet | Add-Member -MemberType ScriptMethod -Name ShouldContinue -Value {
                param($Message, $Caption)

                $this.Calls.Add([pscustomobject]@{
                    Message = $Message
                    Caption = $Caption
                }) | Out-Null
                return $this.ShouldContinueResult
            }

            $result = Confirm-NovaPrereleaseModuleUpdate -Cmdlet $cmdlet -CurrentVersion '1.2.3' -TargetVersion '2.0.0-preview2'

            $result | Should -BeFalse
            $calls.Count | Should -Be 1
            $calls[0].Caption | Should -Be 'Confirm prerelease NovaModuleTools update'
            $calls[0].Message | Should -Match '1.2.3'
            $calls[0].Message | Should -Match '2.0.0-preview2'
        }
    }

    It 'Invoke-NovaPowerShellScriptWithTimeout returns the first pipeline result and forwards arguments when the script completes' {
        $runner = New-TestPowerShellRunner -ShouldComplete:$true -EndInvokeResult @('first result', 'second result')

        InModuleScope $script:moduleName -Parameters @{Runner = $runner} {
            param($Runner)

            $result = Invoke-NovaPowerShellScriptWithTimeout -Script 'param($name, $flag)' -ArgumentList @('NovaModuleTools', $true) -TimeoutMilliseconds 321 -PowerShellFactory {$runner}

            $result | Should -Be 'first result'
            $Runner.State.Script | Should -Be 'param($name, $flag)'
            @($Runner.State.Arguments) | Should -Be @('NovaModuleTools', $true)
            $Runner.State.LastTimeoutMilliseconds | Should -Be 321
            $Runner.State.EndInvokeCalls | Should -Be 1
            $Runner.State.StopCalls | Should -Be 0
            $Runner.State.DisposeCalls | Should -Be 1
        }
    }

    It 'Invoke-NovaPowerShellScriptWithTimeout returns nothing and stops the pipeline when the timeout is exceeded' {
        $runner = New-TestPowerShellRunner -ShouldComplete:$false

        InModuleScope $script:moduleName -Parameters @{Runner = $runner} {
            param($Runner)

            $result = Invoke-NovaPowerShellScriptWithTimeout -Script 'Start-Sleep -Seconds 30' -TimeoutMilliseconds 25 -PowerShellFactory {$Runner}

            $result | Should -BeNullOrEmpty
            $Runner.State.LastTimeoutMilliseconds | Should -Be 25
            $Runner.State.StopCalls | Should -Be 1
            $Runner.State.EndInvokeCalls | Should -Be 0
            $Runner.State.DisposeCalls | Should -Be 1
        }
    }

    It 'Invoke-NovaPowerShellScriptWithTimeout swallows stop and EndInvoke failures and still disposes the pipeline' {
        $stopFailureRunner = New-TestPowerShellRunner -ShouldComplete:$false -ThrowOnStop
        $endFailureRunner = New-TestPowerShellRunner -ShouldComplete:$true -ThrowOnEndInvoke

        InModuleScope $script:moduleName -Parameters @{StopFailureRunner = $stopFailureRunner; EndFailureRunner = $endFailureRunner} {
            param($StopFailureRunner, $EndFailureRunner)

            $timedOutResult = Invoke-NovaPowerShellScriptWithTimeout -Script 'Start-Sleep -Seconds 30' -TimeoutMilliseconds 25 -PowerShellFactory {$StopFailureRunner}
            $endFailureResult = Invoke-NovaPowerShellScriptWithTimeout -Script 'throw' -PowerShellFactory {$EndFailureRunner}

            $timedOutResult | Should -BeNullOrEmpty
            $endFailureResult | Should -BeNullOrEmpty
            $StopFailureRunner.State.StopCalls | Should -Be 1
            $StopFailureRunner.State.DisposeCalls | Should -Be 1
            $EndFailureRunner.State.EndInvokeCalls | Should -Be 1
            $EndFailureRunner.State.DisposeCalls | Should -Be 1
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
        $result.Warnings[0] | Should -Match '% nova update'
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
        $result.Warnings[0] | Should -Match '% nova update'
        $result.Warnings[0] | Should -Match 'Set-NovaUpdateNotificationPreference -DisablePrereleaseNotifications'
        $result.Warnings[0] | Should -Match '% nova notification --disable'
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
                '% nova update'
            )
        }
    }

    It 'Write-NovaModuleReleaseNotesLink formats a provided release-notes URI for user-facing output' {
        InModuleScope $script:moduleName {
            $script:hostMessages = @()

            Mock Write-Host {$script:hostMessages += $Object}

            $message = Get-NovaModuleReleaseNotesMessage -ReleaseNotesUri 'https://www.novamoduletools.com/release-notes.html'
            Write-NovaModuleReleaseNotesLink -ReleaseNotesUri 'https://www.novamoduletools.com/release-notes.html'

            $message | Should -Be 'Release notes: https://www.novamoduletools.com/release-notes.html'
            $script:hostMessages | Should -Be @('Release notes: https://www.novamoduletools.com/release-notes.html')
        }
    }

    It 'Get-NovaModuleReleaseNotesMessage resolves the URI from the module parameter set' {
        InModuleScope $script:moduleName {
            Mock Get-NovaModuleReleaseNotesUri {'https://www.novamoduletools.com/release-notes.html'}

            $message = Get-NovaModuleReleaseNotesMessage -Module ([pscustomobject]@{Name = 'NovaModuleTools'})

            $message | Should -Be 'Release notes: https://www.novamoduletools.com/release-notes.html'
            Assert-MockCalled Get-NovaModuleReleaseNotesUri -Times 1
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
        $result.Result.ReleaseNotesUri | Should -Be 'https://www.novamoduletools.com/release-notes.html'
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
        $result.Result.ReleaseNotesUri | Should -Be 'https://www.novamoduletools.com/release-notes.html'
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
        $result.Result.ReleaseNotesUri | Should -BeNullOrEmpty
        $result.HostMessages | Should -HaveCount 0
    }

    It 'public self-update entrypoints stop on a structured self-update failure for <Name>' -ForEach @(
        @{
            Name = 'Update-NovaModuleTool'
            Invoke = {
                Update-NovaModuleTool -Confirm:$false
            }
        },
        @{
            Name = 'Invoke-NovaCli update'
            Invoke = {
                Invoke-NovaCli update
            }
        }
    ) {
        InModuleScope $script:moduleName -Parameters @{TestCase = $_} {
            param($TestCase)

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

            $thrown = $null
            try {
                & $TestCase.Invoke
            }
            catch {
                $thrown = $_
            }

            $thrown | Should -Not -BeNullOrEmpty
            $thrown.Exception.Message | Should -Be "Module 'NovaModuleTools' was not installed by using Install-Module, so it cannot be updated."
            $thrown.FullyQualifiedErrorId | Should -Be 'Nova.Dependency.ModuleSelfUpdateFailed'
            $thrown.CategoryInfo.Category | Should -Be ([System.Management.Automation.ErrorCategory]::InvalidOperation)
            $thrown.TargetObject | Should -Be 'NovaModuleTools'
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
            $commandHelp | Should -Not -Match 'nova update'
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
