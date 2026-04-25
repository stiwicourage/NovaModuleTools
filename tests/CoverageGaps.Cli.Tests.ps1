$script:gitTestSupportPath = (Resolve-Path -LiteralPath (Join-Path $PSScriptRoot 'GitTestSupport.ps1')).Path
$script:coverageGapsCliTestSupportPath = (Resolve-Path -LiteralPath (Join-Path $PSScriptRoot 'CoverageGaps.Cli.TestSupport.ps1')).Path
$global:gitTestSupportFunctionNameList = @(
    'Initialize-TestGitRepository'
    'New-TestGitCommit'
    'New-TestGitTag'
)
$global:coverageGapsCliTestSupportFunctionNameList = @(
    'Assert-TestStructuredCliError'
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
            Mock Test-NovaCliHelpRequest {$true}
            Mock Assert-NovaCliAliasCommonParameterSyntax {}
            Mock Assert-NovaCliArgumentSyntax {}
            Mock Get-NovaCliArgumentRoutingState {
                [pscustomobject]@{
                    Command = 'publish'
                    Arguments = @('--help')
                    ForwardedParameters = @{}
                    WhatIfEnabled = $false
                }
            }
            Mock Merge-NovaCliParameterSet {$BaseParameters}
            Mock Get-NovaCliAliasRootCommandOverride {$null}

            $result = Get-NovaCliInvocationContext -InvocationRequest ([pscustomobject]@{
                Command = 'publish'
                BoundParameters = @{Verbose = $true; Arguments = @('--help')}
                Arguments = @('--help')
                InvocationName = 'Invoke-NovaCli'
                InvocationStatement = 'Invoke-NovaCli publish --help'
            }) -WhatIfEnabled

            $result.Command | Should -Be 'publish'
            $result.Arguments | Should -Be @('--help')
            $result.CommonParameters.Verbose | Should -BeTrue
            $result.MutatingCommonParameters.WhatIf | Should -BeTrue
            $result.IsHelpRequest | Should -BeTrue
            $result.ModuleName | Should -Be 'NovaModuleTools'
            $result.WhatIfEnabled | Should -BeTrue
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
                Arguments = @('--help')
                CommonParameters = @{}
                MutatingCommonParameters = @{}
                IsHelpRequest = $true
                ModuleName = 'NovaModuleTools'
                WhatIfEnabled = $false
            }
            Mock Get-NovaCliCommandHelp {'package-help'}

            $result = Invoke-NovaCliCommandRoute -InvocationContext $invocationContext

            $result | Should -Be 'package-help'
            Assert-MockCalled Get-NovaCliCommandHelp -Times 1 -ParameterFilter {$Command -eq 'package'}
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
                        $WhatIfEnabled -and
                        $InvocationRequest.InvocationName -eq 'Invoke-NovaCli'
            }
            Assert-MockCalled Invoke-NovaCliCommandRoute -Times 1 -ParameterFilter {
                $InvocationContext.Command -eq 'build' -and $InvocationContext.WhatIfEnabled
            }
        }
    }

    It 'Get-NovaCliInvocationContext normalizes root alias -v and routed alias -v correctly' {
        InModuleScope $script:moduleName {
            $rootContext = Get-NovaCliInvocationContext -InvocationRequest ([pscustomobject]@{
                Command = '--help'
                BoundParameters = @{Verbose = $true}
                Arguments = @()
                InvocationName = 'nova'
                InvocationStatement = 'nova -v'
            })
            $buildContext = Get-NovaCliInvocationContext -InvocationRequest ([pscustomobject]@{
                Command = 'build'
                BoundParameters = @{Command = 'build'; Verbose = $true; Arguments = @('-w', '-c')}
                Arguments = @('-w', '-c')
                InvocationName = 'nova'
                InvocationStatement = 'nova build -v -w -c'
            })

            $rootContext.Command | Should -Be '--version'
            $rootContext.Arguments | Should -Be @()
            $buildContext.Command | Should -Be 'build'
            $buildContext.Arguments | Should -Be @()
            $buildContext.CommonParameters.Verbose | Should -BeTrue
            $buildContext.MutatingCommonParameters.Verbose | Should -BeTrue
            $buildContext.MutatingCommonParameters.WhatIf | Should -BeTrue
            $buildContext.MutatingCommonParameters.Confirm | Should -BeTrue
            $buildContext.WhatIfEnabled | Should -BeTrue
        }
    }

    It 'Get-NovaCliInvocationContext rejects alias-bound legacy PowerShell-style common parameters' {
        InModuleScope $script:moduleName {
            $thrown = $null
            try {
                Get-NovaCliInvocationContext -InvocationRequest ([pscustomobject]@{
                    Command = 'build'
                    BoundParameters = @{Command = 'build'; Verbose = $true}
                    Arguments = @()
                    InvocationName = 'nova'
                    InvocationStatement = 'nova build -Verbose'
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

    It 'ConvertFrom-NovaBumpCliArgument parses the preview switch and rejects unsupported bump arguments' {
        InModuleScope $script:moduleName {
            (ConvertFrom-NovaBumpCliArgument -Arguments @('--preview')).Preview | Should -BeTrue
            (ConvertFrom-NovaBumpCliArgument -Arguments @('-p')).Preview | Should -BeTrue

            $unknownArgumentError = $null
            try {
                ConvertFrom-NovaBumpCliArgument -Arguments @('--bogus')
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

    It 'Get-NovaCliCommandHelp maps the remaining routed commands to the expected help targets' {
        InModuleScope $script:moduleName {
            Mock Get-Help {"help:$Name"}

            $expectedTargets = @{
                info = 'Get-NovaProjectInfo'
                version = 'Invoke-NovaCli'
                build = 'Invoke-NovaBuild'
                test = 'Test-NovaBuild'
                bump = 'Update-NovaModuleVersion'
                update = 'Update-NovaModuleTool'
                notification = 'Set-NovaUpdateNotificationPreference'
                publish = 'Publish-NovaModule'
                release = 'Invoke-NovaRelease'
            }

            foreach ($commandName in $expectedTargets.Keys) {
                $result = Get-NovaCliCommandHelp -Command $commandName

                $result | Should -Be "help:$( $expectedTargets[$commandName] )"
            }
        }
    }

    It 'CLI routing helpers cover normalized root help, alias invocation fallback, token parsing, and generic syntax guidance' {
        InModuleScope $script:moduleName {
            (Get-NovaCliNormalizedRootCommand -Command '-h') | Should -Be '--help'

            $nonAliasInvocation = [pscustomobject]@{
                InvocationName = 'Invoke-NovaCli'
                InvocationStatement = $null
                Command = 'build'
                Arguments = @('--verbose')
                BoundParameters = @{}
            }
            $aliasInvocation = [pscustomobject]@{
                InvocationName = 'nova'
                InvocationStatement = $null
                Command = 'build'
                Arguments = @('--verbose')
                BoundParameters = @{}
            }

            (Get-NovaCliAliasInvocationStatement -Invocation $nonAliasInvocation) | Should -BeNullOrEmpty
            (Get-NovaCliAliasInvocationStatement -Invocation $aliasInvocation) | Should -Be 'nova build --verbose'
            (Get-NovaCliInvocationParameterTokenSet -InvocationStatement '') | Should -Be @()
            (Get-NovaCliBoundCommonParameterToken -ParameterName 'Confirm' -ParameterTokens @('-Verbose', '-WhatIf')) | Should -BeNullOrEmpty

            $genericSyntaxError = $null
            try {
                Assert-NovaCliArgumentSyntax -Arguments @('-legacy')
            }
            catch {
                $genericSyntaxError = $_
            }

            Assert-TestStructuredCliError -ThrownError $genericSyntaxError -ExpectedError ([pscustomobject]@{
                Message = "Unsupported CLI option syntax: -legacy. Use long options with '--' or single-character short options."
                ErrorId = 'Nova.Validation.UnsupportedCliOptionSyntax'
                Category = [System.Management.Automation.ErrorCategory]::InvalidArgument
                TargetObject = '-legacy'
            })
        }
    }

    It 'Get-NovaCliAliasRootCommandOverride returns nothing when root alias verbose binding did not come from -v' {
        InModuleScope $script:moduleName {
            $result = Get-NovaCliAliasRootCommandOverride -Invocation ([pscustomobject]@{
                InvocationName = 'nova'
                Command = '--help'
                BoundParameters = @{Verbose = $true}
                Arguments = @()
                InvocationStatement = 'nova -Verbose'
            })

            $result | Should -BeNullOrEmpty
        }
    }

    It 'ConvertFrom-NovaCliArgument parses local, path, and api key options' {
        InModuleScope $script:moduleName {
            $options = ConvertFrom-NovaCliArgument -Arguments @('--local', '--path', '/tmp/modules', '--api-key', 'secret')

            $options.Local | Should -BeTrue
            $options.ModuleDirectoryPath | Should -Be '/tmp/modules'
            $options.ApiKey | Should -Be 'secret'
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
                Message = "The 'nova init' CLI command does not support '--whatif'/'-w'.*"
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
