$script:gitTestSupportPath = (Resolve-Path -LiteralPath (Join-Path $PSScriptRoot 'GitTestSupport.ps1')).Path
$script:coverageGapsCliTestSupportPath = (Resolve-Path -LiteralPath (Join-Path $PSScriptRoot 'CoverageGaps.Cli.TestSupport.ps1')).Path
$global:gitTestSupportFunctionNameList = @(
    'Initialize-TestGitRepository'
    'New-TestGitCommit'
    'New-TestGitTag'
)
$global:coverageGapsCliTestSupportFunctionNameList = @(
    'Assert-TestStructuredCliError'
    'Resolve-TestPublicDocsUrl'
    'Assert-TestPublicDocsUrlExists'
    'Get-TestNovaCliRoutedParserCaseList'
    'Get-TestNovaCliContinuousIntegrationRouteCaseList'
    'Get-TestNovaCliNormalizedRootCommandCaseList'
    'Get-TestNovaCliOptionClassificationCaseList'
    'Get-TestNovaCliSyntaxGuidanceCaseList'
)
. $script:gitTestSupportPath
. $script:coverageGapsCliTestSupportPath

foreach ($functionName in $global:gitTestSupportFunctionNameList) {
    $scriptBlock = (Get-Command -Name $functionName -CommandType Function -ErrorAction Stop).ScriptBlock
    Set-Item -Path "function:global:$functionName" -Value $scriptBlock
}
foreach ($functionName in $global:coverageGapsCliTestSupportFunctionNameList) {
    $scriptBlock = (Get-Command -Name $functionName -CommandType Function -ErrorAction Stop).ScriptBlock
    Set-Item -Path "function:global:$functionName" -Value $scriptBlock
}

BeforeAll {
    $here = Split-Path -Parent $PSCommandPath
    $gitTestSupportPath = (Resolve-Path -LiteralPath (Join-Path $PSScriptRoot 'GitTestSupport.ps1')).Path
    $coverageGapsCliTestSupportPath = (Resolve-Path -LiteralPath (Join-Path $PSScriptRoot 'CoverageGaps.Cli.TestSupport.ps1')).Path
    $script:repoRoot = Split-Path -Parent $here
    $script:moduleName = (Get-Content -LiteralPath (Join-Path $script:repoRoot 'project.json') -Raw | ConvertFrom-Json).ProjectName
    $script:distModuleDir = Join-Path $script:repoRoot "dist/$script:moduleName"

    if (-not (Test-Path -LiteralPath $script:distModuleDir)) {
        throw "Expected built $script:moduleName module at: $script:distModuleDir. Run Invoke-NovaBuild in the repo root first."
    }

    . $gitTestSupportPath
    . $coverageGapsCliTestSupportPath
    foreach ($functionName in $global:gitTestSupportFunctionNameList) {
        $scriptBlock = (Get-Command -Name $functionName -CommandType Function -ErrorAction Stop).ScriptBlock
        Set-Item -Path "function:global:$functionName" -Value $scriptBlock
    }
    foreach ($functionName in $global:coverageGapsCliTestSupportFunctionNameList) {
        $scriptBlock = (Get-Command -Name $functionName -CommandType Function -ErrorAction Stop).ScriptBlock
        Set-Item -Path "function:global:$functionName" -Value $scriptBlock
    }

    Remove-Module $script:moduleName -ErrorAction SilentlyContinue
    Import-Module $script:distModuleDir -Force
}

Describe 'Coverage gaps for CLI and installed-version internals' {
    It 'Get-NovaCliInvocationContext resolves forwarded parameter sets, normalized arguments, and help detection' {
        InModuleScope $script:moduleName {
            Mock Get-NovaCliForwardingParameterSet {
                if ($IncludeShouldProcess) {
                    return @{WhatIf = $true}
                }

                return @{Verbose = $true}
            }
            Mock ConvertTo-NovaCliArgumentArray {@('--help')}
            Mock Get-NovaCliHelpRequest {
                [pscustomobject]@{
                    Command = 'publish'
                    View = 'Short'
                    TargetType = 'Command'
                    IsHelpRequest = $true
                }
            }
            Mock Assert-NovaCliArgumentSyntax {}

            $result = Get-NovaCliInvocationContext -InvocationRequest ([pscustomobject]@{
                Command = 'publish'
                BoundParameters = @{Verbose = $true; Arguments = @('--help')}
                Arguments = @('--help')
            }) -WhatIfEnabled

            $result.Command | Should -Be 'publish'
            $result.Arguments | Should -Be @()
            $result.CommonParameters.Verbose | Should -BeTrue
            $result.MutatingCommonParameters.WhatIf | Should -BeTrue
            $result.IsHelpRequest | Should -BeTrue
            $result.HelpRequest.View | Should -Be 'Short'
            $result.HelpRequest.TargetType | Should -Be 'Command'
            $result.ModuleName | Should -Be 'NovaModuleTools'
            $result.WhatIfEnabled | Should -BeTrue
            $result.CliConfirmEnabled | Should -BeFalse
            Assert-MockCalled Get-NovaCliForwardingParameterSet -Times 1 -ParameterFilter {
                $BoundParameters.ContainsKey('Verbose') -and -not $IncludeShouldProcess
            }
            Assert-MockCalled Get-NovaCliForwardingParameterSet -Times 1 -ParameterFilter {
                $BoundParameters.ContainsKey('Verbose') -and $IncludeShouldProcess
            }
        }
    }

    It 'Invoke-NovaCliCommandRoute returns routed command help when the invocation requests help' {
        InModuleScope $script:moduleName {
            $invocationContext = [pscustomobject]@{
                Command = 'package'
                Arguments = @()
                CommonParameters = @{}
                MutatingCommonParameters = @{}
                IsHelpRequest = $true
                HelpRequest = [pscustomobject]@{
                    Command = 'package'
                    View = 'Long'
                    TargetType = 'Command'
                }
                ModuleName = 'NovaModuleTools'
                WhatIfEnabled = $false
            }
            Mock Get-NovaCliCommandHelp {'package-help'}

            $result = Invoke-NovaCliCommandRoute -InvocationContext $invocationContext

            $result | Should -Be 'package-help'
            Assert-MockCalled Get-NovaCliCommandHelp -Times 1 -ParameterFilter {$Command -eq 'package' -and $View -eq 'Long'}
        }
    }

    It 'Format-NovaCliCommandResult renders structured bump results as a stable CLI summary' {
        InModuleScope $script:moduleName {
            $versionUpdateResult = [pscustomobject]@{
                PreviousVersion = '1.0.0'
                NewVersion = '1.1.0-preview'
                Label = 'Minor'
                CommitCount = 2
                Applied = $false
            }
            $result = Format-NovaCliCommandResult -Command 'bump' -Result $versionUpdateResult

            $result | Should -Be 'Version plan: 1.0.0 -> 1.1.0-preview | Label: Minor | Commits: 2'
        }
    }

    It 'Format-NovaCliCommandResult renders applied bump results as a completed CLI summary' {
        InModuleScope $script:moduleName {
            $versionUpdateResult = [pscustomobject]@{
                PreviousVersion = '1.0.0'
                NewVersion = '1.1.0'
                Label = 'Minor'
                CommitCount = 2
                Applied = $true
            }

            $result = Format-NovaCliCommandResult -Command 'bump' -Result $versionUpdateResult

            $result | Should -Be 'Version bump completed: 1.0.0 -> 1.1.0 | Label: Minor | Commits: 2'
        }
    }

    It 'Invoke-NovaCliCommandRoute formats bump results through the shared CLI formatter' {
        InModuleScope $script:moduleName {
            $invocationContext = [pscustomobject]@{
                Command = 'bump'
                Arguments = @('--preview')
                CommonParameters = @{}
                MutatingCommonParameters = @{WhatIf = $true}
                IsHelpRequest = $false
                HelpRequest = $null
                ModuleName = 'NovaModuleTools'
                WhatIfEnabled = $true
                CliConfirmEnabled = $false
            }
            Mock ConvertFrom-NovaBumpCliArgument {@{Preview = $true}}
            Mock Update-NovaModuleVersion {
                [pscustomobject]@{
                    PreviousVersion = '1.0.0'
                    NewVersion = '1.1.0-preview'
                    Label = 'Minor'
                    CommitCount = 2
                    Applied = $false
                }
            }

            $result = Invoke-NovaCliCommandRoute -InvocationContext $invocationContext

            $result | Should -Be 'Version plan: 1.0.0 -> 1.1.0-preview | Label: Minor | Commits: 2'
            Assert-MockCalled ConvertFrom-NovaBumpCliArgument -Times 1 -ParameterFilter {$Arguments -eq @('--preview')}
            Assert-MockCalled Update-NovaModuleVersion -Times 1 -ParameterFilter {$Preview -and $WhatIf}
        }
    }

    It 'Invoke-NovaCliCommandRoute handles the direct root --help command route when help was not pre-normalized' {
        InModuleScope $script:moduleName {
            $invocationContext = [pscustomobject]@{
                Command = '--help'
                Arguments = @()
                CommonParameters = @{}
                MutatingCommonParameters = @{}
                IsHelpRequest = $false
                HelpRequest = $null
                ModuleName = 'NovaModuleTools'
                WhatIfEnabled = $false
                CliConfirmEnabled = $false
            }
            Mock Get-NovaCliHelp {'root-help'}
            Mock Get-NovaCliCommandHelp {throw 'command help should not be used'}

            $result = Invoke-NovaCliCommandRoute -InvocationContext $invocationContext

            $result | Should -Be 'root-help'
            Assert-MockCalled Get-NovaCliHelp -Times 1
            Assert-MockCalled Get-NovaCliCommandHelp -Times 0
        }
    }

    It 'Get-NovaCliCommandHandler returns the mapped handler for a known command' {
        InModuleScope $script:moduleName {
            $expectedHandler = [pscustomobject]@{Name = 'publish-handler'}
            $handlerMap = @{publish = $expectedHandler}

            $result = Get-NovaCliCommandHandler -CommandHandlerMap $handlerMap -Command 'publish'

            $result | Should -Be $expectedHandler
        }
    }

    It 'Get-NovaCliHelpRequest resolves root short help, command short help, and command long help' {
        InModuleScope $script:moduleName {
            $rootHelp = Get-NovaCliHelpRequest -Command '--help' -Arguments @()
            $shortHelp = Get-NovaCliHelpRequest -Command 'build' -Arguments @('-h')
            $longHelp = Get-NovaCliHelpRequest -Command '-h' -Arguments @('build')

            $rootHelp.TargetType | Should -Be 'Root'
            $rootHelp.View | Should -Be 'Short'
            $shortHelp.Command | Should -Be 'build'
            $shortHelp.View | Should -Be 'Short'
            $longHelp.Command | Should -Be 'build'
            $longHelp.View | Should -Be 'Long'
        }
    }

    It 'Invoke-NovaCli delegates invocation preparation and routing to private helpers' {
        InModuleScope $script:moduleName {
            Mock Get-NovaCliInvocationContext {
                [pscustomobject]@{
                    Command = 'build'
                    Arguments = @()
                    CommonParameters = @{}
                    MutatingCommonParameters = @{WhatIf = $true}
                    IsHelpRequest = $false
                    ModuleName = 'NovaModuleTools'
                    WhatIfEnabled = $true
                }
            }
            Mock Invoke-NovaCliCommandRoute {'delegated-build'}

            $result = Invoke-NovaCli build -WhatIf

            $result | Should -Be 'delegated-build'
            Assert-MockCalled Get-NovaCliInvocationContext -Times 1 -ParameterFilter {
                $InvocationRequest.Command -eq 'build' -and
                        $InvocationRequest.BoundParameters.ContainsKey('WhatIf') -and
                        $WhatIfEnabled
            }
            Assert-MockCalled Invoke-NovaCliCommandRoute -Times 1 -ParameterFilter {
                $InvocationContext.Command -eq 'build' -and $InvocationContext.WhatIfEnabled
            }
        }
    }

    It 'Get-NovaCliInvocationContext normalizes explicit root and routed GNU-style options correctly' {
        InModuleScope $script:moduleName {
            $rootContext = Get-NovaCliInvocationContext -InvocationRequest ([pscustomobject]@{
                Command = '-v'
                BoundParameters = @{Command = '-v'}
                Arguments = @()
            })
            $buildContext = Get-NovaCliInvocationContext -InvocationRequest ([pscustomobject]@{
                Command = 'build'
                BoundParameters = @{Command = 'build'; Arguments = @('-v', '-w', '-c')}
                Arguments = @('-v', '-w', '-c')
            })

            $rootContext.Command | Should -Be '--version'
            $rootContext.Arguments | Should -Be @()
            $buildContext.Command | Should -Be 'build'
            $buildContext.Arguments | Should -Be @()
            $buildContext.CommonParameters.Verbose | Should -BeTrue
            $buildContext.MutatingCommonParameters.Verbose | Should -BeTrue
            $buildContext.MutatingCommonParameters.WhatIf | Should -BeTrue
            $buildContext.MutatingCommonParameters.ContainsKey('Confirm') | Should -BeFalse
            $buildContext.WhatIfEnabled | Should -BeTrue
            $buildContext.CliConfirmEnabled | Should -BeTrue
        }
    }

    It 'Get-NovaCliArgumentRoutingState enables CLI confirmation only for supported mutating commands' {
        InModuleScope $script:moduleName {
            $supportedCommandList = @('build', 'test', 'package', 'deploy', 'bump', 'update', 'notification', 'publish', 'release')

            foreach ($command in $supportedCommandList) {
                foreach ($option in @('--confirm', '-c')) {
                    $state = Get-NovaCliArgumentRoutingState -Command $command -Arguments @($option)

                    $state.Command | Should -Be $command
                    $state.Arguments | Should -Be @()
                    $state.CliConfirmEnabled | Should -BeTrue
                    $state.ForwardedParameters.ContainsKey('Confirm') | Should -BeFalse
                }
            }
        }
    }

    It 'Get-NovaCliArgumentRoutingState rejects CLI confirmation for non-confirmable commands' {
        InModuleScope $script:moduleName {
            foreach ($command in @('--help', '--version', 'info', 'version', 'init')) {
                foreach ($option in @('--confirm', '-c')) {
                    $thrown = $null
                    try {
                        Get-NovaCliArgumentRoutingState -Command $command -Arguments @($option)
                    }
                    catch {
                        $thrown = $_
                    }

                    Assert-TestStructuredCliError -ThrownError $thrown -ExpectedError ([pscustomobject]@{
                        Message = "The 'nova $command' CLI command does not support '--confirm'/'-c'."
                        ErrorId = 'Nova.Validation.UnsupportedCliConfirm'
                        Category = [System.Management.Automation.ErrorCategory]::InvalidOperation
                        TargetObject = 'Confirm'
                    })
                }
            }
        }
    }

    It 'Get-NovaCliInvocationContext rejects legacy PowerShell-style CLI options passed through routed arguments' {
        InModuleScope $script:moduleName {
            $thrown = $null
            try {
                Get-NovaCliInvocationContext -InvocationRequest ([pscustomobject]@{
                    Command = 'build'
                    BoundParameters = @{Command = 'build'; Arguments = @('-Verbose')}
                    Arguments = @('-Verbose')
                })
            }
            catch {
                $thrown = $_
            }

            Assert-TestStructuredCliError -ThrownError $thrown -ExpectedError ([pscustomobject]@{
                Message = "Unsupported CLI option syntax: -Verbose. Use '--verbose' or '-v' instead."
                ErrorId = 'Nova.Validation.UnsupportedCliOptionSyntax'
                Category = [System.Management.Automation.ErrorCategory]::InvalidArgument
                TargetObject = '-Verbose'
            })
        }
    }

    It 'Invoke-NovaCli dispatches the remaining public command branches' {
        InModuleScope $script:moduleName {
            Mock Get-NovaProjectInfo {'info-value'} -ParameterFilter {-not $Version}
            Mock Invoke-NovaBuild {'build-value'}
            Mock Test-NovaBuild {'test-value'}
            Mock Get-NovaUpdateNotificationPreference {[pscustomobject]@{Mode = 'status'}}
            Mock Set-NovaUpdateNotificationPreference {
                [pscustomobject]@{
                    Enabled = $EnablePrereleaseNotifications.IsPresent
                    Disabled = $DisablePrereleaseNotifications.IsPresent
                }
            }
            Mock Initialize-NovaModule {
                param([string]$Path, [switch]$Example)
                if ($Example) {
                    if ( $PSBoundParameters.ContainsKey('Path')) {
                        return "init-example:$Path"
                    }

                    return 'init-example-default'
                }

                if ( $PSBoundParameters.ContainsKey('Path')) {
                    return "init:$Path"
                }

                return 'init-default'
            }
            Mock Update-NovaModuleVersion {'bump-value'}
            Mock Invoke-NovaRelease {$PublishOption}

            Invoke-NovaCli info | Should -Be 'info-value'
            Invoke-NovaCli build | Should -Be 'build-value'
            Invoke-NovaCli test | Should -Be 'test-value'
            Invoke-NovaCli init | Should -Be 'init-default'
            Invoke-NovaCli -Command init -Arguments @('--path', '/tmp/demo') | Should -Be 'init:/tmp/demo'
            Invoke-NovaCli -Command init -Arguments @('--example') | Should -Be 'init-example-default'
            Invoke-NovaCli -Command init -Arguments @('--example', '--path', '/tmp/demo') | Should -Be 'init-example:/tmp/demo'
            Invoke-NovaCli bump | Should -Be 'bump-value'
            Invoke-NovaCli bump --preview | Should -Be 'bump-value'
            (Invoke-NovaCli notification).Mode | Should -Be 'status'
            (Invoke-NovaCli notification --disable).Disabled | Should -BeTrue
            (Invoke-NovaCli notification --enable).Enabled | Should -BeTrue
            (Invoke-NovaCli release --repository PSGallery --api-key key123).Repository | Should -Be 'PSGallery'

            Assert-MockCalled Update-NovaModuleVersion -Times 1 -ParameterFilter {-not $Preview}
            Assert-MockCalled Update-NovaModuleVersion -Times 1 -ParameterFilter {$Preview}
        }
    }

    It 'routed CLI parsers accept supported switches and reject unsupported arguments' {
        foreach ($testCase in (Get-TestNovaCliRoutedParserCaseList)) {
            InModuleScope $script:moduleName -Parameters @{TestCase = $testCase} {
                param($TestCase)

                foreach ($validCase in $TestCase.ValidCases) {
                    $options = & $TestCase.ParserCommand -Arguments $validCase.Arguments
                    $options[$validCase.Property] | Should -BeTrue
                }

                $unknownArgumentError = $null
                try {
                    & $TestCase.ParserCommand -Arguments @('--bogus')
                }
                catch {
                    $unknownArgumentError = $_
                }

                Assert-TestStructuredCliError -ThrownError $unknownArgumentError -ExpectedError ([pscustomobject]@{
                    Message = 'Unknown argument: --bogus'
                    ErrorId = 'Nova.Validation.UnknownCliArgument'
                    Category = [System.Management.Automation.ErrorCategory]::InvalidArgument
                    TargetObject = '--bogus'
                })
            }
        }
    }

    It 'ConvertFrom-NovaInitCliArgument parses explicit path and example switches' {
        InModuleScope $script:moduleName {
            $options = ConvertFrom-NovaInitCliArgument -Arguments @('--example', '--path', 'tmp/project/root')

            $options.Example | Should -BeTrue
            $options.Path | Should -Be 'tmp/project/root'
        }
    }

    It 'the migrated CLI parsers expose structured validation errors for invalid usage cases' -ForEach @(
        [pscustomobject]@{
            CommandName = 'ConvertFrom-NovaInitCliArgument'
            Arguments = @('some/path')
            ExpectedError = [pscustomobject]@{
                Message = "Unsupported 'nova init' usage*"
                ErrorId = 'Nova.Validation.UnsupportedInitCliUsage'
                Category = [System.Management.Automation.ErrorCategory]::InvalidArgument
                TargetObject = 'some/path'
            }
        },
        [pscustomobject]@{
            CommandName = 'ConvertFrom-NovaInitCliArgument'
            Arguments = @('--path')
            ExpectedError = [pscustomobject]@{
                Message = 'Missing value for --path'
                ErrorId = 'Nova.Validation.MissingCliOptionValue'
                Category = [System.Management.Automation.ErrorCategory]::InvalidArgument
                TargetObject = '--path'
            }
        },
        [pscustomobject]@{
            CommandName = 'ConvertFrom-NovaInitCliArgument'
            Arguments = @('--bogus')
            ExpectedError = [pscustomobject]@{
                Message = 'Unknown argument: --bogus'
                ErrorId = 'Nova.Validation.UnknownCliArgument'
                Category = [System.Management.Automation.ErrorCategory]::InvalidArgument
                TargetObject = '--bogus'
            }
        },
        [pscustomobject]@{
            CommandName = 'ConvertFrom-NovaNotificationCliArgument'
            Arguments = @('--enable', '--disable')
            ExpectedError = [pscustomobject]@{
                Message = "Unsupported 'nova notification' usage*"
                ErrorId = 'Nova.Validation.UnsupportedNotificationCliUsage'
                Category = [System.Management.Automation.ErrorCategory]::InvalidArgument
            }
        },
        [pscustomobject]@{
            CommandName = 'ConvertFrom-NovaNotificationCliArgument'
            Arguments = @('--bogus')
            ExpectedError = [pscustomobject]@{
                Message = 'Unknown argument: --bogus'
                ErrorId = 'Nova.Validation.UnknownCliArgument'
                Category = [System.Management.Automation.ErrorCategory]::InvalidArgument
                TargetObject = '--bogus'
            }
        },
        [pscustomobject]@{
            CommandName = 'ConvertFrom-NovaDeployCliArgument'
            Arguments = @('--url')
            ExpectedError = [pscustomobject]@{
                Message = 'Missing value for --url'
                ErrorId = 'Nova.Validation.MissingCliOptionValue'
                Category = [System.Management.Automation.ErrorCategory]::InvalidArgument
                TargetObject = '--url'
            }
        },
        [pscustomobject]@{
            CommandName = 'ConvertFrom-NovaDeployCliArgument'
            Arguments = @('--bogus')
            ExpectedError = [pscustomobject]@{
                Message = 'Unknown argument: --bogus'
                ErrorId = 'Nova.Validation.UnknownCliArgument'
                Category = [System.Management.Automation.ErrorCategory]::InvalidArgument
                TargetObject = '--bogus'
            }
        }
    ) {
        InModuleScope $script:moduleName -Parameters @{TestCase = $_} {
            param($TestCase)

            $thrown = $null
            try {
                switch ($TestCase.CommandName) {
                    'ConvertFrom-NovaInitCliArgument' {
                        ConvertFrom-NovaInitCliArgument -Arguments $TestCase.Arguments
                    }
                    'ConvertFrom-NovaNotificationCliArgument' {
                        ConvertFrom-NovaNotificationCliArgument -Arguments $TestCase.Arguments
                    }
                    'ConvertFrom-NovaDeployCliArgument' {
                        ConvertFrom-NovaDeployCliArgument -Arguments $TestCase.Arguments
                    }
                }
            }
            catch {
                $thrown = $_
            }

            Assert-TestStructuredCliError -ThrownError $thrown -ExpectedError $TestCase.ExpectedError
        }
    }

    It 'ConvertFrom-NovaNotificationCliArgument resolves status, enable, and disable actions' {
        InModuleScope $script:moduleName {
            (ConvertFrom-NovaNotificationCliArgument).ToString() | Should -Be 'status'
            (ConvertFrom-NovaNotificationCliArgument -Arguments @('-e')).ToString() | Should -Be 'enable'
            (ConvertFrom-NovaNotificationCliArgument -Arguments @('--disable')).ToString() | Should -Be 'disable'
        }
    }

    It 'ConvertFrom-NovaDeployCliArgument parses extended upload options and headers' {
        InModuleScope $script:moduleName {
            $options = ConvertFrom-NovaDeployCliArgument -Arguments @(
                '--path', '/tmp/package-a.nupkg',
                '--upload-path', 'modules/releases/',
                '--token', 'secret-token',
                '--token-env', 'NOVA_TOKEN',
                '--auth-scheme', 'Bearer',
                '--header', 'X-Trace-Id=trace-123'
            )

            $options.PackagePath | Should -Be @('/tmp/package-a.nupkg')
            $options.UploadPath | Should -Be 'modules/releases/'
            $options.Token | Should -Be 'secret-token'
            $options.TokenEnvironmentVariable | Should -Be 'NOVA_TOKEN'
            $options.AuthenticationScheme | Should -Be 'Bearer'
            $options.Headers['X-Trace-Id'] | Should -Be 'trace-123'
        }
    }

    It 'ConvertFrom-NovaVersionCliArgument resolves default and installed version modes' {
        InModuleScope $script:moduleName {
            (ConvertFrom-NovaVersionCliArgument).Installed | Should -BeFalse
            (ConvertFrom-NovaVersionCliArgument -Arguments @('-i')).Installed | Should -BeTrue

            $unsupportedUsageError = $null
            try {
                ConvertFrom-NovaVersionCliArgument -Arguments @('--bogus')
            }
            catch {
                $unsupportedUsageError = $_
            }

            Assert-TestStructuredCliError -ThrownError $unsupportedUsageError -ExpectedError ([pscustomobject]@{
                Message = "Unsupported 'nova version' usage*"
                ErrorId = 'Nova.Validation.UnsupportedVersionCliUsage'
                Category = [System.Management.Automation.ErrorCategory]::InvalidArgument
            })
        }
    }

    It 'Get-NovaCliCommandHelp and Add-NovaCliHeaderOption expose structured CLI validation errors' {
        InModuleScope $script:moduleName {
            $unknownCommandError = $null
            try {
                Get-NovaCliCommandHelp -Command 'banana'
            }
            catch {
                $unknownCommandError = $_
            }

            Assert-TestStructuredCliError -ThrownError $unknownCommandError -ExpectedError ([pscustomobject]@{
                Message = "Unknown command: <banana> | Use 'nova --help' to see available commands."
                ErrorId = 'Nova.Validation.UnknownCliCommand'
                Category = [System.Management.Automation.ErrorCategory]::InvalidArgument
                TargetObject = 'banana'
            })

            $options = @{}
            Add-NovaCliHeaderOption -Options $options -HeaderArgument 'X-Trace-Id=trace-123'
            $options.Headers['X-Trace-Id'] | Should -Be 'trace-123'

            $invalidHeaderError = $null
            try {
                Add-NovaCliHeaderOption -Options @{} -HeaderArgument '=value'
            }
            catch {
                $invalidHeaderError = $_
            }

            Assert-TestStructuredCliError -ThrownError $invalidHeaderError -ExpectedError ([pscustomobject]@{
                Message = 'Invalid header argument: =value. Use Name=Value.'
                ErrorId = 'Nova.Validation.InvalidCliHeaderArgument'
                Category = [System.Management.Automation.ErrorCategory]::InvalidArgument
                TargetObject = '=value'
            })
        }
    }

    It 'Invoke-NovaCliCommandRoute forwards parsed mutating options for <Command>' -ForEach @(
        @{
            Command = 'test'
            Arguments = @('--build')
            ParserCommand = 'ConvertFrom-NovaTestCliArgument'
            ActionCommand = 'Test-NovaBuild'
            ParsedOptions = @{Build = $true}
            ExpectedProperty = 'Build'
            UsesPublishOption = $false
        }
        @{
            Command = 'package'
            Arguments = @('--skip-tests')
            ParserCommand = 'ConvertFrom-NovaPackageCliArgument'
            ActionCommand = 'New-NovaModulePackage'
            ParsedOptions = @{SkipTests = $true}
            ExpectedProperty = 'SkipTests'
            UsesPublishOption = $false
        }
        @{
            Command = 'publish'
            Arguments = @('-s')
            ParserCommand = 'ConvertFrom-NovaCliArgument'
            ActionCommand = 'Publish-NovaModule'
            ParsedOptions = @{SkipTests = $true}
            ExpectedProperty = 'SkipTests'
            UsesPublishOption = $false
        }
        @{
            Command = 'release'
            Arguments = @('--skip-tests')
            ParserCommand = 'ConvertFrom-NovaCliArgument'
            ActionCommand = 'Invoke-NovaRelease'
            ParsedOptions = @{SkipTests = $true}
            ExpectedProperty = 'SkipTests'
            UsesPublishOption = $true
        }
    ) {
        InModuleScope $script:moduleName -Parameters @{TestCase = $_} {
            param($TestCase)

            $invocationContext = [pscustomobject]@{
                Command = $TestCase.Command
                Arguments = $TestCase.Arguments
                CommonParameters = @{}
                MutatingCommonParameters = @{WhatIf = $true}
                IsHelpRequest = $false
                HelpRequest = $null
                ModuleName = 'NovaModuleTools'
                WhatIfEnabled = $true
                CliConfirmEnabled = $false
            }

            $parserCommand = $TestCase.ParserCommand
            $actionCommand = $TestCase.ActionCommand
            $parsedOptions = $TestCase.ParsedOptions
            $expectedProperty = $TestCase.ExpectedProperty

            Mock $parserCommand {$parsedOptions}
            if ($TestCase.UsesPublishOption) {
                Mock $actionCommand {
                    param([hashtable]$PublishOption, [switch]$WhatIf)

                    [pscustomobject]@{Feature = [bool]$PublishOption.SkipTests; WhatIf = $WhatIf.IsPresent}
                }
            }
            elseif ($expectedProperty -eq 'Build') {
                Mock $actionCommand {
                    param([switch]$Build, [switch]$WhatIf)

                    [pscustomobject]@{Feature = $Build.IsPresent; WhatIf = $WhatIf.IsPresent}
                }
            }
            else {
                Mock $actionCommand {
                    param([switch]$SkipTests, [switch]$WhatIf)

                    [pscustomobject]@{Feature = $SkipTests.IsPresent; WhatIf = $WhatIf.IsPresent}
                }
            }

            $result = Invoke-NovaCliCommandRoute -InvocationContext $invocationContext

            $result.Feature | Should -BeTrue
            $result.WhatIf | Should -BeTrue
            Assert-MockCalled $parserCommand -Times 1 -ParameterFilter {$Arguments -eq $TestCase.Arguments}
        }
    }

    It 'Invoke-NovaCliCommandRoute forwards ContinuousIntegration to build and bump commands' {
        foreach ($testCase in (Get-TestNovaCliContinuousIntegrationRouteCaseList)) {
            InModuleScope $script:moduleName -Parameters @{TestCase = $testCase} {
                param($TestCase)

                $invocationContext = [pscustomobject]@{
                    Command = $TestCase.Command
                    Arguments = @('--continuous-integration')
                    CommonParameters = @{}
                    MutatingCommonParameters = @{WhatIf = $true}
                    IsHelpRequest = $false
                    HelpRequest = $null
                    ModuleName = 'NovaModuleTools'
                    WhatIfEnabled = $true
                    CliConfirmEnabled = $false
                }

                Mock $TestCase.ParserCommand {@{ContinuousIntegration = $true}}
                Mock $TestCase.ActionCommand {
                    param([switch]$ContinuousIntegration, [switch]$WhatIf)

                    [pscustomobject]@{Feature = $ContinuousIntegration.IsPresent; WhatIf = $WhatIf.IsPresent}
                }

                $result = Invoke-NovaCliCommandRoute -InvocationContext $invocationContext

                $result.Feature | Should -BeTrue
                $result.WhatIf | Should -BeTrue
            }
        }
    }

    It 'Get-NovaCliCommandHelp renders CLI-native command help without calling Get-Help' {
        InModuleScope $script:moduleName {
            Mock Get-Help {throw 'CLI help should not call Get-Help'}

            foreach ($commandName in @('info', 'version', 'build', 'test', 'bump', 'update', 'notification', 'publish', 'release')) {
                $result = Get-NovaCliCommandHelp -Command $commandName

                $result | Should -Match '^usage: '
                $result | Should -Match 'Options:'
            }

            Assert-MockCalled Get-Help -Times 0
        }
    }

    It 'Get-NovaCliCommandHelp includes docs URLs only in long help descriptions' {
        InModuleScope $script:moduleName -Parameters @{DocsRoot = (Join-Path $script:repoRoot 'docs')} {
            param($DocsRoot)

            $docsLinkPrefix = 'For more information, documentation, and examples, visit:'
            $docsUrlMap = @{
                'init' = 'https://www.novamoduletools.com/core-workflows.html#scaffold'
                'info' = 'https://www.novamoduletools.com/project-json-reference.html'
                'version' = 'https://www.novamoduletools.com/versioning-and-updates.html#version-views'
                'build' = 'https://www.novamoduletools.com/core-workflows.html#build'
                'test' = 'https://www.novamoduletools.com/core-workflows.html#test'
                'package' = 'https://www.novamoduletools.com/packaging-and-delivery.html#pack'
                'deploy' = 'https://www.novamoduletools.com/packaging-and-delivery.html#upload'
                'bump' = 'https://www.novamoduletools.com/versioning-and-updates.html#bump'
                'update' = 'https://www.novamoduletools.com/versioning-and-updates.html#self-update'
                'notification' = 'https://www.novamoduletools.com/versioning-and-updates.html#notification-preferences'
                'publish' = 'https://www.novamoduletools.com/packaging-and-delivery.html#publish'
                'release' = 'https://www.novamoduletools.com/packaging-and-delivery.html#release'
            }

            foreach ($commandName in $docsUrlMap.Keys) {
                $docsUrl = $docsUrlMap[$commandName]
                $shortHelp = Get-NovaCliCommandHelp -Command $commandName -View 'Short'
                $longHelp = Get-NovaCliCommandHelp -Command $commandName -View 'Long'

                $shortHelp | Should -Not -Match ([regex]::Escape($docsLinkPrefix))
                $shortHelp | Should -Not -Match ([regex]::Escape($docsUrl))
                $longHelp | Should -Match ([regex]::Escape($docsLinkPrefix))
                $longHelp | Should -Match ([regex]::Escape($docsUrl))
                Assert-TestPublicDocsUrlExists -Url $docsUrl -DocsRoot $docsRoot | Out-Null
            }
        }
    }

    It 'Get-NovaCliNormalizedRootCommand normalizes root aliases' {
        foreach ($testCase in (Get-TestNovaCliNormalizedRootCommandCaseList)) {
            InModuleScope $script:moduleName -Parameters @{TestCase = $testCase} {
                param($TestCase)

                (Get-NovaCliNormalizedRootCommand -Command $TestCase.Command) | Should -Be $TestCase.Expected
            }
        }
    }

    It 'CLI routing helpers classify routed options correctly' {
        foreach ($testCase in (Get-TestNovaCliOptionClassificationCaseList)) {
            InModuleScope $script:moduleName -Parameters @{TestCase = $testCase} {
                param($TestCase)

                (& $TestCase.HelperName -Argument $TestCase.Argument) | Should -Be $TestCase.Expected
            }
        }
    }

    It 'Assert-NovaCliArgumentSyntax returns migration guidance for unsupported routed options' {
        foreach ($testCase in (Get-TestNovaCliSyntaxGuidanceCaseList)) {
            InModuleScope $script:moduleName -Parameters @{TestCase = $testCase} {
                param($TestCase)

                $syntaxError = $null
                try {
                    Assert-NovaCliArgumentSyntax -Arguments @($TestCase.Argument)
                }
                catch {
                    $syntaxError = $_
                }

                Assert-TestStructuredCliError -ThrownError $syntaxError -ExpectedError ([pscustomobject]@{
                    Message = $TestCase.Message
                    ErrorId = 'Nova.Validation.UnsupportedCliOptionSyntax'
                    Category = [System.Management.Automation.ErrorCategory]::InvalidArgument
                    TargetObject = $TestCase.Argument
                })
            }
        }
    }

    It 'Read-NovaCliConsoleKeyChar returns the key character from the console read result' {
        InModuleScope $script:moduleName {
            Mock Invoke-NovaCliConsoleReadKey {
                [pscustomobject]@{KeyChar = [char]'y'}
            }

            $result = Read-NovaCliConsoleKeyChar

            $result | Should -Be ([char]'y')
            Assert-MockCalled Invoke-NovaCliConsoleReadKey -Times 1
        }
    }

    It 'Invoke-NovaCliConsoleReadKey invokes the shared console reader delegate' {
        InModuleScope $script:moduleName {
            Mock Get-NovaCliConsoleReadKeyReader {
                $delegate = {
                    [pscustomobject]@{KeyChar = [char]'y'}
                }

                return $delegate
            }

            $result = Invoke-NovaCliConsoleReadKey

            $result.KeyChar | Should -Be ([char]'y')
            Assert-MockCalled Get-NovaCliConsoleReadKeyReader -Times 1
        }
    }

    It 'Invoke-NovaCliConsoleReadKey executes the console read path when standard input is redirected' {
        $runnerPath = Join-Path $TestDrive 'Invoke-NovaCliConsoleReadKey.Runner.ps1'
        $stdinPath = Join-Path $TestDrive 'Invoke-NovaCliConsoleReadKey.stdin.txt'
        $stdoutPath = Join-Path $TestDrive 'Invoke-NovaCliConsoleReadKey.stdout.txt'
        $stderrPath = Join-Path $TestDrive 'Invoke-NovaCliConsoleReadKey.stderr.txt'
        Set-Content -LiteralPath $stdinPath -Value '' -Encoding utf8 -NoNewline
        Set-Content -LiteralPath $runnerPath -Encoding utf8 -Value @"
`$module = Import-Module '$script:distModuleDir' -Force -PassThru

try {
    & `$module {
        Invoke-NovaCliConsoleReadKey | Out-Null
    }

    Write-Output 'NO_THROW'
    exit 1
}
catch {
    Write-Output `$_.FullyQualifiedErrorId
    Write-Output `$_.Exception.Message
    exit 0
}
"@

        $process = Start-Process pwsh -ArgumentList @('-NoLogo', '-NoProfile', '-File', $runnerPath) `
            -RedirectStandardInput $stdinPath `
            -RedirectStandardOutput $stdoutPath `
            -RedirectStandardError $stderrPath `
            -Wait `
            -PassThru
        $output = @(
        if (Test-Path -LiteralPath $stdoutPath) {
            Get-Content -LiteralPath $stdoutPath
        }
        if (Test-Path -LiteralPath $stderrPath) {
            Get-Content -LiteralPath $stderrPath
        }
        )

        $process.ExitCode | Should -Be 0 -Because ($output -join [Environment]::NewLine)
        ($output -join [Environment]::NewLine) | Should -Match 'Cannot read keys when either application does not have a console or when console input has been redirected'
    }

    It 'Add-NovaCliCommonOption returns false for non-common routed options' {
        InModuleScope $script:moduleName {
            $forwardedParameters = @{}
            $result = Add-NovaCliCommonOption -Argument '--repository' -ForwardedParameters $forwardedParameters

            $result | Should -BeFalse
            $forwardedParameters.Count | Should -Be 0
        }
    }

    It 'Add-NovaCliCommonOption maps WhatIf long and short options into forwarded parameters' {
        InModuleScope $script:moduleName {
            foreach ($option in @('--what-if', '-w')) {
                $forwardedParameters = @{}

                $result = Add-NovaCliCommonOption -Argument $option -ForwardedParameters $forwardedParameters

                $result | Should -BeTrue
                $forwardedParameters.WhatIf | Should -BeTrue
            }
        }
    }

    It 'ConvertFrom-NovaCliArgument parses local, path, api key, skip-tests, and continuous integration options' {
        InModuleScope $script:moduleName {
            $options = ConvertFrom-NovaCliArgument -Arguments @('--local', '--path', '/tmp/modules', '--api-key', 'secret', '--skip-tests', '--continuous-integration')

            $options.Local | Should -BeTrue
            $options.ModuleDirectoryPath | Should -Be '/tmp/modules'
            $options.ApiKey | Should -Be 'secret'
            $options.SkipTests | Should -BeTrue
            $options.ContinuousIntegration | Should -BeTrue
        }
    }

    It 'ConvertFrom-NovaPackageCliArgument accepts skip-tests and rejects publish-only options' {
        InModuleScope $script:moduleName {
            (ConvertFrom-NovaPackageCliArgument -Arguments @('-s')).SkipTests | Should -BeTrue

            $thrown = $null
            try {
                ConvertFrom-NovaPackageCliArgument -Arguments @('--local')
            }
            catch {
                $thrown = $_
            }

            Assert-TestStructuredCliError -ThrownError $thrown -ExpectedError ([pscustomobject]@{
                Message = 'Unknown argument: --local'
                ErrorId = 'Nova.Validation.UnknownCliArgument'
                Category = [System.Management.Automation.ErrorCategory]::InvalidArgument
                TargetObject = '--local'
            })
        }
    }

    It 'ConvertFrom-NovaCliArgument reports missing values for repository, path, and api key' {
        InModuleScope $script:moduleName -Parameters @{
            TestCases = @(
                @{Arguments = @('--repository'); ExpectedMessage = 'Missing value for --repository'; Target = '--repository'}
                @{Arguments = @('--path'); ExpectedMessage = 'Missing value for --path'; Target = '--path'}
                @{Arguments = @('--api-key'); ExpectedMessage = 'Missing value for --api-key'; Target = '--api-key'}
            )
        } {
            param($TestCases)

            foreach ($testCase in $TestCases) {
                $thrown = $null
                try {
                    ConvertFrom-NovaCliArgument -Arguments $testCase.Arguments
                }
                catch {
                    $thrown = $_
                }

                Assert-TestStructuredCliError -ThrownError $thrown -ExpectedError ([pscustomobject]@{
                    Message = $testCase.ExpectedMessage
                    ErrorId = 'Nova.Validation.MissingCliOptionValue'
                    Category = [System.Management.Automation.ErrorCategory]::InvalidArgument
                    TargetObject = $testCase.Target
                })
            }
        }
    }

    It 'Get-NovaCliInstallDirectory uses the destination when provided and HOME otherwise' {
        InModuleScope $script:moduleName {
            $custom = Get-NovaCliInstallDirectory -DestinationDirectory "$TestDrive/custom-bin"
            $custom | Should -Be ([System.IO.Path]::GetFullPath("$TestDrive/custom-bin"))

            $originalHome = $env:HOME
            try {
                $env:HOME = $TestDrive
                Get-NovaCliInstallDirectory | Should -Be ([System.IO.Path]::Join($TestDrive, '.local', 'bin'))
                $env:HOME = ''

                $missingHomeError = $null
                try {
                    Get-NovaCliInstallDirectory
                }
                catch {
                    $missingHomeError = $_
                }

                Assert-TestStructuredCliError -ThrownError $missingHomeError -ExpectedError ([pscustomobject]@{
                    Message = 'HOME environment variable is not set*'
                    ErrorId = 'Nova.Environment.HomeDirectoryMissing'
                    Category = [System.Management.Automation.ErrorCategory]::ResourceUnavailable
                    TargetObject = 'HOME'
                })
            }
            finally {
                $env:HOME = $originalHome
            }
        }
    }

    It 'Get-NovaCliInstallDirectory reads HOME through the shared environment helper' {
        InModuleScope $script:moduleName {
            Mock Get-NovaEnvironmentVariableValue {'/tmp/nova-home'} -ParameterFilter {$Name -eq 'HOME'}

            Get-NovaCliInstallDirectory | Should -Be ([System.IO.Path]::Join('/tmp/nova-home', '.local', 'bin'))
            Assert-MockCalled Get-NovaEnvironmentVariableValue -Times 1 -ParameterFilter {$Name -eq 'HOME'}
        }
    }

    It 'Invoke-NovaCliInitCommand rejects WhatIf with a structured validation error' {
        InModuleScope $script:moduleName {
            $unsupportedWhatIfError = $null
            try {
                Invoke-NovaCliInitCommand -Arguments @('--path', '/tmp/project') -ForwardedParameters @{} -WhatIfEnabled
            }
            catch {
                $unsupportedWhatIfError = $_
            }

            Assert-TestStructuredCliError -ThrownError $unsupportedWhatIfError -ExpectedError ([pscustomobject]@{
                Message = "The 'nova init' CLI command does not support '--what-if'/'-w'.*"
                ErrorId = 'Nova.Validation.UnsupportedInitCliWhatIf'
                Category = [System.Management.Automation.ErrorCategory]::InvalidOperation
                TargetObject = 'WhatIf'
            })
        }
    }

    It 'Get-NovaCliLauncherPath reports missing commands, missing file-backed commands, and missing launcher files' {
        InModuleScope $script:moduleName {
            Mock Get-Command {$null}
            $missingCommandError = $null
            try {
                Get-NovaCliLauncherPath
            }
            catch {
                $missingCommandError = $_
            }

            Assert-TestStructuredCliError -ThrownError $missingCommandError -ExpectedError ([pscustomobject]@{
                Message = 'Install-NovaCli command not found.'
                ErrorId = 'Nova.Environment.CliInstallCommandNotFound'
                Category = [System.Management.Automation.ErrorCategory]::ObjectNotFound
                TargetObject = 'Install-NovaCli'
            })

            Mock Get-Command {
                [pscustomobject]@{
                    ScriptBlock = [pscustomobject]@{File = $null}
                }
            }
            $nonFileBackedCommandError = $null
            try {
                Get-NovaCliLauncherPath
            }
            catch {
                $nonFileBackedCommandError = $_
            }

            Assert-TestStructuredCliError -ThrownError $nonFileBackedCommandError -ExpectedError ([pscustomobject]@{
                Message = 'Install-NovaCli must be loaded from a file-backed module.'
                ErrorId = 'Nova.Environment.CliInstallCommandNotFileBacked'
                Category = [System.Management.Automation.ErrorCategory]::ResourceUnavailable
                TargetObject = 'Install-NovaCli'
            })

            Mock Get-Command {
                [pscustomobject]@{
                    ScriptBlock = [pscustomobject]@{File = '/tmp/public/InstallNovaCli.ps1'}
                }
            }
            Mock Test-Path {$false}
            $missingLauncherError = $null
            try {
                Get-NovaCliLauncherPath
            }
            catch {
                $missingLauncherError = $_
            }

            Assert-TestStructuredCliError -ThrownError $missingLauncherError -ExpectedError ([pscustomobject]@{
                Message = 'Nova CLI launcher not found*'
                ErrorId = 'Nova.Environment.CliLauncherNotFound'
                Category = [System.Management.Automation.ErrorCategory]::ObjectNotFound
                TargetObject = 'nova'
            })
        }
    }

    It 'Get-NovaCliInstalledVersion returns the currently loaded module version' {
        $module = Get-Module $script:moduleName -ErrorAction Stop
        $expectedVersion = $module.Version.ToString()
        $psData = $module.PrivateData.PSData
        $prereleaseLabel = if ($psData -is [hashtable]) {
            $psData['Prerelease']
        }
        elseif ($null -ne $psData -and $psData.PSObject.Properties.Name -contains 'Prerelease') {
            $psData.Prerelease
        }
        else {
            $null
        }

        if (-not [string]::IsNullOrWhiteSpace($prereleaseLabel)) {
            $expectedVersion = "$expectedVersion-$prereleaseLabel"
        }

        InModuleScope $script:moduleName -Parameters @{ExpectedVersion = $expectedVersion} {
            param($ExpectedVersion)

            Get-NovaCliInstalledVersion | Should -Be $ExpectedVersion
        }
    }

    It 'Get-NovaCliInstalledVersion appends prerelease metadata from the loaded module when present' {
        InModuleScope $script:moduleName {
            $moduleInfo = [pscustomobject]@{
                Version = [version]'1.11.1'
                PrivateData = [pscustomobject]@{
                    PSData = [pscustomobject]@{
                        Prerelease = 'preview'
                    }
                }
            }

            Get-NovaCliInstalledVersion -Module $moduleInfo | Should -Be '1.11.1-preview'
        }
    }

    It 'Get-NovaInstalledProjectManifestPath builds the expected local manifest path for the current project' {
        InModuleScope $script:moduleName {
            $projectInfo = [pscustomobject]@{ProjectName = 'AzureDevOpsAgentInstaller'}

            Mock Resolve-NovaLocalPublishPath {'/tmp/local-modules'}

            $result = Get-NovaInstalledProjectManifestPath -ProjectInfo $projectInfo

            $result | Should -Be '/tmp/local-modules/AzureDevOpsAgentInstaller/AzureDevOpsAgentInstaller.psd1'
        }
    }

    It 'Get-NovaInstalledProjectVersion reads the locally installed module version and updates after the local manifest changes' {
        InModuleScope $script:moduleName {
            $moduleRoot = Join-Path $TestDrive 'modules'
            $manifestDirectory = Join-Path $moduleRoot 'AzureDevOpsAgentInstaller'
            $manifestPath = Join-Path $manifestDirectory 'AzureDevOpsAgentInstaller.psd1'
            $projectInfo = [pscustomobject]@{
                ProjectName = 'AzureDevOpsAgentInstaller'
                Version = '1.12.1'
            }

            New-Item -ItemType Directory -Path $manifestDirectory -Force | Out-Null
            New-Item -ItemType File -Path (Join-Path $manifestDirectory 'AzureDevOpsAgentInstaller.psm1') -Force | Out-Null

            Mock Resolve-NovaLocalPublishPath {$moduleRoot}

            @'
@{
    RootModule = 'AzureDevOpsAgentInstaller.psm1'
    ModuleVersion = '1.12.0'
    GUID = '11111111-1111-1111-1111-111111111111'
    Author = 'Test'
}
'@ | Set-Content -LiteralPath $manifestPath -Encoding utf8

            Get-NovaInstalledProjectVersion -ProjectInfo $projectInfo | Should -Be 'AzureDevOpsAgentInstaller 1.12.0'

            @'
@{
    RootModule = 'AzureDevOpsAgentInstaller.psm1'
    ModuleVersion = '1.12.1'
    GUID = '11111111-1111-1111-1111-111111111111'
    Author = 'Test'
}
'@ | Set-Content -LiteralPath $manifestPath -Encoding utf8

            Get-NovaInstalledProjectVersion -ProjectInfo $projectInfo | Should -Be 'AzureDevOpsAgentInstaller 1.12.1'
        }
    }

    It 'Get-NovaInstalledProjectVersion resolves the default project info when none is supplied' {
        InModuleScope $script:moduleName {
            Mock Get-NovaProjectInfo {
                [pscustomobject]@{
                    ProjectName = 'AzureDevOpsAgentInstaller'
                    Version = '1.12.1'
                }
            }
            Mock Get-NovaInstalledProjectManifestPath {'/tmp/local-modules/AzureDevOpsAgentInstaller/AzureDevOpsAgentInstaller.psd1'}
            Mock Test-Path {$true}
            Mock Test-ModuleManifest {
                [pscustomobject]@{
                    Version = [version]'1.12.0'
                }
            }

            $result = Get-NovaInstalledProjectVersion

            $result | Should -Be 'AzureDevOpsAgentInstaller 1.12.0'
            Assert-MockCalled Get-NovaProjectInfo -Times 1
            Assert-MockCalled Get-NovaInstalledProjectManifestPath -Times 1 -ParameterFilter {$ProjectInfo.ProjectName -eq 'AzureDevOpsAgentInstaller'}
        }
    }

    It 'Get-NovaInstalledProjectVersion fails clearly when the current project is not installed locally' {
        InModuleScope $script:moduleName {
            $projectInfo = [pscustomobject]@{ProjectName = 'AzureDevOpsAgentInstaller'}

            Mock Resolve-NovaLocalPublishPath {'/tmp/local-modules'}

            $thrown = $null
            try {
                Get-NovaInstalledProjectVersion -ProjectInfo $projectInfo
            }
            catch {
                $thrown = $_
            }

            Assert-TestStructuredCliError -ThrownError $thrown -ExpectedError ([pscustomobject]@{
                Message = 'Local module install not found for AzureDevOpsAgentInstaller*Run ''nova publish --local'' or ''nova publish -l'' first*'
                ErrorId = 'Nova.Environment.LocalModuleInstallNotFound'
                Category = [System.Management.Automation.ErrorCategory]::ObjectNotFound
                TargetObject = '/tmp/local-modules/AzureDevOpsAgentInstaller/AzureDevOpsAgentInstaller.psd1'
            })
        }
    }

    It 'Test-NovaCliDirectoryOnPath returns true when the directory is present' {
        InModuleScope $script:moduleName {
            $originalPath = $env:PATH
            $separator = [string][System.IO.Path]::PathSeparator
            $targetDirectory = [System.IO.Path]::GetFullPath($TestDrive)

            try {
                $env:PATH = "/tmp/other${separator}$targetDirectory${separator}/tmp/else"
                Test-NovaCliDirectoryOnPath -Directory $TestDrive | Should -BeTrue
            }
            finally {
                $env:PATH = $originalPath
            }
        }
    }

    It 'Test-NovaCliDirectoryOnPath reads PATH through the shared environment helper' {
        InModuleScope $script:moduleName {
            $separator = [string][System.IO.Path]::PathSeparator
            $targetDirectory = [System.IO.Path]::GetFullPath($TestDrive)
            Mock Get-NovaEnvironmentVariableValue {"/tmp/other${separator}$targetDirectory"} -ParameterFilter {$Name -eq 'PATH'}

            Test-NovaCliDirectoryOnPath -Directory $TestDrive | Should -BeTrue
            Assert-MockCalled Get-NovaEnvironmentVariableValue -Times 1 -ParameterFilter {$Name -eq 'PATH'}
        }
    }

    It 'Set-NovaCliExecutablePermission throws when chmod fails' {
        InModuleScope $script:moduleName {
            if ($IsWindows) {
                Set-NovaCliExecutablePermission -Path 'C:\temp\nova' -Confirm:$false
                return
            }

            $path = Join-Path $TestDrive 'missing-nova'
            $thrown = $null
            try {
                Set-NovaCliExecutablePermission -Path $path -Confirm:$false
            }
            catch {
                $thrown = $_
            }

            Assert-TestStructuredCliError -ThrownError $thrown -ExpectedError ([pscustomobject]@{
                Message = 'Failed to make nova launcher executable*'
                ErrorId = 'Nova.Dependency.CliLauncherPermissionUpdateFailed'
                Category = [System.Management.Automation.ErrorCategory]::InvalidOperation
                TargetObject = $path
            })
        }
    }

    It 'Write-Message forwards text and color to Write-Host' {
        InModuleScope $script:moduleName {
            Mock Write-Host {}

            'hello' | Write-Message -color Green

            Assert-MockCalled Write-Host -Times 1 -ParameterFilter {$Object -eq 'hello' -and $ForegroundColor -eq 'Green'}
        }
    }
}
