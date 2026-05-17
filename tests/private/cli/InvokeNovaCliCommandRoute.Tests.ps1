BeforeAll {
    $projectRoot = Split-Path -Parent (Split-Path -Parent (Split-Path -Parent $PSScriptRoot))
    . (Join-Path $projectRoot 'src/private/cli/InvokeNovaCliCommandRoute.ps1')

    function Stop-NovaOperation {
        param([string]$Message, [string]$ErrorId, [System.Management.Automation.ErrorCategory]$Category, $TargetObject)
        $exception = [System.Exception]::new($Message)
        $record = [System.Management.Automation.ErrorRecord]::new($exception, $ErrorId, $Category, $TargetObject)
        throw $record
    }
    function Test-NovaCliMutatingCommand {param([string]$Command); return @('build','test','package','deploy','bump','update','notification','publish','release') -contains $Command}
    function Confirm-NovaCliCommandAction {param([string]$Command)}
    function Get-NovaCliHelp {}
    function Get-NovaCliCommandHelp {param([string]$Command, [string]$View)}
    function Get-NovaProjectInfo {}
    function Invoke-NovaCliVersionCommand {param($Arguments, $ForwardedParameters)}
    function Invoke-NovaCliDeployCommand {param($Arguments, $ForwardedParameters)}
    function Invoke-NovaCliInitCommand {param($Arguments, $ForwardedParameters, [switch]$WhatIfEnabled)}
    function Invoke-NovaCliUpdateCommand {param($Arguments, $ForwardedParameters)}
    function Invoke-NovaCliNotificationCommand {param($Arguments, $CommonParameters, $MutatingCommonParameters)}
    function Get-NovaCliInstalledVersion {}
    function Format-NovaCliVersionString {param([string]$Name, $Version)}
    function Format-NovaCliCommandResult {param([string]$Command, $Result); return $Result}
    function ConvertFrom-NovaBumpCliArgument {param($Arguments)}
    function ConvertFrom-NovaBuildCliArgument {param($Arguments)}
    function ConvertFrom-NovaTestCliArgument {param($Arguments)}
    function ConvertFrom-NovaPackageCliArgument {param($Arguments)}
    function ConvertFrom-NovaCliArgument {param($Arguments)}
    function Update-NovaModuleVersion {}
    function Invoke-NovaBuild {}
    function Test-NovaBuild {}
    function New-NovaModulePackage {}
    function Publish-NovaModule {}
    function Invoke-NovaRelease {}
    function New-TestContext {
        param(
            [string]$Command = 'info',
            [object[]]$Arguments = @(),
            [hashtable]$CommonParameters = @{},
            [hashtable]$MutatingCommonParameters = @{},
            [bool]$IsHelpRequest = $false,
            [pscustomobject]$HelpRequest = $null,
            [string]$ModuleName = 'NovaModuleTools',
            [bool]$WhatIfEnabled = $false,
            [bool]$CliConfirmEnabled = $false
        )
        return [pscustomobject]@{
            Command = $Command
            Arguments = $Arguments
            CommonParameters = $CommonParameters
            MutatingCommonParameters = $MutatingCommonParameters
            IsHelpRequest = $IsHelpRequest
            HelpRequest = $HelpRequest
            ModuleName = $ModuleName
            WhatIfEnabled = $WhatIfEnabled
            CliConfirmEnabled = $CliConfirmEnabled
        }
    }
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

    It 'dispatches test through parsed command pipeline' {
        Mock Invoke-NovaCliParsedCommand { 'tested' }
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
        {Invoke-NovaCliCommandRoute -InvocationContext (New-TestContext -Command 'bogus')} | Should -Throw -ErrorId 'Nova.Validation.UnknownCliCommand'
    }
}
