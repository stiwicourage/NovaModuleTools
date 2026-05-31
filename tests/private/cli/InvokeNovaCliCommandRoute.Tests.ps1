BeforeAll {
    $projectRoot = Split-Path -Parent (Split-Path -Parent (Split-Path -Parent $PSScriptRoot))
    . (Join-Path $projectRoot 'src/private/cli/InvokeNovaCliCommandRoute.ps1')
    . (Join-Path $PSScriptRoot 'InvokeNovaCliCommandRoute.TestSupport.ps1')
}

Describe 'Confirm-NovaCliRoutedCommand' {
    It 'does nothing when CliConfirmEnabled is false' {
        Mock Confirm-NovaCliCommandAction {}
        Confirm-NovaCliRoutedCommand -InvocationContext (New-TestContext -CliConfirmEnabled $false) -Command 'build'
        Assert-MockCalled Confirm-NovaCliCommandAction -Times 0
    }
    It 'does nothing when WhatIfEnabled is true' {
        Mock Confirm-NovaCliCommandAction {}
        Confirm-NovaCliRoutedCommand -InvocationContext (New-TestContext -CliConfirmEnabled $true -WhatIfEnabled $true) -Command 'build'
        Assert-MockCalled Confirm-NovaCliCommandAction -Times 0
    }
    It 'does nothing when command is not mutating' {
        Mock Confirm-NovaCliCommandAction {}
        Confirm-NovaCliRoutedCommand -InvocationContext (New-TestContext -CliConfirmEnabled $true) -Command 'info'
        Assert-MockCalled Confirm-NovaCliCommandAction -Times 0
    }
    It 'invokes confirmation otherwise' {
        Mock Confirm-NovaCliCommandAction {}
        Confirm-NovaCliRoutedCommand -InvocationContext (New-TestContext -CliConfirmEnabled $true) -Command 'build'
        Assert-MockCalled Confirm-NovaCliCommandAction -Times 1
    }
}

Describe 'Invoke-NovaCliParsedCommand' {
    It 'parses arguments and forwards them with mutating parameters' {
        function Test-ParserCmd { param($Arguments) return @{Mode = 'Release'} }
        function Test-ActionCmd {
            param([string]$Mode, [switch]$WhatIf)
            return "Mode=$Mode WhatIf=$($WhatIf.IsPresent)"
        }
        $ctx = New-TestContext -Arguments @('--mode','Release') -MutatingCommonParameters @{WhatIf=$true}
        $result = Invoke-NovaCliParsedCommand -InvocationContext $ctx -ParserCommand 'Test-ParserCmd' -ActionCommand 'Test-ActionCmd'
        $result | Should -Be 'Mode=Release WhatIf=True'
    }
}

Describe 'Invoke-NovaCliTestRouteCommand' {
    It 'routes plain nova test to Invoke-NovaTest' {
        Mock ConvertFrom-NovaTestCliArgument { @{TagFilter = @('fast')} }
        Mock Invoke-NovaTest { param([string[]]$TagFilter, [switch]$WhatIf) "unit:$($TagFilter -join ','):$($WhatIf.IsPresent)" }
        Mock Test-NovaBuild {}

        $result = Invoke-NovaCliTestRouteCommand -InvocationContext (New-TestContext -Arguments @('--tag', 'fast') -MutatingCommonParameters @{WhatIf = $true})

        $result | Should -Be 'unit:fast:True'
        Assert-MockCalled Test-NovaBuild -Times 0
    }

    It 'routes nova test --build to Test-NovaBuild without forwarding the Build switch' {
        Mock ConvertFrom-NovaTestCliArgument { @{Build = $true; OverrideWarning = $true} }
        Mock Test-NovaBuild { param([switch]$OverrideWarning, [switch]$WhatIf) "integration:$($OverrideWarning.IsPresent):$($WhatIf.IsPresent)" }
        Mock Invoke-NovaTest {}

        $result = Invoke-NovaCliTestRouteCommand -InvocationContext (New-TestContext -Arguments @('--build') -MutatingCommonParameters @{WhatIf = $true})

        $result | Should -Be 'integration:True:True'
        Assert-MockCalled Invoke-NovaTest -Times 0
    }
}

Describe 'Read-NovaCliCapturedOutput' {
    It 'separates warning records from result' {
        $warn = [System.Management.Automation.WarningRecord]::new('hi')
        $captured = Read-NovaCliCapturedOutput -OutputRecords @($warn, 'value')
        $captured.Result | Should -Be 'value'
        $captured.WarningMessages.Count | Should -Be 1
    }
    It 'returns null result when only warnings' {
        $captured = Read-NovaCliCapturedOutput -OutputRecords @([System.Management.Automation.WarningRecord]::new('hi'))
        $captured.Result | Should -BeNullOrEmpty
        $captured.WarningMessages.Count | Should -Be 1
    }
    It 'handles empty inputs' {
        $captured = Read-NovaCliCapturedOutput
        $captured.Result | Should -BeNullOrEmpty
        $captured.WarningMessages.Count | Should -Be 0
    }
}

Describe 'ConvertTo-NovaCliWarningMessageText' {
    It 'extracts Message from WarningRecord' {
        ConvertTo-NovaCliWarningMessageText -WarningMessage ([System.Management.Automation.WarningRecord]::new('w!')) | Should -Be 'w!'
    }
    It 'stringifies other types' {
        ConvertTo-NovaCliWarningMessageText -WarningMessage 'plain' | Should -Be 'plain'
    }
}

Describe 'Get-NovaCliReplayWarningMessage' {
    It 'returns non-empty warning text' {
        $warn = [System.Management.Automation.WarningRecord]::new('first')
        $messages = Get-NovaCliReplayWarningMessage -WarningMessages @($warn, '', 'second')
        $messages | Should -Be @('first', 'second')
    }
}

Describe 'Write-NovaCliCapturedWarning' {
    It 'writes Write-Warning for each non-empty warning' {
        Mock Write-Warning {}
        Write-NovaCliCapturedWarning -WarningMessages @('a','b')
        Assert-MockCalled Write-Warning -Times 2
    }
}

Describe 'Invoke-NovaCliBumpCommand' {
    It 'replays captured warnings and returns the result' {
        Mock Invoke-NovaCliParsedCommand {
            Write-Warning 'w1'
            'bumped'
        }
        Mock Write-Warning {}
        $r = Invoke-NovaCliBumpCommand -InvocationContext (New-TestContext)
        $r | Should -Be 'bumped'
        Assert-MockCalled Write-Warning -Times 1
    }
}

Describe 'Invoke-NovaCliUpdateRouteCommand' {
    It 'forwards args/parameters to update command and formats the result' {
        Mock Invoke-NovaCliUpdateCommand { 'updated' }
        Mock Format-NovaCliCommandResult { param($Command, $Result) "fmt:$Result" }
        $r = Invoke-NovaCliUpdateRouteCommand -InvocationContext (New-TestContext -Command 'update')
        $r | Should -Be 'fmt:updated'
    }
}

Describe 'Invoke-NovaCliBumpRouteCommand' {
    It 'returns formatted bump result' {
        Mock Invoke-NovaCliBumpCommand { 'bumped' }
        Mock Format-NovaCliCommandResult { param($Command, $Result) "fmt:$Result" }
        Invoke-NovaCliBumpRouteCommand -InvocationContext (New-TestContext -Command 'bump') | Should -Be 'fmt:bumped'
    }
}

Describe 'Invoke-NovaCliNotificationRouteCommand' {
    It 'delegates to Invoke-NovaCliNotificationCommand' {
        Mock Invoke-NovaCliNotificationCommand {}
        Invoke-NovaCliNotificationRouteCommand -InvocationContext (New-TestContext -Command 'notification')
        Assert-MockCalled Invoke-NovaCliNotificationCommand -Times 1
    }
}

Describe 'Invoke-NovaCliInstalledVersionCommand' {
    It 'returns formatted installed version string' {
        Mock Get-NovaCliInstalledVersion { [version]'1.2.3' }
        Mock Format-NovaCliVersionString { param($Name, $Version) "$Name $Version" }
        Invoke-NovaCliInstalledVersionCommand -InvocationContext (New-TestContext) | Should -Be 'NovaModuleTools 1.2.3'
    }
}

Describe 'Invoke-NovaCliCommandRoute' {
    It 'returns root help when help target is Root' {
        Mock Get-NovaCliHelp { 'root-help' }
        $ctx = New-TestContext -IsHelpRequest $true -HelpRequest ([pscustomobject]@{TargetType='Root'; Command=''; View='Short'})
        Invoke-NovaCliCommandRoute -InvocationContext $ctx | Should -Be 'root-help'
    }

    It 'returns command help when help target is Command' {
        Mock Get-NovaCliCommandHelp { param($Command, $View) "help:${Command}:${View}" }
        $ctx = New-TestContext -IsHelpRequest $true -HelpRequest ([pscustomobject]@{TargetType='Command'; Command='package'; View='Long'})
        Invoke-NovaCliCommandRoute -InvocationContext $ctx | Should -Be 'help:package:Long'
    }

    It 'dispatches info to Get-NovaProjectInfo' {
        Mock Get-NovaProjectInfo { 'info' }
        Mock Confirm-NovaCliRoutedCommand {}
        Invoke-NovaCliCommandRoute -InvocationContext (New-TestContext -Command 'info') | Should -Be 'info'
    }

    It 'dispatches version' {
        Mock Invoke-NovaCliVersionCommand { 'v' }
        Mock Confirm-NovaCliRoutedCommand {}
        Invoke-NovaCliCommandRoute -InvocationContext (New-TestContext -Command 'version') | Should -Be 'v'
    }

    It 'dispatches build through parsed command pipeline' {
        Mock Invoke-NovaCliParsedCommand { 'built' }
        Mock Confirm-NovaCliRoutedCommand {}
        Invoke-NovaCliCommandRoute -InvocationContext (New-TestContext -Command 'build') | Should -Be 'built'
        Assert-MockCalled Invoke-NovaCliParsedCommand -Times 1 -ParameterFilter {$ParserCommand -eq 'ConvertFrom-NovaBuildCliArgument' -and $ActionCommand -eq 'Invoke-NovaBuild'}
    }

    It 'dispatches test through the dedicated test router' {
        Mock Invoke-NovaCliTestRouteCommand { 'tested' }
        Mock Confirm-NovaCliRoutedCommand {}
        Invoke-NovaCliCommandRoute -InvocationContext (New-TestContext -Command 'test') | Should -Be 'tested'
    }

    It 'dispatches package' {
        Mock Invoke-NovaCliParsedCommand { 'pkg' }
        Mock Confirm-NovaCliRoutedCommand {}
        Invoke-NovaCliCommandRoute -InvocationContext (New-TestContext -Command 'package') | Should -Be 'pkg'
    }

    It 'dispatches deploy' {
        Mock Invoke-NovaCliDeployCommand { 'deployed' }
        Mock Confirm-NovaCliRoutedCommand {}
        Invoke-NovaCliCommandRoute -InvocationContext (New-TestContext -Command 'deploy') | Should -Be 'deployed'
    }

    It 'dispatches init' {
        Mock Invoke-NovaCliInitCommand { 'init' }
        Mock Confirm-NovaCliRoutedCommand {}
        Invoke-NovaCliCommandRoute -InvocationContext (New-TestContext -Command 'init') | Should -Be 'init'
    }

    It 'dispatches copilot' {
        Mock Invoke-NovaCliCopilotCommand {'copilot'}
        Mock Confirm-NovaCliRoutedCommand {}
        Invoke-NovaCliCommandRoute -InvocationContext (New-TestContext -Command 'copilot') | Should -Be 'copilot'
    }

    It 'dispatches bump' {
        Mock Invoke-NovaCliBumpRouteCommand { 'bumped' }
        Mock Confirm-NovaCliRoutedCommand {}
        Invoke-NovaCliCommandRoute -InvocationContext (New-TestContext -Command 'bump') | Should -Be 'bumped'
    }

    It 'dispatches update' {
        Mock Invoke-NovaCliUpdateRouteCommand { 'updated' }
        Mock Confirm-NovaCliRoutedCommand {}
        Invoke-NovaCliCommandRoute -InvocationContext (New-TestContext -Command 'update') | Should -Be 'updated'
    }

    It 'dispatches publish and release through parsed command pipeline' {
        Mock Invoke-NovaCliParsedCommand { 'p-or-r' }
        Mock Confirm-NovaCliRoutedCommand {}
        Invoke-NovaCliCommandRoute -InvocationContext (New-TestContext -Command 'publish') | Should -Be 'p-or-r'
        Invoke-NovaCliCommandRoute -InvocationContext (New-TestContext -Command 'release') | Should -Be 'p-or-r'
    }

    It 'dispatches notification' {
        Mock Invoke-NovaCliNotificationRouteCommand { 'notif' }
        Mock Confirm-NovaCliRoutedCommand {}
        Invoke-NovaCliCommandRoute -InvocationContext (New-TestContext -Command 'notification') | Should -Be 'notif'
    }

    It 'dispatches --version' {
        Mock Invoke-NovaCliInstalledVersionCommand { 'v1' }
        Mock Confirm-NovaCliRoutedCommand {}
        Invoke-NovaCliCommandRoute -InvocationContext (New-TestContext -Command '--version') | Should -Be 'v1'
    }

    It 'dispatches --help' {
        Mock Get-NovaCliHelp { 'help' }
        Mock Confirm-NovaCliRoutedCommand {}
        Invoke-NovaCliCommandRoute -InvocationContext (New-TestContext -Command '--help') | Should -Be 'help'
    }

    It 'throws on unknown command' {
        Mock Confirm-NovaCliRoutedCommand {}
        $record = $null

        try {
            Invoke-NovaCliCommandRoute -InvocationContext (New-TestContext -Command 'bogus')
        } catch {
            $record = $_
        }

        $record | Should -Not -BeNullOrEmpty
        $record.FullyQualifiedErrorId | Should -Be 'Nova.Validation.UnknownCliCommand'
        $record.Exception.Message | Should -Be "Unknown nova command: bogus. Run 'nova --help' to list available commands, or 'nova --help <command>' for command-specific help."
    }
}
